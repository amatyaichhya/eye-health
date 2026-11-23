# Eye Health Screening Server

Standalone **Python / FastAPI** project in this monorepo. It loads the trained `.pt` models and exposes an HTTP API that the Flutter app calls for fundus screening.

This is **not** part of the Flutter binary — run it separately on your machine (or a host) while demoing.

## Prerequisites

- Models in `~/Downloads/screening_models/`:
  - `mobilevit_s_diabetic_retinopathy.pt`
  - `mobileone_s4_glaucoma_class_sinkhorn_seed45.pt`
- Python **3.13** recommended (PyTorch may not support 3.14 yet)

## Setup (one time)

```bash
cd services/screening_server

python3.13 -m venv .venv
# or: python3 -m venv .venv

source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

Optional: inspect checkpoint structure:

```bash
python inspect_checkpoint.py
```

## Run the server

```bash
cd services/screening_server
source .venv/bin/activate

# Optional: custom model folder
# export SCREENING_MODEL_DIR="$HOME/Downloads/screening_models"

uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

- Health: http://127.0.0.1:8000/health  
- Docs: http://127.0.0.1:8000/docs  

## Test from terminal

```bash
curl -s http://127.0.0.1:8000/health | python -m json.tool

curl -s -X POST http://127.0.0.1:8000/screen \
  -F "file=@$HOME/Downloads/test - Copy/20170413112758639.jpg" \
  | python -m json.tool
```

## Connect from Flutter

Set `SCREENING_BASE_URL` in `config.dev.json` (repo root):

| Where you run the app | Base URL |
|---|---|
| iOS Simulator / Android emulator (Mac host) | `http://127.0.0.1:8000` |
| Physical phone on same Wi‑Fi | `http://<your-mac-lan-ip>:8000` |

Find your Mac IP: `ipconfig getifaddr en0`

Keep this server running while you demo screening in the app.

## Notes

- Preprocessing uses ImageNet normalize + 224×224. If training used different size/normalization, accuracy will be off until matched.
- Demo only — not for clinical diagnosis.
