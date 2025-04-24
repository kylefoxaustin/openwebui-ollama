#!/bin/bash

# Set variables - replace 'yourusername' with your Docker Hub username
DOCKER_HUB_USERNAME="kylefoxaustin"
IMAGE_NAME="openwebui-ollama"
VERSION="latest"

# Tag CPU image
echo "Tagging CPU image..."
docker tag openwebui:cpu $DOCKER_HUB_USERNAME/$IMAGE_NAME:$VERSION
docker tag openwebui:cpu $DOCKER_HUB_USERNAME/$IMAGE_NAME:${VERSION}-cpu

# Tag GPU image
echo "Tagging GPU image..."
docker tag openwebui:gpu $DOCKER_HUB_USERNAME/$IMAGE_NAME:${VERSION}-gpu

# Login to Docker Hub
echo "Logging in to Docker Hub..."
docker login

# Push CPU images
echo "Pushing CPU images..."
docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:$VERSION
docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:${VERSION}-cpu

# Push GPU image
echo "Pushing GPU image..."
docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:${VERSION}-gpu

echo "All images pushed successfully!"
