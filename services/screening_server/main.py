"""
Local screening API for Eye Health demo.

Endpoints:
  GET  /health
  POST /screen   (multipart form field: file=<image>)
"""

from __future__ import annotations

import io
import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

from model_loader import ScreeningModels

DEFAULT_MODEL_DIR = Path.home() / "Downloads" / "screening_models"
MODEL_DIR = Path(os.environ.get("SCREENING_MODEL_DIR", DEFAULT_MODEL_DIR)).expanduser()

models: ScreeningModels | None = None


@asynccontextmanager
async def lifespan(_: FastAPI):
    global models
    try:
        models = ScreeningModels(MODEL_DIR)
    except Exception as exc:  # load error
        print(f"Failed to load models: {exc}")
        raise
    yield
    models = None


app = FastAPI(title="Eye Health Screening API", version="0.1.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {
        "status": "ok",
        "models_loaded": models is not None,
        "model_dir": str(MODEL_DIR),
    }


@app.post("/screen")
async def screen(file: UploadFile = File(...)):
    if models is None:
        raise HTTPException(status_code=503, detail="Models not loaded")

    if not file.content_type or not file.content_type.startswith("image/"):
        pass

    raw = await file.read()
    if not raw:
        raise HTTPException(status_code=400, detail="Empty file")

    try:
        image = Image.open(io.BytesIO(raw))
        result = models.predict(image)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=400, detail=f"Inference failed: {exc}") from exc

    return {
        "success": True,
        "filename": file.filename,
        **result,
    }
