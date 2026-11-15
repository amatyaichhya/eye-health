# 🔐 Secure API Configuration Setup

This project follows security best practices for handling API keys and secrets in Flutter, as outlined in [this excellent Medium article](https://alaminkarno.medium.com/wait-youre-using-env-files-in-flutter-for-secrets-let-s-talk-before-it-s-too-late-0b622ee28db6).

## 🚨 Important Security Note

**Never commit real API keys to version control!** This project uses `--dart-define` to inject secrets at build time, keeping them out of your app bundle.

## 🚀 Quick Setup (Automated)

### Option 1: Use the Setup Script
```bash
# Make scripts executable (first time only)
chmod +x setup_config.sh local_build.sh

# Setup configuration for development
./setup_config.sh dev

# Or setup both dev and production
./setup_config.sh both
```

### Option 2: Manual Setup

## 📋 Manual Setup Instructions

### 1. Get Your OpenAI API Key
1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create a new API key
3. Copy the key (you'll only see it once!)

### 2. Create Your Config Files

Copy the template files and add your real API keys:

```bash
# Copy templates
cp config.dev.template.json config.dev.json
cp config.prod.template.json config.prod.json

# Edit the files and replace "your_dev_api_key_here" with your actual API key
```

## 🏗️ Building the App

### Automated Build System

Use the provided build script for secure, automated builds:

```bash
# Development build (faster, less secure)
./local_build.sh

# Development build with specific build number
./local_build.sh 5

# Production build (obfuscated, secure)
./local_build.sh 1 prod

# Production build with specific build number
./local_build.sh 10 prod
```

### Manual Build Commands

#### Development Build
```bash
flutter run --dart-define-from-file=config.dev.json
```

#### Production Build (Android)
```bash
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=./debug_info \
  --dart-define-from-file=config.prod.json
```

#### Production Build (iOS)
```bash
flutter build ios \
  --release \
  --obfuscate \
  --split-debug-info=./debug_info \
  --dart-define-from-file=config.prod.json
```

### 4. Alternative: Single Key Method

If you prefer to pass just the API key:

```bash
flutter run --dart-define=OPENAI_API_KEY=your_actual_api_key_here
```

## 🛡️ Security Features

✅ **Secrets injected at build time** - Not bundled as assets  
✅ **Code obfuscation enabled** - Makes reverse engineering harder (prod builds)  
✅ **Config files in .gitignore** - Real secrets never committed  
✅ **Template files provided** - Easy setup for new developers  
✅ **Environment-specific configs** - Different keys for dev/prod  
✅ **Automated build validation** - Checks API key configuration before building  
✅ **Build artifact management** - Organized output with build information  

## 🔍 How It Works

1. **Build Time**: Secrets are injected using `--dart-define-from-file`
2. **Runtime**: App reads secrets using `String.fromEnvironment()`
3. **Security**: Secrets are compiled into the binary, not stored as plain text assets

## 📁 File Structure

```
├── config.dev.template.json     # Template (safe to commit)
├── config.prod.template.json    # Template (safe to commit)
├── config.dev.json             # Real secrets (gitignored)
├── config.prod.json            # Real secrets (gitignored)
├── lib/config/api_config.dart   # Configuration class
├── setup_config.sh             # Automated setup script
└── local_build.sh              # Automated build script
```

## 🏗️ Build System Features

The automated build system (`local_build.sh`) provides:

- **Environment validation** - Ensures config files exist and API keys are set
- **Git state checking** - Prevents builds with uncommitted changes
- **Automatic versioning** - Date-based versioning with build numbers
- **Build artifact organization** - Organized output directories
- **Security options** - Full obfuscation for production builds
- **Build information** - Detailed build metadata saved with each APK
- **Cleanup management** - Automatic cleanup of old build folders

## 🚫 What NOT to Do

❌ Don't use `.env` files with `flutter_dotenv` for secrets  
❌ Don't hardcode API keys in Dart files  
❌ Don't commit config files with real secrets  
❌ Don't skip code obfuscation in production builds  

## 🔧 Troubleshooting

### "API key not configured" Error
1. Run `./setup_config.sh` to create config files
2. Or manually ensure you've created `config.dev.json` from the template
3. Replace `"your_dev_api_key_here"` with your actual OpenAI API key
4. Use the correct build command with `--dart-define-from-file`

### Build Script Errors
1. Ensure scripts are executable: `chmod +x setup_config.sh local_build.sh`
2. Check that your config JSON is valid
3. Ensure all required fields are present
4. Verify your API key is correct

### Build Fails
1. Check that your config JSON is valid
2. Ensure all required fields are present
3. Verify your API key is correct

## 📚 Learn More

- [Medium Article: Secure Flutter Secrets](https://alaminkarno.medium.com/wait-youre-using-env-files-in-flutter-for-secrets-let-s-talk-before-it-s-too-late-0b622ee28db6)
- [Flutter Documentation: dart-define](https://docs.flutter.dev/deployment/flavors#define-separate-app-icons-and-names)
- [OpenAI API Documentation](https://platform.openai.com/docs)

## 🤝 Team Setup

When onboarding new developers:

1. Share this README
2. Have them run `./setup_config.sh dev`
3. Provide them with development API keys separately (Slack, email, etc.)
4. Never share production keys in group channels

## 🎯 Quick Start Summary

```bash
# 1. Setup (first time only)
./setup_config.sh dev

# 2. Run in development
flutter run --dart-define-from-file=config.dev.json

# 3. Build for testing
./local_build.sh

# 4. Build for production
./local_build.sh 1 prod
```

---

**Remember**: Security is everyone's responsibility! 🔒 