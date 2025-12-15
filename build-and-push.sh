#!/bin/bash

# Build and Push Docker Images to GitHub Container Registry (GHCR)
# This script builds images for services that have Dockerfiles and pushes them to GHCR.

set -e

# ========================================
# Configuration - Update these variables
# ========================================
GITHUB_USERNAME="${GITHUB_USERNAME:-jctroth}"  # Your GitHub username
GITHUB_REPO="${GITHUB_REPO:-erp-demo}"  # Your GitHub repository name
TAG="${TAG:-latest}"  # Image tag, e.g., 'latest', 'v1.0', or use git commit hash

# Services to build (from docker-compose.yml build contexts)
SERVICES=(
    "user-management"
    "inventory"
    "sales"
    "financial"
    "dashboard"
    "gateway"
    "frontend"
)

# ========================================
# Functions
# ========================================

# Login to GitHub Container Registry
docker_login() {
    echo "Logging in to GitHub Container Registry..."
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "GITHUB_TOKEN environment variable not set."
        echo "Set it with: export GITHUB_TOKEN='your-github-personal-access-token'"
        echo "Create a token at: https://github.com/settings/tokens"
        echo "Required scopes: write:packages, read:packages"
        exit 1
    fi
    echo "$GITHUB_TOKEN" | docker login ghcr.io --username "$GITHUB_USERNAME" --password-stdin
    echo "Logged in to GHCR as $GITHUB_USERNAME"
}

# Build and push a single service
build_and_push() {
    local service=$1
    local image_name="ghcr.io/$GITHUB_USERNAME/$GITHUB_REPO-$service:$TAG"
    local context="./services/$service"

    if [ ! -d "$context" ]; then
        echo "Context directory $context not found, skipping $service"
        return
    fi

    echo "Building image for $service..."
    docker build -t "$image_name" "$context"

    echo "Pushing $image_name..."
    docker push "$image_name"

    echo "$service pushed as $image_name"
}

# Main execution
main() {
    echo "========================================="
    echo "Building and Pushing ERP Images to GHCR"
    echo "Username: $GITHUB_USERNAME"
    echo "Repository: $GITHUB_REPO"
    echo "Tag: $TAG"
    echo "========================================="

    docker_login

    for service in "${SERVICES[@]}"; do
        build_and_push "$service"
    done

    echo ""
    echo "All images built and pushed!"
    echo "Update docker-compose.yml to use these images instead of build contexts."
    echo "Example:"
    echo "  services:"
    echo "    user-management:"
    echo "      image: ghcr.io/$GITHUB_USERNAME/$GITHUB_REPO-user-management:$TAG"
    echo "      # Remove 'build:' section"
}

# ========================================
# Run main
# ========================================
main "$@"