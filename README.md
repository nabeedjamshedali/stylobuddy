# StyloBuddy

StyloBuddy is an outfit recommendation platform that combines a small trained compatibility model with an LLM styling assistant. This repository holds the whole project in one place.

| Folder | What it is | Stack |
|---|---|---|
| [`web/`](web) | Web portal | Next.js, TypeScript, Tailwind CSS |
| [`backend/`](backend) | API behind the web portal | FastAPI, PostgreSQL (Supabase), PyTorch, PydanticAI, JWT auth |
| [`mobile/`](mobile) | Mobile app | Flutter, Firebase |
| [`model/`](model) | TACN model research code (Type-Aware Compatibility Network) | PyTorch |

## Research

The model and the hybrid TACN + LLM approach are described in the technical report:

*StyloBuddy: A Hybrid Deep Learning and LLM Framework for Trend-Aware Outfit Recommendation*, [doi:10.5281/zenodo.23838353](https://doi.org/10.5281/zenodo.23838353).

## Running the parts

Each folder is self-contained.

- Web portal: see `web/package.json` (`npm install`, `npm run dev`).
- Backend: see `backend/requirements.txt` and `backend/alembic.ini` (install requirements, run migrations, start with `uvicorn app.main:app`).
- Mobile app: `flutter pub get` inside `mobile/`.
- Model: see [`model/README.md`](model/README.md) for training.

Configuration files with secrets (`.env`, `.env.local`, `android/key.properties`) are not part of the repository.

## History

This repository was assembled from three earlier repositories (`stylobuddy`, `stylobuddy-frontend`, `stylobuddy-outfit-recommendator`). Their commit history is kept.
