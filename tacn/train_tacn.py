"""
Cmd to run training:
    python train_tacn.py --data_dir ./data --epochs 20 --lr 1e-4
"""

import argparse
import csv
import json
import os
import random
from pathlib import Path

import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image

from outfit_recommendation_model import (
    TACN,
    TripletCompatibilityLoss,
    image_transform,
    save_model,
    MARGIN,
)


# ─────────────────────────────────────────────────────────────────────────────
# COLOR COMPATIBILITY RULES (used for synthetic outfit generation)
# ─────────────────────────────────────────────────────────────────────────────

# Neutral colors pair well with everything
NEUTRALS = {"Black", "White", "Grey", "Navy Blue", "Beige", "Cream", "Charcoal", "Off White"}

# Colors that pair well together (bidirectional)
COLOR_COMPAT = {
    "Blue": {"White", "Black", "Grey", "Beige", "Brown", "Navy Blue", "Cream", "Khaki"},
    "Red": {"Black", "White", "Grey", "Navy Blue", "Beige", "Blue"},
    "Green": {"Black", "White", "Beige", "Brown", "Khaki", "Grey", "Navy Blue"},
    "Brown": {"White", "Beige", "Blue", "Green", "Cream", "Khaki", "Black"},
    "Pink": {"Black", "White", "Grey", "Navy Blue", "Blue", "Beige"},
    "Maroon": {"Black", "White", "Grey", "Beige", "Cream", "Khaki"},
    "Olive": {"White", "Black", "Beige", "Brown", "Cream", "Khaki", "Navy Blue"},
    "Khaki": {"Black", "White", "Navy Blue", "Brown", "Olive", "Maroon", "Blue"},
    "Yellow": {"Black", "White", "Grey", "Navy Blue", "Blue"},
    "Orange": {"Black", "White", "Grey", "Navy Blue", "Blue"},
    "Purple": {"Black", "White", "Grey", "Beige"},
    "Teal": {"White", "Black", "Grey", "Beige", "Cream"},
}

# Usage/occasion compatibility
USAGE_COMPAT = {
    "Casual": {"Casual", "Sports"},
    "Formal": {"Formal"},
    "Sports": {"Sports", "Casual"},
    "Ethnic": {"Ethnic", "Party"},
    "Party": {"Party", "Ethnic"},
    "Smart Casual": {"Smart Casual", "Casual", "Party"},
}

# subCategory → TACN category mapping
SUBCAT_TO_TACN = {
    "Topwear": "topwear",
    "Bottomwear": "bottomwear",
    "Shoes": "footwear",
    "Sandal": "footwear",
    "Flip Flops": "footwear",
    "Bags": "accessory",
    "Wallets": "accessory",
    "Belts": "accessory",
    "Watches": "accessory",
    "Jewellery": "accessory",
    "Eyewear": "accessory",
    "Dress": "topwear",
    "Innerwear": "topwear",
    "Loungewear and Nightwear": "topwear",
    "Saree": "topwear",
}


def colors_compatible(c1: str, c2: str) -> bool:
    """Check if two colors are compatible based on fashion rules."""
    if c1 in NEUTRALS or c2 in NEUTRALS:
        return True
    if c1 == c2:
        return True  # monochrome is always valid
    compat_set = COLOR_COMPAT.get(c1, set())
    if c2 in compat_set:
        return True
    compat_set_reverse = COLOR_COMPAT.get(c2, set())
    if c1 in compat_set_reverse:
        return True
    return False


def usage_compatible(u1: str, u2: str) -> bool:
    """Check if two usage types are compatible."""
    compat = USAGE_COMPAT.get(u1, {u1})
    return u2 in compat


# ─────────────────────────────────────────────────────────────────────────────
# 1. FASHION PRODUCT IMAGES DATASET (Kaggle — styles.csv + images/)
# ─────────────────────────────────────────────────────────────────────────────

class FashionProductDataset(Dataset):
    """
    Generates synthetic outfit triplets from the Fashion Product Images dataset.

    How it works:
        - Reads styles.csv to get item metadata (category, color, usage)
        - Groups items into topwear and bottomwear pools
        - Creates COMPATIBLE pairs using color + usage rules → anchor/positive
        - Creates INCOMPATIBLE pairs by random swap → negative
        - Each triplet trains the model to distinguish good from bad outfits

    Expected structure:
        data_dir/
        ├── styles.csv
        └── images/
            ├── 15970.jpg
            ├── 39386.jpg
            └── ...
    """

    def __init__(self, data_dir: str, num_outfits: int = 10000):
        self.data_dir = Path(data_dir)
        self.images_dir = self.data_dir / "images"
        self.num_outfits = num_outfits

        # Load and parse styles.csv
        self.topwear = []    # items with subCategory == Topwear
        self.bottomwear = [] # items with subCategory == Bottomwear
        self.footwear = []   # items with subCategory in (Shoes, Sandal, ...)
        self.all_items = {"topwear": [], "bottomwear": [], "footwear": []}

        csv_path = self.data_dir / "styles.csv"
        with open(csv_path, "r", encoding="utf-8", errors="ignore") as f:
            reader = csv.DictReader(f)
            for row in reader:
                item_id = row.get("id", "").strip()
                sub_cat = row.get("subCategory", "").strip()
                tacn_cat = SUBCAT_TO_TACN.get(sub_cat)

                if tacn_cat not in ("topwear", "bottomwear", "footwear"):
                    continue

                img_path = self.images_dir / f"{item_id}.jpg"
                if not img_path.exists():
                    continue

                item = {
                    "id": item_id,
                    "image_path": str(img_path),
                    "category": tacn_cat,
                    "color": row.get("baseColour", "").strip(),
                    "usage": row.get("usage", "Casual").strip(),
                    "gender": row.get("gender", "").strip(),
                    "name": row.get("productDisplayName", "").strip(),
                }
                self.all_items[tacn_cat].append(item)

        print(f"Loaded items — topwear: {len(self.all_items['topwear'])}, "
              f"bottomwear: {len(self.all_items['bottomwear'])}, "
              f"footwear: {len(self.all_items['footwear'])}")

        # Pre-generate compatible outfit pairs
        self.outfits = self._generate_outfits()
        print(f"Generated {len(self.outfits)} compatible outfit pairs")

    def _generate_outfits(self) -> list[dict]:
        """Generate synthetic compatible outfits using color + usage rules."""
        outfits = []
        tops = self.all_items["topwear"]
        bottoms = self.all_items["bottomwear"]

        if not tops or not bottoms:
            print("WARNING: Need both topwear and bottomwear items to generate outfits")
            return []

        attempts = 0
        max_attempts = self.num_outfits * 5

        while len(outfits) < self.num_outfits and attempts < max_attempts:
            attempts += 1
            top = random.choice(tops)
            bottom = random.choice(bottoms)

            # Check compatibility: same gender (or unisex), compatible colors + usage
            gender_ok = (
                top["gender"] == bottom["gender"]
                or "Unisex" in (top["gender"], bottom["gender"])
            )
            color_ok = colors_compatible(top["color"], bottom["color"])
            usage_ok = usage_compatible(top["usage"], bottom["usage"])

            if gender_ok and color_ok and usage_ok:
                outfit = {"top": top, "bottom": bottom}

                # Optionally add footwear
                if self.all_items["footwear"] and random.random() < 0.3:
                    shoe = random.choice(self.all_items["footwear"])
                    if (colors_compatible(shoe["color"], top["color"])
                            and usage_compatible(shoe["usage"], top["usage"])):
                        outfit["footwear"] = shoe

                outfits.append(outfit)

        return outfits

    def __len__(self):
        return len(self.outfits)

    def __getitem__(self, idx):
        """
        Returns triplet: (anchor, positive, negative)
            anchor   = compatible outfit (top + bottom, optionally shoes)
            positive = same outfit
            negative = outfit with one item randomly swapped (incompatible)
        """
        outfit = self.outfits[idx]

        # Build anchor items
        anchor_items = []
        item_list = []

        for key in ("top", "bottom", "footwear"):
            if key not in outfit:
                continue
            item = outfit[key]
            try:
                img = image_transform(Image.open(item["image_path"]).convert("RGB"))
                anchor_items.append((img, item["category"]))
                item_list.append(item)
            except Exception:
                continue

        if len(anchor_items) < 2:
            # Fallback: return dummy data
            dummy = torch.randn(3, 224, 224)
            return [(dummy, "topwear"), (dummy, "bottomwear")], \
                   [(dummy, "topwear"), (dummy, "bottomwear")], \
                   [(dummy, "topwear"), (dummy, "bottomwear")]

        # Positive = same outfit
        positive_items = anchor_items.copy()

        # Negative = swap one item with an INCOMPATIBLE item (hard negative)
        negative_items = anchor_items.copy()
        swap_idx = random.randint(0, len(negative_items) - 1)
        swap_cat = negative_items[swap_idx][1]
        swap_item = item_list[swap_idx]

        # Hard negative: pick item with DIFFERENT usage OR clashing color
        pool = self.all_items[swap_cat]
        random.shuffle(pool)
        for replacement in pool:
            if replacement["id"] == swap_item["id"]:
                continue
            # Prefer items that are clearly incompatible
            color_clash = not colors_compatible(
                replacement["color"],
                item_list[1 - swap_idx]["color"] if len(item_list) > 1 else ""
            )
            usage_clash = not usage_compatible(
                replacement["usage"],
                item_list[1 - swap_idx]["usage"] if len(item_list) > 1 else ""
            )
            if color_clash or usage_clash:
                try:
                    neg_img = image_transform(
                        Image.open(replacement["image_path"]).convert("RGB")
                    )
                    negative_items[swap_idx] = (neg_img, swap_cat)
                    break
                except Exception:
                    continue
        else:
            # Fallback: any different item
            for replacement in pool:
                if replacement["id"] != swap_item["id"]:
                    try:
                        neg_img = image_transform(
                            Image.open(replacement["image_path"]).convert("RGB")
                        )
                        negative_items[swap_idx] = (neg_img, swap_cat)
                        break
                    except Exception:
                        continue

        return anchor_items, positive_items, negative_items


# ─────────────────────────────────────────────────────────────────────────────
# 2. CUSTOM CATALOG DATASET (from your own items / GPT history)
# ─────────────────────────────────────────────────────────────────────────────

class CustomCatalogDataset(Dataset):
    """
    Build training data from manually curated outfits or GPT recommendation history.

    Expected JSON format:
        [
            {
                "outfit_id": "1",
                "items": [
                    {"id": "item1", "image_path": "path/to/img.jpg", "category": "topwear"},
                    {"id": "item2", "image_path": "path/to/img.jpg", "category": "bottomwear"}
                ]
            }
        ]
    """

    def __init__(self, outfits_json: str):
        with open(outfits_json, "r") as f:
            self.outfits = json.load(f)

        self.cat_to_items: dict[str, list[dict]] = {}
        for outfit in self.outfits:
            for item in outfit["items"]:
                cat = item["category"]
                self.cat_to_items.setdefault(cat, []).append(item)

        print(f"Loaded {len(self.outfits)} custom outfits")

    def __len__(self):
        return len(self.outfits)

    def __getitem__(self, idx):
        outfit = self.outfits[idx]
        items = outfit["items"]

        anchor = []
        for item in items:
            img = image_transform(Image.open(item["image_path"]).convert("RGB"))
            anchor.append((img, item["category"]))

        positive = anchor.copy()

        negative = anchor.copy()
        swap_idx = random.randint(0, len(negative) - 1)
        swap_cat = negative[swap_idx][1]

        candidates = self.cat_to_items.get(swap_cat, [])
        current_ids = {item["id"] for item in items}

        for _ in range(10):
            candidate = random.choice(candidates) if candidates else None
            if candidate and candidate["id"] not in current_ids:
                try:
                    neg_img = image_transform(Image.open(candidate["image_path"]).convert("RGB"))
                    negative[swap_idx] = (neg_img, swap_cat)
                    break
                except Exception:
                    continue

        return anchor, positive, negative


# ─────────────────────────────────────────────────────────────────────────────
# 3. TRAINING LOOP
# ─────────────────────────────────────────────────────────────────────────────

def train_model(
    model: TACN,
    dataset: Dataset,
    epochs: int = 20,
    lr: float = 1e-4,
    device: str = "cpu",
    save_every: int = 5,
    output_path: str = "tacn_weights.pth",
):
    """Train TACN with triplet loss."""
    model.to(device)
    model.train()

    optimizer = torch.optim.Adam(
        filter(lambda p: p.requires_grad, model.parameters()), lr=lr, weight_decay=1e-5
    )
    scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=7, gamma=0.5)
    loss_fn = TripletCompatibilityLoss(margin=MARGIN)
    # Custom collate: outfits are variable-length lists of (tensor, str) tuples
    # Default collate can't handle this, so we pass them through as-is
    def collate_fn(batch):
        return batch[0]  # batch_size=1, just unwrap

    loader = DataLoader(dataset, batch_size=1, shuffle=True, num_workers=0, collate_fn=collate_fn)

    best_loss = float("inf")

    for epoch in range(1, epochs + 1):
        epoch_loss = 0.0
        n_batches = 0

        for anchor, positive, negative in loader:
            # Each item is (3, 224, 224) — unsqueeze to (1, 3, 224, 224) for the model
            anchor_items = [(img.unsqueeze(0).to(device), cat) for img, cat in anchor]
            pos_items = [(img.unsqueeze(0).to(device), cat) for img, cat in positive]
            neg_items = [(img.unsqueeze(0).to(device), cat) for img, cat in negative]

            optimizer.zero_grad()

            s_a = model.score_outfit(anchor_items)
            s_p = model.score_outfit(pos_items)
            s_n = model.score_outfit(neg_items)

            loss = loss_fn(s_a, s_p, s_n)
            loss.backward()
            optimizer.step()

            epoch_loss += loss.item()
            n_batches += 1

            if n_batches % 500 == 0:
                print(f"  Epoch {epoch} — batch {n_batches}/{len(loader)} — loss: {loss.item():.4f}")

        avg_loss = epoch_loss / max(n_batches, 1)
        print(f"Epoch {epoch:>3}/{epochs}  |  loss = {avg_loss:.4f}")

        if avg_loss < best_loss:
            best_loss = avg_loss

        scheduler.step()

        if epoch % save_every == 0:
            save_model(model, output_path)
            print(f"  → Checkpoint saved (best_loss={best_loss:.4f})")

    save_model(model, output_path)
    print(f"\nTraining complete. Final model saved to {output_path}")
    return model


# ─────────────────────────────────────────────────────────────────────────────
# 4. GENERATE TRAINING DATA FROM GPT RECOMMENDATION HISTORY
# ─────────────────────────────────────────────────────────────────────────────

def generate_training_data_from_history(
    db_export_path: str,
    images_dir: str,
    output_path: str = "custom_outfits.json",
):
    """
    Convert saved GPT recommendations into TACN training data.

    Export your outfit_recommendations table as JSON, then run this.
    GPT-approved combos become positive examples.
    """
    with open(db_export_path, "r") as f:
        recs = json.load(f)

    outfits = []
    for rec in recs:
        payload = rec.get("recommendation_payload", {})
        for combo in payload.get("combinations", []):
            items = []
            valid = True
            for oi in combo.get("items", []):
                img_path = os.path.join(images_dir, f"{oi['item_id']}.jpg")
                if not os.path.exists(img_path):
                    valid = False
                    break
                items.append({
                    "id": oi["item_id"],
                    "image_path": img_path,
                    "category": oi.get("category", "topwear"),
                })
            if valid and len(items) >= 2:
                outfits.append({"outfit_id": str(len(outfits)), "items": items})

    with open(output_path, "w") as f:
        json.dump(outfits, f, indent=2)

    print(f"Generated {len(outfits)} training outfits → {output_path}")
    return outfits


# ─────────────────────────────────────────────────────────────────────────────
# 5. CLI ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Train TACN outfit compatibility model")
    parser.add_argument("--data_dir", type=str, default="./data",
                        help="Path to dataset directory (with styles.csv + images/)")
    parser.add_argument("--custom_json", type=str,
                        help="Path to custom outfits JSON (alternative to Fashion Product dataset)")
    parser.add_argument("--num_outfits", type=int, default=10000,
                        help="Number of synthetic outfits to generate (for Fashion Product dataset)")
    parser.add_argument("--epochs", type=int, default=20)
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--output", type=str, default="tacn_weights.pth")
    parser.add_argument("--device", type=str,
                        default="cuda" if torch.cuda.is_available() else "cpu")
    parser.add_argument("--save_every", type=int, default=5)
    args = parser.parse_args()

    print("=" * 60)
    print("TACN Training — StyloBuddy")
    print("=" * 60)
    print(f"Device: {args.device}")
    print(f"Epochs: {args.epochs}, LR: {args.lr}")
    print(f"Output: {args.output}")
    print()

    model = TACN(frozen_backbone=True)  # True = freeze early layers, fine-tune last 2 blocks
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    total = sum(p.numel() for p in model.parameters())
    print(f"Model: {total:,} params ({trainable:,} trainable)")
    print()

    if args.custom_json:
        print(f"Loading custom outfits from {args.custom_json}")
        dataset = CustomCatalogDataset(args.custom_json)
    else:
        print(f"Loading Fashion Product Images from {args.data_dir}")
        dataset = FashionProductDataset(args.data_dir, num_outfits=args.num_outfits)

    if len(dataset) == 0:
        print("ERROR: Dataset is empty. Check paths and image files.")
        return

    print(f"Dataset size: {len(dataset)} outfits")
    print()

    train_model(
        model=model,
        dataset=dataset,
        epochs=args.epochs,
        lr=args.lr,
        device=args.device,
        save_every=args.save_every,
        output_path=args.output,
    )


if __name__ == "__main__":
    main()
