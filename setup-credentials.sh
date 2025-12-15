#!/bin/bash

# Interactive script to set up GitHub Container Registry credentials
# This script will:
# 1. Ask for required parameters
# 2. Explain where to get them
# 3. Set them in the current terminal session
# 4. Generate a set_credentials.sh script for future use

set -e

echo "========================================="
echo "GitHub Container Registry Setup"
echo "========================================="
echo ""

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local response

    read -p "$prompt [$default]: " response
    echo "${response:-$default}"
}

# Function to prompt for password (hidden input)
prompt_password() {
    local prompt="$1"
    local password

    read -s -p "$prompt: " password
    echo ""
    echo "$password"
}

echo "Required Parameters:"
echo ""

# GitHub Username
echo "1. GitHub Username"
echo "   Where to find: Your GitHub profile URL (github.com/YOUR_USERNAME)"
echo "   Example: If your GitHub URL is github.com/johnsmith, enter 'johnsmith'"
echo "   Note: Will be converted to lowercase for Docker compatibility"
GITHUB_USERNAME=$(prompt_with_default "Enter your GitHub username" "jctroth")
GITHUB_USERNAME=$(echo "$GITHUB_USERNAME" | tr '[:upper:]' '[:lower:]')
echo "   Using lowercase username: $GITHUB_USERNAME"
echo ""

# GitHub Repository
echo "2. GitHub Repository Name"
echo "   Where to find: Your repository URL (github.com/username/REPO_NAME)"
echo "   Example: If your repo URL is github.com/jctroth/erp-demo, enter 'erp-demo'"
GITHUB_REPO=$(prompt_with_default "Enter your GitHub repository name" "erp-demo")
echo ""

# GitHub Personal Access Token
echo "3. GitHub Personal Access Token (PAT)"
echo "   Where to create: https://github.com/settings/tokens"
echo "   Required scopes:"
echo "      - write:packages (to push images)"
echo "      - read:packages (to pull images)"
echo "      - delete:packages (optional, to delete images)"
echo "   IMPORTANT: Keep this token secure and never commit it to git!"
echo ""
echo "   Steps to create:"
echo "   1. Go to https://github.com/settings/tokens"
echo "   2. Click 'Generate new token (classic)'"
echo "   3. Give it a name like 'ERP Demo GHCR'"
echo "   4. Select the scopes listed above"
echo "   5. Click 'Generate token'"
echo "   6. Copy the token immediately (you won't see it again!)"
echo ""

GITHUB_TOKEN=$(prompt_password "Enter your GitHub Personal Access Token")
echo ""

# Optional: Docker Hub credentials (for fallback)
echo "4. Docker Hub Credentials (Optional - for fallback)"
echo "   Where to find: https://hub.docker.com/ (if you have a Docker Hub account)"
echo "   Leave empty if you don't want to set Docker Hub credentials"
DOCKER_USERNAME=$(prompt_with_default "Enter your Docker Hub username (optional)" "")
if [ -n "$DOCKER_USERNAME" ]; then
    DOCKER_PASSWORD=$(prompt_password "Enter your Docker Hub password/token")
    echo ""
fi

# Set environment variables in current session
echo "Setting environment variables for current session..."
export GITHUB_USERNAME="$GITHUB_USERNAME"
export GITHUB_REPO="$GITHUB_REPO"
export GITHUB_TOKEN="$GITHUB_TOKEN"

if [ -n "$DOCKER_USERNAME" ]; then
    export DOCKER_USERNAME="$DOCKER_USERNAME"
    export DOCKER_PASSWORD="$DOCKER_PASSWORD"
fi

echo "Environment variables set!"
echo ""

# Generate set_credentials.sh script
echo "Generating set_credentials.sh script..."

cat > set_credentials.sh << EOF
#!/bin/bash

# Generated credentials script for GitHub Container Registry
# This file contains your credentials - KEEP IT SECURE!
# Generated on: $(date)

# GitHub Container Registry credentials
export GITHUB_USERNAME="$GITHUB_USERNAME"
export GITHUB_REPO="$GITHUB_REPO"
export GITHUB_TOKEN="$GITHUB_TOKEN"

EOF

if [ -n "$DOCKER_USERNAME" ]; then
    cat >> set_credentials.sh << EOF
# Docker Hub credentials (optional)
export DOCKER_USERNAME="$DOCKER_USERNAME"
export DOCKER_PASSWORD="$DOCKER_PASSWORD"

EOF
fi

cat >> set_credentials.sh << EOF
echo "Credentials loaded for GitHub Container Registry"
echo "Username: \$GITHUB_USERNAME"
echo "Repository: \$GITHUB_REPO"
echo "Token: [HIDDEN]"
EOF

chmod +x set_credentials.sh

echo "set_credentials.sh generated!"
echo ""

# Test the credentials
echo "Testing GitHub Container Registry authentication..."
if echo "$GITHUB_TOKEN" | docker login ghcr.io --username "$GITHUB_USERNAME" --password-stdin 2>/dev/null; then
    echo "Authentication successful!"
else
    echo "Authentication failed. Please check your token and try again."
    exit 1
fi

echo ""
echo "Setup complete! You can now run:"
echo "   ./build-and-push.sh"
echo ""
echo "To load credentials in future sessions:"
echo "   source ./set_credentials.sh"
echo ""
echo "Remember to keep set_credentials.sh secure and never commit it to git!"