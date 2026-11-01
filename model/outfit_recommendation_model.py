"""
Outfit Recommendation Model — StyloBuddy
=========================================
Type-Aware Compatibility Network (TACN)

Architecture:
    1. Visual Encoder   — pretrained ResNet-18 backbone, outputs 512-dim embedding
    2. Type Projection  — maps each item into a category-specific subspace
    3. Compatibility Scorer — pairwise dot-product scoring across subspaces
    4. Outfit Ranker    — aggregates pairwise scores into a full outfit score

Training:
    Triplet loss: anchor outfit (compatible) pulled closer than negative outfit (random swap)

Inference:
    Given N candidate items, enumerate combinations and return top-K ranked outfits
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models, transforms
from torch.utils.data import Dataset, DataLoader
from itertools import product
from PIL import Image
import requests
from io import BytesIO
import numpy as np


# Constants and hyperparameters

CATEGORIES = ["topwear", "bottomwear", "footwear", "accessory", "outerwear"]

# Each category pair gets its own compatibility subspace dimension
EMBEDDING_DIM   = 512       # ResNet-18 output
SUBSPACE_DIM    = 64        # per-type projected dimension
TEMPERATURE     = 0.07      # softmax temperature for contrastive loss
MARGIN          = 0.3       # triplet loss margin


# Image preprocessing pipeline (resize, normalize, etc.)

image_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],   # ImageNet stats
        std =[0.229, 0.224, 0.225]
    )
])


def load_image_from_url(url: str) -> torch.Tensor:
    """Download an image from URL and return a preprocessed tensor (1, 3, 224, 224)."""
    response = requests.get(url, timeout=10)
    img = Image.open(BytesIO(response.content)).convert("RGB")
    return image_transform(img).unsqueeze(0)


def load_image_from_path(path: str) -> torch.Tensor:
    """Load a local image file and return a preprocessed tensor (1, 3, 224, 224)."""
    img = Image.open(path).convert("RGB")
    return image_transform(img).unsqueeze(0)


# Visual Encoder: Pretrained ResNet-18 with projection head for fashion embeddings

class VisualEncoder(nn.Module):
    """
    Pretrained ResNet-18 with the classification head replaced by a
    512-dim L2-normalised embedding layer.
    """

    def __init__(self, frozen_backbone: bool = True):
        super().__init__()
        backbone = models.resnet18(weights=models.ResNet18_Weights.IMAGENET1K_V1)

        # Split backbone: early layers (freeze) + late layers (fine-tune)
        children = list(backbone.children())[:-1]  # remove FC
        self.features = nn.Sequential(*children)

        if frozen_backbone:
            # Freeze all layers first
            for param in self.features.parameters():
                param.requires_grad = False
            # Unfreeze last 2 blocks (layer3 + layer4) for fine-tuning
            # This lets the model learn fashion-specific visual features
            for name, param in self.features.named_parameters():
                if "6." in name or "7." in name:  # layer3=idx6, layer4=idx7
                    param.requires_grad = True

        self.projection = nn.Sequential(
            nn.Flatten(),
            nn.Linear(512, 256),
            nn.LayerNorm(256),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(256, EMBEDDING_DIM)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: image tensor of shape (B, 3, 224, 224)
        Returns:
            L2-normalised embedding of shape (B, EMBEDDING_DIM)
        """
        feat = self.features(x)           # (B, 512, 1, 1)
        emb  = self.projection(feat)      # (B, EMBEDDING_DIM)
        return F.normalize(emb, p=2, dim=1)


# Type Projection: It gives 64-dim subspace projections for each category

class TypeProjection(nn.Module):

    def __init__(self):
        super().__init__()
        # One projection matrix per category
        self.projections = nn.ModuleDict({
            cat: nn.Linear(EMBEDDING_DIM, SUBSPACE_DIM, bias=False)
            for cat in CATEGORIES
        })

    def forward(self, embedding: torch.Tensor, category: str) -> torch.Tensor:
        
        projected = self.projections[category](embedding)
        return F.normalize(projected, p=2, dim=1)


# Cosine Similarity Scorer

class CompatibilityScorer(nn.Module):

    def forward(
        self,
        proj_a: torch.Tensor,
        proj_b: torch.Tensor
    ) -> torch.Tensor:

        return (proj_a * proj_b).sum(dim=1)   # cosine similarity


# Type-Aware Compatibility Network (TACN) 

class TACN(nn.Module):
    """
    Type-Aware Compatibility Network.

    Given a list of (image_tensor, category) pairs that form an outfit,
    the model:
        1. Encodes each image into a visual embedding.
        2. Projects each embedding into its category-specific subspace.
        3. Computes all pairwise compatibility scores.
        4. Aggregates pairwise scores into a single outfit compatibility score.

    A higher score means the items form a more compatible outfit.
    """

    def __init__(self, frozen_backbone: bool = True):
        super().__init__()
        self.encoder  = VisualEncoder(frozen_backbone=frozen_backbone)
        self.projector = TypeProjection()
        self.scorer    = CompatibilityScorer()

    def encode_item(
        self,
        image: torch.Tensor,
        category: str
    ) -> torch.Tensor:
        """Encode a single item to its type-projected subspace vector."""
        emb       = self.encoder(image)            
        projected = self.projector(emb, category)   
        return projected

    def score_outfit(
        self,
        items: list[tuple[torch.Tensor, str]]
    ) -> torch.Tensor:
        """
        Args:
            items : list of (image_tensor, category_string) for each garment in outfit
                    image_tensor shape: (1, 3, 224, 224)
        Returns:
            outfit_score : scalar tensor — mean pairwise compatibility across all pairs
        """
        # Encode all items
        projections = [
            self.encode_item(img, cat)
            for img, cat in items
        ]

        # Compute all unique pairwise scores
        scores = []
        n = len(projections)
        for i in range(n):
            for j in range(i + 1, n):
                s = self.scorer(projections[i], projections[j])
                scores.append(s)

        if not scores:
            return torch.tensor(0.0)

        return torch.stack(scores).mean()

    def forward(
        self,
        anchor_items:   list[tuple[torch.Tensor, str]],
        positive_items: list[tuple[torch.Tensor, str]],
        negative_items: list[tuple[torch.Tensor, str]]
    ) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
        """
        Triplet forward pass for training.

        anchor   — a complete outfit (compatible)
        positive — same outfit, minor variation (still compatible)
        negative — outfit with one item randomly swapped (incompatible)

        Returns:
            score_anchor, score_positive, score_negative
        """
        s_anchor   = self.score_outfit(anchor_items)
        s_positive = self.score_outfit(positive_items)
        s_negative = self.score_outfit(negative_items)
        return s_anchor, s_positive, s_negative


# ─────────────────────────────────────────────────────────────────────────────
# 7.  TRIPLET LOSS
# ─────────────────────────────────────────────────────────────────────────────

class TripletCompatibilityLoss(nn.Module):
    """
    Encourages:
        score(anchor, positive) > score(anchor, negative) + margin

    Loss = max(0, margin - score_positive + score_negative)
    """

    def __init__(self, margin: float = MARGIN):
        super().__init__()
        self.margin = margin

    def forward(
        self,
        score_anchor:   torch.Tensor,
        score_positive: torch.Tensor,
        score_negative: torch.Tensor
    ) -> torch.Tensor:
        loss = F.relu(self.margin - score_positive + score_negative)
        return loss.mean()


# ─────────────────────────────────────────────────────────────────────────────
# 8.  DATASET  (illustrative — plug in your own data source)
# ─────────────────────────────────────────────────────────────────────────────

class OutfitDataset(Dataset):
    """
    Expects a list of outfit records, each of the form:
        {
            "anchor":   [(image_path, category), ...],
            "positive": [(image_path, category), ...],
            "negative": [(image_path, category), ...]
        }

    For Polyvore-style datasets, build this from the JSON splits.
    """

    def __init__(self, records: list[dict]):
        self.records = records

    def _load_outfit(self, items: list[tuple[str, str]]):
        return [
            (image_transform(Image.open(p).convert("RGB")).unsqueeze(0), cat)
            for p, cat in items
        ]

    def __len__(self):
        return len(self.records)

    def __getitem__(self, idx):
        rec = self.records[idx]
        return (
            self._load_outfit(rec["anchor"]),
            self._load_outfit(rec["positive"]),
            self._load_outfit(rec["negative"]),
        )


# ─────────────────────────────────────────────────────────────────────────────
# 9.  TRAINING LOOP
# ─────────────────────────────────────────────────────────────────────────────

def train(
    model:      TACN,
    dataset:    OutfitDataset,
    epochs:     int   = 20,
    lr:         float = 1e-4,
    batch_size: int   = 1,       # outfit-level batches
    device:     str   = "cpu"
):
    """
    Training loop for TACN using triplet compatibility loss.

    Args:
        model      : TACN instance
        dataset    : OutfitDataset with anchor/positive/negative triplets
        epochs     : number of training epochs
        lr         : learning rate for Adam optimiser
        batch_size : number of outfit triplets per gradient step
        device     : "cpu" or "cuda"
    """
    model.to(device)
    model.train()

    # Only optimise the projection heads (backbone is frozen by default)
    optimizer = torch.optim.Adam(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=lr
    )
    loss_fn = TripletCompatibilityLoss(margin=MARGIN)
    loader  = DataLoader(dataset, batch_size=batch_size, shuffle=True)

    for epoch in range(1, epochs + 1):
        epoch_loss = 0.0

        for anchor, positive, negative in loader:
            optimizer.zero_grad()

            s_a, s_p, s_n = model(anchor, positive, negative)
            loss = loss_fn(s_a, s_p, s_n)

            loss.backward()
            optimizer.step()

            epoch_loss += loss.item()

        avg = epoch_loss / max(len(loader), 1)
        print(f"Epoch {epoch:>3}/{epochs}  |  loss = {avg:.4f}")

    return model


# ─────────────────────────────────────────────────────────────────────────────
# 10.  INFERENCE: OUTFIT RECOMMENDATION
# ─────────────────────────────────────────────────────────────────────────────

def recommend_outfits(
    model:         TACN,
    candidate_items: list[dict],
    required_categories: list[str] = None,
    top_k:         int  = 3,
    device:        str  = "cpu"
) -> list[dict]:
    """
    Given a pool of candidate clothing items, generate and rank outfit combinations.

    Args:
        model            : trained TACN
        candidate_items  : list of dicts with keys:
                               "id"       — item identifier
                               "name"     — display name
                               "image"    — local path or URL string
                               "category" — one of CATEGORIES
        required_categories : if set, only build outfits that include at least
                               one item from each required category
                               e.g. ["topwear", "bottomwear"]
        top_k            : number of top outfits to return
        device           : "cpu" or "cuda"

    Returns:
        List of top_k dicts, each with:
            "items"             — list of item dicts in the outfit
            "compatibility_score" — float in [-1, 1], higher is better
            "rank"              — 1-indexed rank
    """
    model.to(device)
    model.eval()

    if required_categories is None:
        required_categories = ["topwear", "bottomwear"]

    # ── Group items by category ──────────────────────────────────
    by_category: dict[str, list[dict]] = {cat: [] for cat in CATEGORIES}
    for item in candidate_items:
        cat = item["category"]
        if cat in by_category:
            by_category[cat].append(item)

    # ── Check we have at least one item per required category ────
    for cat in required_categories:
        if not by_category[cat]:
            raise ValueError(f"No items found for required category: {cat}")

    # ── Build candidate outfit combinations ──────────────────────
    # One item per required category; accessories are optional
    category_pools = [by_category[cat] for cat in required_categories]
    combinations   = list(product(*category_pools))

    # ── Load images and score each combination ───────────────────
    scored = []

    with torch.no_grad():
        for combo in combinations:
            outfit_items = []
            for item in combo:
                src = item["image"]
                try:
                    if src.startswith("http"):
                        tensor = load_image_from_url(src).to(device)
                    else:
                        tensor = load_image_from_path(src).to(device)
                    outfit_items.append((tensor, item["category"]))
                except Exception:
                    outfit_items = None
                    break

            if outfit_items is None:
                continue

            score = model.score_outfit(outfit_items).item()
            scored.append({
                "items": list(combo),
                "compatibility_score": round(score, 4)
            })

    # ── Sort and return top-K ────────────────────────────────────
    scored.sort(key=lambda x: x["compatibility_score"], reverse=True)
    top = scored[:top_k]

    for rank, outfit in enumerate(top, start=1):
        outfit["rank"] = rank

    return top


# ─────────────────────────────────────────────────────────────────────────────
# 11.  SAVE / LOAD MODEL
# ─────────────────────────────────────────────────────────────────────────────

def save_model(model: TACN, path: str = "tacn_weights.pth"):
    torch.save(model.state_dict(), path)
    print(f"Model saved → {path}")


def load_model(path: str = "tacn_weights.pth", frozen_backbone: bool = True) -> TACN:
    model = TACN(frozen_backbone=frozen_backbone)
    model.load_state_dict(torch.load(path, map_location="cpu"))
    model.eval()
    print(f"Model loaded ← {path}")
    return model


# ─────────────────────────────────────────────────────────────────────────────
# 12.  QUICK DEMO  (runs without real data)
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":

    print("=== TACN — Type-Aware Compatibility Network ===\n")

    # Instantiate model
    model = TACN(frozen_backbone=True)
    total_params     = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"Total parameters     : {total_params:,}")
    print(f"Trainable parameters : {trainable_params:,}")
    print(f"Frozen (backbone)    : {total_params - trainable_params:,}\n")

    # Simulate two outfit items with random tensors (no real images needed)
    dummy_top    = (torch.randn(1, 3, 224, 224), "topwear")
    dummy_bottom = (torch.randn(1, 3, 224, 224), "bottomwear")
    dummy_shoes  = (torch.randn(1, 3, 224, 224), "footwear")

    outfit = [dummy_top, dummy_bottom, dummy_shoes]

    with torch.no_grad():
        score = model.score_outfit(outfit)

    print(f"Demo outfit compatibility score : {score.item():.4f}")
    print("(random tensors used — train the model on real outfit data for meaningful scores)\n")

    # Simulate triplet loss forward pass
    loss_fn = TripletCompatibilityLoss()
    s_a = torch.tensor(0.72)
    s_p = torch.tensor(0.68)
    s_n = torch.tensor(0.31)
    loss = loss_fn(s_a, s_p, s_n)
    print(f"Example triplet loss : {loss.item():.4f}  (margin={MARGIN})")
    print("\nDone. Plug in real outfit image data to train and use recommend_outfits().")
