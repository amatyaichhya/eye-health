#!/bin/bash
#
# Flutter APK Builder with Secure API Configuration
# =================================================
# This script automates building different Flutter APK variants with proper versioning,
# package naming, secure API key injection, and cleanup handling. 
# Ensures a clean git state before building and provides error handling with context logging.
#
# Usage:
#   ./local_build.sh [BUILD_NUMBER] [ENVIRONMENT]
#
# Parameters:
#   BUILD_NUMBER - Optional incremental build number (default: 1)
#   ENVIRONMENT  - Optional environment (dev|prod, default: dev)
#
# Examples:
#   ./local_build.sh                    # Build with dev config
#   ./local_build.sh 5                  # Build #5 with dev config
#   ./local_build.sh 5 prod             # Build #5 with prod config

# --------------------------
# Configuration & Setup
# --------------------------

# Get script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
BUILD_NUMBER=${1:-1}
ENVIRONMENT=${2:-dev}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo "Error: Environment must be 'dev' or 'prod'"
    echo "Usage: $0 [BUILD_NUMBER] [ENVIRONMENT]"
    exit 1
fi

# Define base directory for builds
BASE_DIR=~/Desktop/eye_health_app_builds

# Get today's date in YYYY-MM-DD format
TODAY=$(date "+%Y-%m-%d")

# Base output directory for today
BASE_OUTPUT_DIR="$BASE_DIR/$TODAY"

# Start counter from BUILD_NUMBER
COUNT=$BUILD_NUMBER
OUTPUT_DIR="${BASE_OUTPUT_DIR}_${ENVIRONMENT}_$COUNT"

# Check for existing directories and increment the counter
while [[ -d "$OUTPUT_DIR" ]]; do
  ((COUNT++))
  OUTPUT_DIR="${BASE_OUTPUT_DIR}_${ENVIRONMENT}_$COUNT"
done

# Create the output directory
mkdir -p "$OUTPUT_DIR"

# Define log directory
readonly OUTPUT_DIR
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Create logs directory
mkdir -p "$LOG_DIR"

echo "Build directory created at: $OUTPUT_DIR"
echo "Environment: $ENVIRONMENT"
echo "Build number: $COUNT"

# Cleanup: Delete old folders except today's
for dir in "$BASE_DIR"/*; do
  if [[ -d "$dir" && ! "$dir" =~ "$TODAY" ]]; then
    echo "Deleting old build folder: $dir"
    rm -rf "$dir"
  fi
done

echo "Cleanup complete!"

# --------------------------
# Error Handling
# --------------------------
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local func_trace=$5

    echo -e "\n╔════════════════════════════════════════════════════════════╗"
    echo "║                      BUILD FAILED                       ║"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║ Error Details:                                          ║"
    echo "║   Line: $line_no | Command: '$last_command'"
    echo "║   Exit Code: $exit_code | Function Trace: $func_trace"
    echo "║   Environment: $ENVIRONMENT | Build: $COUNT"
    echo "╚════════════════════════════════════════════════════════════╝"

    git stash -u  # Clean working directory to preserve git state
    exit "$exit_code"
}

# --------------------------
# Dependency Checks
# --------------------------
check_requirements() {
    local required_commands=("git" "flutter" "dart")
    local missing=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing required commands:"
        printf '• %s\n' "${missing[@]}"
        exit 1
    fi
}

# --------------------------
# Configuration Validation
# --------------------------
validate_config() {
    local config_file="config.${ENVIRONMENT}.json"
    
    echo "▶ Validating configuration..."
    
    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file '$config_file' not found!"
        echo ""
        echo "Please create the config file:"
        echo "  cp config.${ENVIRONMENT}.template.json $config_file"
        echo "  # Then edit $config_file and add your real API key"
        echo ""
        echo "Available template files:"
        ls -la config.*.template.json 2>/dev/null || echo "  No template files found"
        exit 1
    fi
    
    # Check if API key is configured
    local api_key=$(grep -o '"OPENAI_API_KEY"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | cut -d'"' -f4)
    
    if [[ -z "$api_key" || "$api_key" == "your_dev_api_key_here" || "$api_key" == "your_production_api_key_here" ]]; then
        echo "Error: OpenAI API key not configured in '$config_file'!"
        echo ""
        echo "Please edit '$config_file' and replace the placeholder with your real OpenAI API key."
        echo "Get your API key from: https://platform.openai.com/api-keys"
        exit 1
    fi
    
    echo "✓ Configuration validated: $config_file"
    echo "✓ API key configured (${#api_key} characters)"
}

# --------------------------
# Git State Validation
# --------------------------
verify_git_state() {
    echo "▶ Verifying git state..."
    
    # Check for uncommitted changes (excluding config files)
    local uncommitted=$(git status --porcelain | grep -v "config\\..*\\.json$" || true)
    if [[ -n "$uncommitted" ]]; then
        echo "Error: Uncommitted changes detected (excluding config files):"
        echo "$uncommitted"
        exit 1
    fi

    # Verify remote synchronization
    local local_branch=$(git rev-parse --abbrev-ref HEAD)
    local remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)

    if [ -z "$remote_branch" ]; then
        echo "Warning: No upstream branch configured."
    else
        if ! git diff --quiet HEAD @{u}; then
            echo "Warning: Local branch not synchronized with remote."
        fi
    fi
    
    echo "✓ Git state verified"
}

# --------------------------
# Project Setup
# --------------------------
setup_project() {
    echo "▶ Preparing project environment..."
    flutter clean
    flutter pub get || {
        echo "Error: Dependency resolution failed"
        return 1
    }
    echo "✓ Project setup complete"
}

# --------------------------
# APK Building
# --------------------------
build_apk() {
    local output_name=$1
    local config_file="config.${ENVIRONMENT}.json"

    echo "▶ Building APK with secure configuration..."
    echo "  • Environment: $ENVIRONMENT"
    echo "  • Config file: $config_file"
    echo "  • Output: $output_name"

    # Execute Flutter build with secure dart-define-from-file
    echo "• Compiling APK with obfuscation..."
    
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        # Production build with full security
        flutter build apk \
            --release \
            --obfuscate \
            --split-debug-info="$OUTPUT_DIR/debug_info" \
            --dart-define-from-file="$config_file" || return 1
    else
        # Development build (faster, less secure)
        flutter build apk \
            --release \
            --dart-define-from-file="$config_file" || return 1
    fi

    # Archive build artifact
    mkdir -p "$OUTPUT_DIR"
    cp "build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/$output_name" || return 1
    echo "✓ Build artifact saved: $output_name"

    # Save build info
    cat > "$OUTPUT_DIR/build_info.txt" << EOF
Build Information
=================
Date: $(date "+%Y-%m-%d %H:%M:%S")
Environment: $ENVIRONMENT
Build Number: $COUNT
Config File: $config_file
Flutter Version: $(flutter --version | head -n1)
Dart Version: $(dart --version)
Git Commit: $(git rev-parse HEAD)
Git Branch: $(git rev-parse --abbrev-ref HEAD)
Obfuscation: $([ "$ENVIRONMENT" == "prod" ] && echo "Enabled" || echo "Disabled")
Debug Info: $([ "$ENVIRONMENT" == "prod" ] && echo "Split to debug_info/" || echo "Included")
EOF

    echo "✓ Build information saved"
}

# --------------------------
# Main Execution Flow
# --------------------------
main() {
    local current_month=$(date "+%m")
    local current_day=$(date "+%d")

    # Initialize directories
    mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

    # Configure logging
    exec > >(tee -a "${LOG_DIR}/build_${ENVIRONMENT}_${current_month}_${current_day}.log")
    exec 2>&1

    echo -e "\n════════════════════════════════════════════════════════════"
    echo "  SECURE BUILD INITIATED - $(date "+%Y-%m-%d %H:%M:%S") "
    echo "  Environment: $ENVIRONMENT | Build: $COUNT"
    echo "════════════════════════════════════════════════════════════"

    # Pre-flight checks
    check_requirements
    validate_config
    verify_git_state
    setup_project

    # Build APK
    build_apk "eye_health_app_${ENVIRONMENT}_v${current_month}.${current_day}.${COUNT}.apk"

    echo -e "\n════════════════════════════════════════════════════════════"
    echo "  BUILD SUCCESS - Output Directory: $OUTPUT_DIR "
    echo "  Environment: $ENVIRONMENT | Build: $COUNT"
    echo "  APK Location: $OUTPUT_DIR/eye_health_app_${ENVIRONMENT}_v${current_month}.${current_day}.${COUNT}.apk"
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        echo "  Debug Info: $OUTPUT_DIR/debug_info/"
    fi
    echo "════════════════════════════════════════════════════════════"
}

# --------------------------
# Script Entry Point
# --------------------------
main "$@"