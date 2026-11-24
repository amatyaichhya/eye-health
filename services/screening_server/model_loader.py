"""Load MobileViT-S (DR) and MobileOne-S4 (glaucoma) checkpoints with timm."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import timm
import torch
import torch.nn as nn
import torch.nn.functional as F
from PIL import Image
from torchvision import transforms

DR_LABELS = {
    0: "No DR",
    1: "Mild NPDR",
    2: "Moderate NPDR",
    3: "Severe NPDR",
    4: "Proliferative DR",
}


def _extract_state_dict(obj: Any) -> dict[str, torch.Tensor]:
    if isinstance(obj, nn.Module):
        return obj.state_dict()
    if not isinstance(obj, dict):
        raise ValueError(f"Unsupported checkpoint type: {type(obj)}")

    for key in (
        "model_state",
        "state_dict",
        "model",
        "model_state_dict",
        "net",
        "weights",
    ):
        if key in obj and isinstance(obj[key], dict):
            sd = obj[key]
            break
    else:
        # Raw state_dict
        if obj and all(torch.is_tensor(v) for v in obj.values()):
            sd = obj
        else:
            raise ValueError(f"Could not find state_dict in keys: {list(obj.keys())}")

    # Strip common prefixes from training wrappers
    cleaned: dict[str, torch.Tensor] = {}
    for k, v in sd.items():
        nk = k
        for prefix in ("module.", "model.", "net.", "backbone."):
            if nk.startswith(prefix):
                nk = nk[len(prefix) :]
        # Training code used Linear `head`; timm classifiers often use `head.fc`
        if nk in ("head.weight", "head.bias"):
            nk = nk.replace("head.", "head.fc.", 1)
        cleaned[nk] = v
    return cleaned


def _infer_num_classes(state_dict: dict[str, torch.Tensor], default: int) -> int:
    for key in reversed(list(state_dict.keys())):
        if key.endswith("weight") and any(
            x in key for x in ("classifier", "head.fc", "head", "fc")
        ):
            w = state_dict[key]
            if w.ndim == 2:
                return int(w.shape[0])
    return default


def _read_checkpoint_meta(raw: Any) -> dict[str, Any]:
    """Pull training flags used at inference (feature norm, referral threshold)."""
    meta: dict[str, Any] = {
        "use_feature_norm": True,  # both shipped checkpoints trained with this
        "best_ref_thr": None,
        "img_size": 224,
    }
    if not isinstance(raw, dict):
        return meta

    if "best_ref_thr" in raw:
        try:
            meta["best_ref_thr"] = float(raw["best_ref_thr"])
        except (TypeError, ValueError):
            pass

    sig = raw.get("training_signature")
    if isinstance(sig, dict):
        if "use_feature_norm" in sig:
            meta["use_feature_norm"] = bool(sig["use_feature_norm"])
        if "img_size" in sig:
            try:
                meta["img_size"] = int(sig["img_size"])
            except (TypeError, ValueError):
                pass
    return meta


def _build_and_load(
    arch: str, checkpoint: Path, default_classes: int
) -> tuple[nn.Module, dict[str, Any]]:
    raw = torch.load(checkpoint, map_location="cpu", weights_only=False)
    meta = _read_checkpoint_meta(raw)
    state_dict = _extract_state_dict(raw)
    num_classes = _infer_num_classes(state_dict, default_classes)
    model = timm.create_model(arch, pretrained=False, num_classes=num_classes)
    missing, unexpected = model.load_state_dict(state_dict, strict=False)
    if missing:
        print(f"[{arch}] missing keys ({len(missing)}): {missing[:5]}...")
    if unexpected:
        print(f"[{arch}] unexpected keys ({len(unexpected)}): {unexpected[:5]}...")
    model.eval()
    print(
        f"[{arch}] classes={num_classes} "
        f"feature_norm={meta['use_feature_norm']} "
        f"best_ref_thr={meta['best_ref_thr']}"
    )
    return model, meta


def default_transform(image_size: int = 224) -> transforms.Compose:
    # Standard ImageNet-style preprocessing used by most timm classifiers.
    return transforms.Compose(
        [
            transforms.Resize((image_size, image_size)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=(0.485, 0.456, 0.406),
                std=(0.229, 0.224, 0.225),
            ),
        ]
    )


class ScreeningModels:
    def __init__(self, model_dir: Path, device: str | None = None) -> None:
        self.device = torch.device(
            device or ("cuda" if torch.cuda.is_available() else "cpu")
        )

        dr_path = model_dir / "mobilevit_s_diabetic_retinopathy.pt"
        gl_path = model_dir / "mobileone_s4_glaucoma_class_sinkhorn_seed45.pt"
        if not dr_path.exists() or not gl_path.exists():
            raise FileNotFoundError(
                f"Expected model files in {model_dir}. Found: {list(model_dir.glob('*.pt'))}"
            )

        print(f"Loading models on {self.device} from {model_dir}")
        self.dr_model, self.dr_meta = _build_and_load(
            "mobilevit_s", dr_path, default_classes=5
        )
        self.dr_model = self.dr_model.to(self.device)

        self.glaucoma_model, self.gl_meta = _build_and_load(
            "mobileone_s4", gl_path, default_classes=2
        )
        self.glaucoma_model = self.glaucoma_model.to(self.device)

        img_size = int(self.dr_meta.get("img_size") or 224)
        self.transform = default_transform(img_size)
        print("Models loaded.")

    def _forward_logits(self, model: nn.Module, batch: torch.Tensor, *, use_feature_norm: bool) -> torch.Tensor:
        """Match training forward: pool → optional L2 feature norm → linear head."""
        features = model.forward_features(batch)
        pooled = model.head.global_pool(features)
        if use_feature_norm:
            pooled = F.normalize(pooled, p=2, dim=1)
        pooled = model.head.drop(pooled)
        return model.head.fc(pooled)

    @torch.inference_mode()
    def predict(self, image: Image.Image) -> dict[str, Any]:
        rgb = image.convert("RGB")
        batch = self.transform(rgb).unsqueeze(0).to(self.device)

        dr_logits = self._forward_logits(
            self.dr_model,
            batch,
            use_feature_norm=bool(self.dr_meta.get("use_feature_norm", True)),
        )
        dr_probs = torch.softmax(dr_logits, dim=1)[0]
        dr_grade = int(torch.argmax(dr_probs).item())
        # Referable DR ≈ moderate or worse (grades 2–4)
        referable_prob = float(dr_probs[2:].sum().item()) if dr_probs.numel() >= 5 else 0.0
        ref_thr = self.dr_meta.get("best_ref_thr")
        if ref_thr is None:
            referable = dr_grade >= 2
        else:
            referable = referable_prob >= float(ref_thr)

        gl_logits = self._forward_logits(
            self.glaucoma_model,
            batch,
            use_feature_norm=bool(self.gl_meta.get("use_feature_norm", True)),
        )
        gl_probs = torch.softmax(gl_logits, dim=1)[0]
        gl_pred = int(torch.argmax(gl_probs).item())
        gl_pos = float(gl_probs[1].item()) if gl_probs.numel() > 1 else float(gl_probs[0].item())
        gl_thr = self.gl_meta.get("best_ref_thr")
        if gl_thr is not None:
            gl_positive = gl_pos >= float(gl_thr)
        else:
            gl_positive = bool(gl_pred == 1)

        return {
            "diabetic_retinopathy": {
                "grade": dr_grade,
                "label": DR_LABELS.get(dr_grade, f"Grade {dr_grade}"),
                "probabilities": {
                    str(i): float(dr_probs[i].item()) for i in range(dr_probs.numel())
                },
                "referable": referable,
                "referable_probability": referable_prob,
                "referable_threshold": ref_thr,
            },
            "glaucoma": {
                "positive": gl_positive,
                "class_index": gl_pred,
                "label": (
                    "Suggestive of glaucoma"
                    if gl_positive
                    else "No glaucoma suggested"
                ),
                "probabilities": {
                    "negative": float(gl_probs[0].item()) if gl_probs.numel() > 0 else None,
                    "positive": gl_pos,
                },
                "threshold": gl_thr,
            },
        }
