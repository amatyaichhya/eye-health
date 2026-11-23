# Eye Health

Flutter mobile app that helps people and clinicians screen for common vision-threatening eye diseases from **fundus photographs**, with supportive education and follow-up tools.

## Goal of the app

Many people with diabetes or elevated eye pressure do not get regular dilated eye exams. Damage from **diabetic retinopathy** and **glaucoma** can progress quietly until vision is already reduced.

**Eye Health** aims to make early screening more accessible by letting users:

1. **Capture or upload** a fundus (retina) photo on a phone  
2. Get **screening-oriented feedback** for diabetic retinopathy and glaucoma via a local API  
3. Ask follow-up questions through an **eye-health assistant**  
4. Track simple **personal health statistics** over time  

The app is for **education and screening support**. It is **not** a replacement for a clinical diagnosis or a full eye exam.

---

## Monorepo layout

| Path | Project | Role |
|---|---|---|
| Repo root (`lib/`, `android/`, `ios/`, …) | **Flutter app** | Mobile UI; sends images over HTTP |
| [`services/screening_server/`](services/screening_server/) | **Python FastAPI** | Loads `.pt` models and runs `/screen` |

The screening server is a **separate project** in this repo — it is not bundled into the app. Run it locally, then point the app at it with `SCREENING_BASE_URL`.

---

## About the diseases

### Diabetic retinopathy (DR)

Diabetic retinopathy is a complication of diabetes that damages the small blood vessels of the retina. Early stages may have no symptoms; later stages can cause bleeding, swelling, and permanent vision loss if untreated.

Screening typically grades severity on a scale. This project’s DR model is planned to output classes **0–4**:

| Grade | Meaning (simplified) |
|---|---|
| **0** | No diabetic retinopathy |
| **1–4** | Increasing severity of DR |

Catching DR early allows referral for monitoring or treatment (e.g. laser, injections) before severe vision loss.

### Glaucoma

Glaucoma is a group of diseases that damage the optic nerve, often linked to elevated intraocular pressure. Vision loss usually starts in the peripheral field and can go unnoticed until advanced.

This project’s glaucoma model is planned as a **binary screen** (e.g. suggestive of glaucoma vs not), to flag people who may need a full clinical workup—not to confirm a definitive diagnosis alone.

---

## Current features

- Splash → home (take / upload fundus photo, statistics, conversation)
- Camera & gallery capture
- AI assistant chat via Hugging Face (config through `--dart-define-from-file`)
- Personal health statistics screen (demo UI)

## Screening models

Collaborators provided trained weights and DR test images:

| Package | Contents |
|---|---|
| `screening_models.zip` | **MobileViT-S** (DR, multi-class 0–4) and **MobileOne-S4** (glaucoma, binary) |
| `test - Copy.zip` | Sample DR fundus images + a text file of true grades (labels) |

Place the `.pt` files under `~/Downloads/screening_models/` (or set `SCREENING_MODEL_DIR`). The Flutter app does **not** load these files — only `services/screening_server` does.

---

## Run the app

```bash
flutter pub get

# Copy template and add keys (include SCREENING_BASE_URL)
cp config.dev.template.json config.dev.json

flutter run --dart-define-from-file=config.dev.json
```

### Run the screening server (separate project)

```bash
cd services/screening_server
python3.13 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Full details: [services/screening_server/README.md](services/screening_server/README.md).

See [README_API_SETUP.md](README_API_SETUP.md) for API and build details.

## Project utilities

```bash
dart run change_app_package_name:main "com.mit.eyehealth"
dart run rename_app:main all="Eye Health"
dart run flutter_launcher_icons:main
```

## Security

- Keep real API keys in `config.dev.json` / `config.prod.json` (gitignored).
- Commit only `config.*.template.json` with placeholders.
