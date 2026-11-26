#!/bin/bash
#
# Eye Health App - Configuration Setup
# ====================================
# This script helps you set up the configuration files for the Eye Health app.
# It creates the necessary config files from templates and guides you through
# adding your OpenAI API key.
#
# Usage:
#   ./setup_config.sh [ENVIRONMENT]
#
# Parameters:
#   ENVIRONMENT - Optional environment (dev|prod|both, default: dev)

# Parse command line arguments
ENVIRONMENT=${1:-dev}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod|both)$ ]]; then
    echo "Error: Environment must be 'dev', 'prod', or 'both'"
    echo "Usage: $0 [ENVIRONMENT]"
    exit 1
fi

echo "🔐 Eye Health App - Configuration Setup"
echo "========================================"
echo ""

# Function to setup a specific environment
setup_environment() {
    local env=$1
    local template_file="config.${env}.template.json"
    local config_file="config.${env}.json"
    
    echo "Setting up $env environment..."
    
    # Check if template exists
    if [[ ! -f "$template_file" ]]; then
        echo "❌ Error: Template file '$template_file' not found!"
        return 1
    fi
    
    # Check if config already exists
    if [[ -f "$config_file" ]]; then
        echo "⚠️  Config file '$config_file' already exists."
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipping $env environment."
            return 0
        fi
    fi
    
    # Copy template to config
    cp "$template_file" "$config_file"
    echo "✅ Created $config_file from template"
    
    # Prompt for API key
    echo ""
    echo "📝 Please enter your OpenAI API key for $env environment:"
    echo "   (Get your API key from: https://platform.openai.com/api-keys)"
    echo ""
    read -p "OpenAI API Key: " -r api_key
    
    if [[ -z "$api_key" ]]; then
        echo "⚠️  No API key provided. You'll need to edit $config_file manually."
        return 0
    fi
    
    # Update the config file with the API key
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/your_${env}_api_key_here/$api_key/g" "$config_file"
        sed -i '' "s/your_production_api_key_here/$api_key/g" "$config_file"
    else
        # Linux
        sed -i "s/your_${env}_api_key_here/$api_key/g" "$config_file"
        sed -i "s/your_production_api_key_here/$api_key/g" "$config_file"
    fi
    
    echo "✅ API key configured in $config_file"
    echo ""
}

# Setup based on environment choice
if [[ "$ENVIRONMENT" == "both" ]]; then
    setup_environment "dev"
    setup_environment "prod"
elif [[ "$ENVIRONMENT" == "dev" ]]; then
    setup_environment "dev"
elif [[ "$ENVIRONMENT" == "prod" ]]; then
    setup_environment "prod"
fi

echo "🎉 Configuration setup complete!"
echo ""
echo "Next steps:"
echo "1. Verify your config files have the correct API keys"
echo "2. Run the app in development:"
echo "   flutter run --dart-define-from-file=config.dev.json"
echo ""
echo "3. Or build a release APK:"
echo "   ./local_build.sh 1 dev     # Development build"
echo "   ./local_build.sh 1 prod    # Production build" 