#!/bin/bash

# Set variables - replace with your Docker Hub username
DOCKER_HUB_USERNAME="kylefoxaustin"
IMAGE_NAME="openwebui-ollama"
VERSION="latest"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
  echo -e "${BLUE}Intel/AMD (x86_64) architecture detected${NC}"
  echo -e "${YELLOW}Skipping ARM64 image processing - not available on this platform${NC}"
  CPU_IMAGE="openwebui:cpu"
  GPU_IMAGE="openwebui:gpu"
  TAG_PREFIX=""
elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then
  echo -e "${BLUE}ARM64 architecture detected${NC}"
  echo -e "${YELLOW}Skipping Intel/AMD image processing - not available on this platform${NC}"
  CPU_IMAGE="openwebui:arm64-cpu"
  GPU_IMAGE="openwebui:arm64-gpu"
  TAG_PREFIX="arm64-"
else
  echo -e "${RED}Unsupported architecture: $ARCH${NC}"
  exit 1
fi

# Check if images exist for this architecture
echo -e "\n${BLUE}Checking for local images...${NC}"
if ! docker image inspect $CPU_IMAGE &>/dev/null; then
  echo -e "${RED}Error: $CPU_IMAGE image not found. Build it first using the appropriate Dockerfile for this architecture.${NC}"
  exit 1
fi

# Check for GPU image
if ! docker image inspect $GPU_IMAGE &>/dev/null; then
  echo -e "${YELLOW}Warning: $GPU_IMAGE image not found. Skipping GPU image tags.${NC}"
  SKIP_GPU=true
else
  SKIP_GPU=false
fi

echo -e "\n${BLUE}Tagging images for Docker Hub...${NC}"

# Tag CPU image
echo -e "Tagging CPU image: ${YELLOW}$CPU_IMAGE → $DOCKER_HUB_USERNAME/$IMAGE_NAME:${TAG_PREFIX}cpu${NC}"
docker tag $CPU_IMAGE $DOCKER_HUB_USERNAME/$IMAGE_NAME:${TAG_PREFIX}cpu

# Tag GPU image if available
if [ "$SKIP_GPU" = false ]; then
  echo -e "Tagging GPU image: ${YELLOW}$GPU_IMAGE → $DOCKER_HUB_USERNAME/$IMAGE_NAME:${TAG_PREFIX}gpu${NC}"
  docker tag $GPU_IMAGE $DOCKER_HUB_USERNAME/$IMAGE_NAME:${TAG_PREFIX}gpu
fi

# For x86_64 architecture, also set the default "latest" tag
if [ "$ARCH" == "x86_64" ]; then
  echo -e "Setting default tag: ${YELLOW}$CPU_IMAGE → $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest${NC}"
  docker tag $CPU_IMAGE $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest
fi

# Login to Docker Hub
echo -e "\n${BLUE}Logging in to Docker Hub...${NC}"
docker login

echo -e "\n${BLUE}Pushing images to Docker Hub...${NC}"

# Push CPU image
echo -e "Pushing: ${YELLOW}$DOCKER_HUB_USERNAME/$IMAGE_NAME:${TAG_PREFIX}cpu${NC}"
docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:${TAG_PREFIX}cpu

# Push GPU image if available
if [ "$SKIP_GPU" = false ]; then
  echo -e "Pushing: ${YELLOW}$DOCKER_HUB_USERNAME/$IMAGE_NAME:${TAG_PREFIX}gpu${NC}"
  docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:${TAG_PREFIX}gpu
fi

# Push latest tag for x86_64
if [ "$ARCH" == "x86_64" ]; then
  echo -e "Pushing: ${YELLOW}$DOCKER_HUB_USERNAME/$IMAGE_NAME:latest${NC}"
  docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest
fi

echo -e "\n${GREEN}All available images for $ARCH architecture pushed successfully!${NC}"
