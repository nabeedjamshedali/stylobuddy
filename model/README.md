# TACN: Type-Aware Compatibility Network

Research code for the technical report *StyloBuddy: A Hybrid Deep Learning and LLM Framework for Trend-Aware Outfit Recommendation* ([Zenodo, doi:10.5281/zenodo.23838353](https://doi.org/10.5281/zenodo.23838353)).

TACN scores outfit compatibility with a partially fine-tuned ResNet-18 backbone and a separate projection head per garment type, trained with a margin-based contrastive loss and hard-negative mining.

| File | Purpose |
|---|---|
| `outfit_recommendation_model.py` | TACN model, contrastive loss, image transforms, save/load helpers |
| `train_tacn.py` | Builds synthetic outfit pairs from the Fashion Product Images dataset and trains TACN |
| `tacn_service_inference.py` | Inference service used by the FastAPI backend (shown for reference; it imports `app.core`) |

## Train

1. Download the [Fashion Product Images](https://www.kaggle.com/datasets/paramaggarwal/fashion-product-images-small) dataset into `./data` (`styles.csv` and `images/`).
2. Install dependencies: `pip install torch torchvision pillow`.
3. Run:

```
python train_tacn.py --data_dir ./data --epochs 20 --lr 1e-4
```

Trained weights are not included; retrain with the command above (20 epochs on a Tesla T4 in the report).
