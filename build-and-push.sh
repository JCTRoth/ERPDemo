#!/bin/bash

# Build and Push Docker Images to Docker Hub
# This script builds images for services that have Dockerfiles and pushes them to Docker Hub.

set -e

# ========================================
# Configuration - Update these variables
# ========================================
DOCKER_USERNAME="${DOCKER_USERNAME:-your-dockerhub-username}"  # Replace with your Docker Hub username
DOCKER_REPO_PREFIX="${DOCKER_REPO_PREFIX:-erp}"  # Prefix for repo names, e.g., 'erp' -> username/erp-user-management
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

# Login to Docker Hub
docker_login() {
    echo "Logging in to Docker Hub..."
    if [ -z "$DOCKER_PASSWORD" ]; then
        echo "DOCKER_PASSWORD environment variable not set."
        echo "Set it with: export DOCKER_PASSWORD='your-password'"
        exit 1
    fi
    echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
    echo "Logged in to Docker Hub as $DOCKER_USERNAME"
}

# Build and push a single service
build_and_push() {
    local service=$1
    local image_name="$DOCKER_USERNAME/$DOCKER_REPO_PREFIX-$service:$TAG"
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
    echo "Building and Pushing ERP Images to Docker Hub"
    echo "Username: $DOCKER_USERNAME"
    echo "Prefix: $DOCKER_REPO_PREFIX"
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
    echo "      image: $DOCKER_USERNAME/$DOCKER_REPO_PREFIX-user-management:$TAG"
    echo "      # Remove 'build:' section"
}

# ========================================
# Run main
# ========================================
main "$@"