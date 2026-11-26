# Eye Health

Welcome to Eye Health, a [Flutter](https://docs.flutter.dev/) mobile application built with Dart. The app helps people capture or upload a fundus photograph, see screening-oriented feedback for diabetic retinopathy and glaucoma, ask follow-up questions, and keep those photos in personal health statistics. Screening runs on a local model server. The assistant is for education. It is not a clinical diagnosis or a replacement for an eye exam.

## Table of Contents

- [Demo](#demo)
- [Editor Setup](#editor-setup)
- [Development Setup](#development-setup)
- [Project Configuration](#project-configuration)
- [APIs](#apis)
- [Running the App Locally](#running-the-app-locally)
- [Screening Server](#screening-server)
- [About the Diseases](#about-the-diseases)
- [Screening Models](#screening-models)
- [Build](#build)

## Demo

Walkthrough video here.

<!--
[Watch the demo](docs/demo.mp4)
-->

## Editor Setup

These tools keep the Dart code consistent. Install them in the editor you use for this repo.

- [Dart](https://dart.dev/tools/dart-format) and the Flutter formatter
- [flutter_lints](https://pub.dev/packages/flutter_lints), already enabled in `analysis_options.yaml`

## Development Setup

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (this project uses Dart SDK `^3.7.0`)
- [Xcode](https://developer.apple.com/xcode/) for the iOS simulator
- [Android Studio](https://developer.android.com/studio) for the Android emulator
- Python 3.13 for the screening server

> Follow the device setup in the [Flutter install guide](https://docs.flutter.dev/get-started/install) before the first run. `flutter doctor` should be clean for the platform you are targeting.

The repo has two projects:

| Path | Project | Role |
| --- | --- | --- |
| Repo root (`lib/`, `android/`, `ios/`) | Flutter app | Mobile UI |
| [`services/screening_server/`](services/screening_server/) | Python FastAPI | Loads the `.pt` models and serves `POST /screen` |

The screening server is not bundled into the app. Run it separately and point the app at it with `SCREENING_BASE_URL`.

## Project Configuration

### Config files

Secrets and environment values are passed at compile time with `--dart-define-from-file`. They live in the project root and are not committed.

```
|- project-root
  |- config.dev.template.json
  |- config.dev.json
  |- config.prod.template.json
  |- config.prod.json
```

### `config.dev.template.json`

```json
{
  "OPENROUTER_BASE_URL": "https://openrouter.ai/api/v1",
  "OPENROUTER_API_KEY": "your_openrouter_api_key_here",
  "OPENROUTER_MODEL": "google/gemma-4-26b-a4b-it:free",
  "OPENROUTER_HTTP_REFERER": "http://localhost",
  "OPENROUTER_APP_TITLE": "Eye Health",
  "SCREENING_BASE_URL": "http://127.0.0.1:8000",
  "APP_ENV": "development"
}
```

`OPENROUTER_API_KEY` is an OpenRouter key (`sk-or-v1-…`) from [openrouter.ai/keys](https://openrouter.ai/keys). It is used only when the user asks a question in chat. Fundus screening does not call OpenRouter. Those results come from the local server.

Copy the template, then fill in the key:

```bash
cp config.dev.template.json config.dev.json
```

These values are compiled into the app. After you change `config.dev.json`, stop the app and start it again. A hot reload will not pick them up.

## APIs

Two services sit behind the app.

**OpenRouter** answers questions in the chat. The app calls `OPENROUTER_BASE_URL` with `OPENROUTER_API_KEY` and `OPENROUTER_MODEL`. That key comes from [openrouter.ai/keys](https://openrouter.ai/keys).

**Screening API** scores the fundus photo. The app posts the image to the local server at `SCREENING_BASE_URL` (`POST /screen`). That server runs the diabetic retinopathy and glaucoma models and returns the grades. Chat does not call this API, and screening does not call OpenRouter.

## Running the App Locally

From the project root, with the screening server already running:

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run on a simulator or device

```bash
flutter run --dart-define-from-file=config.dev.json
```

## Screening Server

Full notes: [services/screening_server/README.md](services/screening_server/README.md).

```bash
cd services/screening_server
python3.13 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

- Health: http://127.0.0.1:8000/health
- Docs: http://127.0.0.1:8000/docs

## About the Diseases

Many people with diabetes or elevated eye pressure do not get regular dilated eye exams. Damage from diabetic retinopathy and glaucoma can progress quietly until vision is already reduced.

### Diabetic retinopathy (DR)

Diabetic retinopathy is a complication of diabetes that damages the small blood vessels of the retina. Early stages may have no symptoms. Later stages can cause bleeding, swelling, and permanent vision loss if untreated.

Screening grades severity on a scale. This project’s DR model outputs classes **0–4**:

| Grade | Meaning (simplified) |
| --- | --- |
| **0** | No diabetic retinopathy |
| **1–4** | Increasing severity of DR |

Catching DR early allows referral for monitoring or treatment, such as laser or injections, before severe vision loss.

### Glaucoma

Glaucoma is a group of diseases that damage the optic nerve, often linked to elevated intraocular pressure. Vision loss usually starts in the peripheral field and can go unnoticed until it is advanced.

This project’s glaucoma model is a **binary screen**: suggestive of glaucoma, or not. It flags people who may need a full clinical workup. It does not confirm a diagnosis on its own.

Both results are for education and screening support. A clinician makes the diagnosis.

## Screening Models

The screening server loads two trained models. The Flutter app never loads the weights itself.

| Model | Task |
| --- | --- |
| **MobileViT-S** | Diabetic retinopathy, multi-class grades 0–4 |
| **MobileOne-S4** | Glaucoma, binary screen |

## Build

Development:

```bash
flutter run --dart-define-from-file=config.dev.json
```

Release builds pass the production config file the same way. See [README_API_SETUP.md](README_API_SETUP.md) for the Android and iOS release commands.

Keep real keys in `config.dev.json` and `config.prod.json`. Commit only the `config.*.template.json` files.
