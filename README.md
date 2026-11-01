# StyloBuddy

StyloBuddy is an outfit recommendation platform that combines a small trained compatibility model with an LLM styling assistant.

This repository is the entry point. Each part of the project lives in its own repository, and this repo links to all of them.

| Part | Repository | Stack |
|---|---|---|
| Web portal | [stylobuddy-web](https://github.com/nabeedjamshedali/stylobuddy-web) | Next.js, TypeScript, Tailwind CSS |
| Backend API | [stylobuddy-backend](https://github.com/nabeedjamshedali/stylobuddy-backend) | FastAPI, PostgreSQL (Supabase), PyTorch, PydanticAI, JWT auth |
| Mobile app | [stylobuddy-mobile](https://github.com/nabeedjamshedali/stylobuddy-mobile) | Flutter, Firebase |
| TACN model (research code) | [stylobuddy-model](https://github.com/nabeedjamshedali/stylobuddy-model) | PyTorch |

## Get the code

Everything at once:

```
git clone --recurse-submodules https://github.com/nabeedjamshedali/stylobuddy.git
```

If you already cloned without `--recurse-submodules`:

```
git submodule update --init --recursive
```

Only one part, for example the mobile app:

```
git clone https://github.com/nabeedjamshedali/stylobuddy-mobile.git
```

## Research

The model and the hybrid TACN + LLM approach are described in the technical report:

*StyloBuddy: A Hybrid Deep Learning and LLM Framework for Trend-Aware Outfit Recommendation*, [doi:10.5281/zenodo.23838353](https://doi.org/10.5281/zenodo.23838353).

## Folders in this repo

`web/`, `backend/`, `mobile/` and `model/` are git submodules that point to the repositories above. Work happens inside each of those repositories. After changes are pushed there, update this repo's pointers with `git submodule update --remote` and commit.
