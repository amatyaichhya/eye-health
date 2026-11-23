"""Inspect .pt checkpoint structure (run after installing requirements)."""

from __future__ import annotations

import sys
from pathlib import Path

import torch

DEFAULT_MODELS = Path.home() / "Downloads" / "screening_models"


def summarize(path: Path) -> None:
    print(f"\n=== {path.name} ===")
    obj = torch.load(path, map_location="cpu", weights_only=False)
    print("type:", type(obj))
    if not isinstance(obj, dict):
        print(obj)
        return

    print("top keys:", list(obj.keys())[:40])
    for key in ("state_dict", "model", "model_state_dict", "net", "weights"):
        if key not in obj:
            continue
        sd = obj[key]
        print(f"nested[{key}] type={type(sd)}")
        if isinstance(sd, dict):
            keys = list(sd.keys())
            print("  tensors:", len(keys))
            print("  first:", keys[:6])
            print("  last:", keys[-4:])
            for ck in ("num_classes", "args", "config", "epoch"):
                if ck in obj:
                    print(f"  meta {ck}:", obj[ck])

    tensor_keys = [k for k, v in obj.items() if torch.is_tensor(v)]
    if tensor_keys:
        print("direct tensors:", len(tensor_keys))
        print("  first:", tensor_keys[:6])
        print("  last:", tensor_keys[-4:])
        # Guess classifier size
        for k in reversed(tensor_keys):
            if any(x in k.lower() for x in ("classifier", "fc", "head")) and k.endswith(
                ("weight", "bias")
            ):
                print(f"  classifier-ish {k}: shape={tuple(obj[k].shape)}")


def main() -> None:
    model_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_MODELS
    paths = sorted(model_dir.glob("*.pt"))
    if not paths:
        print(f"No .pt files in {model_dir}")
        sys.exit(1)
    for path in paths:
        summarize(path)


if __name__ == "__main__":
    main()
