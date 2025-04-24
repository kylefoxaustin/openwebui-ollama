#!/bin/bash

# Set variables - replace with your Docker Hub username
DOCKER_HUB_USERNAME="yourusername"
IMAGE_NAME="yourdockerimage"
VERSION="latest"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize failure tracking
CPU_TEST_FAILED=false
GPU_TEST_FAILED=false
FAILURE_MESSAGES=()

echo -e "${YELLOW}OpenWebUI with Ollama Docker Image Test Script${NC}"
echo "=========================================="

# Function to clean up containers
cleanup() {
    echo -e "\n${YELLOW}Cleaning up test containers...${NC}"
    docker rm -f test-openwebui-cpu test-openwebui-gpu 2>/dev/null
}

# Function to wait for service with progress indicator
wait_for_service() {
    local container_name=$1
    local port=$2
    local timeout=$3
    local interval=1
    local elapsed=0
    local dots=0
    local progress_update=5 # Update progress indicator every 5 seconds

    echo -n "Waiting for OpenWebUI to become available"

    while [ $elapsed -lt $timeout ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/ | grep -q "200"; then
            echo -e "\n${GREEN}OpenWebUI is now accessible after $elapsed seconds.${NC}"
            return 0
        fi

        sleep $interval
        elapsed=$((elapsed + interval))

        # Add a dot every progress_update seconds
        if [ $((elapsed % progress_update)) -eq 0 ]; then
            echo -n "."
            dots=$((dots + 1))

            # Add timing info every 30 seconds
            if [ $((dots % 6)) -eq 0 ]; then
                echo -n " ${elapsed}s "
            fi
        fi
    done

    echo -e "\n${RED}Timed out after ${timeout} seconds waiting for OpenWebUI.${NC}"
    return 1
}

# Initial cleanup
cleanup

# Check if Ollama is already running natively
OLLAMA_RUNNING=false
if pgrep -x "ollama" > /dev/null || nc -z localhost 11434 2>/dev/null; then
    echo -e "${YELLOW}Ollama is already running natively. Using alternative ports.${NC}"
    OLLAMA_RUNNING=true
    CPU_OLLAMA_PORT=11435
    GPU_OLLAMA_PORT=11436
else
    CPU_OLLAMA_PORT=11434
    GPU_OLLAMA_PORT=11435
fi

# Test CPU image
echo -e "\n${YELLOW}Testing CPU image: ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${VERSION}-cpu${NC}"
echo "----------------------------------------"

# Pull the CPU image
echo "Pulling CPU image..."
if ! docker pull ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${VERSION}-cpu; then
    echo -e "${RED}Failed to pull CPU image.${NC}"
    CPU_TEST_FAILED=true
    FAILURE_MESSAGES+=("CPU image pull failed")
else
    # Run the CPU container with appropriate port mapping
    echo "Starting CPU container..."
    if [ "$OLLAMA_RUNNING" = true ]; then
        docker run -d --name test-openwebui-cpu -p 8080:8080 -p ${CPU_OLLAMA_PORT}:11434 ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${VERSION}-cpu
    else
        docker run -d --name test-openwebui-cpu -p 8080:8080 -p ${CPU_OLLAMA_PORT}:11434 ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${VERSION}-cpu
    fi

    # Check if container is running
    if ! docker ps | grep -q "test-openwebui-cpu"; then
        echo -e "${RED}CPU container failed to start.${NC}"
        echo "Container logs:"
        docker logs test-openwebui-cpu
        CPU_TEST_FAILED=true
        FAILURE_MESSAGES+=("CPU container failed to start")
    else
        # Wait for OpenWebUI to become available (timeout after 120 seconds)
        if ! wait_for_service "test-openwebui-cpu" 8080 120; then
            echo -e "${RED}Failed to connect to OpenWebUI on CPU container.${NC}"
            echo "Container logs:"
            docker logs test-openwebui-cpu
            CPU_TEST_FAILED=true
            FAILURE_MESSAGES+=("OpenWebUI on CPU container did not respond within timeout")
        else
            # Test Ollama API
            echo "Testing Ollama API..."
            OLLAMA_RESPONSE=$(docker exec -it test-openwebui-cpu curl -s http://localhost:11434/api/tags)
            if [ ! -z "$OLLAMA_RESPONSE" ]; then
                echo -e "${GREEN}Ollama API is working on CPU container.${NC}"
            else
                echo -e "${RED}Failed to connect to Ollama API on CPU container.${NC}"
                docker logs test-openwebui-cpu
                docker exec -it test-openwebui-cpu cat /var/log/supervisor/ollama.err.log
                CPU_TEST_FAILED=true
                FAILURE_MESSAGES+=("Ollama API on CPU container failed")
            fi
        fi
    fi

    # Stop and remove CPU container regardless of test results
    echo "Stopping CPU test container..."
    docker stop test-openwebui-cpu > /dev/null 2>&1
    docker rm test-openwebui-cpu > /dev/null 2>&1
fi

# Test GPU image if NVIDIA GPU is available
if command -v nvidia-smi &> /dev/null; then
    echo -e "\n${YELLOW}Testing GPU image: ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${VERSION}-gpu${NC}"
    echo "----------------------------------------"

    # Pull the GPU image
    echo "Pulling GPU image..."
    if ! docker pull ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${VERSION}-gpu; then
        echo -e "${RED}Failed to pull GPU image.${NC}"
        GPU_TEST_FAILED=true
        FAILURE_MESSAGES+=("GPU image pull failed")
    else
        # Run GPU container with appropriate port mapping
        echo "Starting GPU container..."
        if [ "$OLLAMA_RUNNING" = true ]; then
            docker run -d --name test-openwebui-gpu --gpus all -p 8081:8080 -p ${GPU_OLLAMA_PORT}:11434 ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${VERSION}-gpu
        else
            docker run -d --name test-openwebui-gpu --gpus all -p 8081:8080 -p ${GPU_OLLAMA_PORT}:11434 ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${VERSION}-gpu
        fi

        # Check if container is running
        if ! docker ps | grep -q "test-openwebui-gpu"; then
            echo -e "${RED}GPU container failed to start.${NC}"
            echo "Container logs:"
            docker logs test-openwebui-gpu
            GPU_TEST_FAILED=true
            FAILURE_MESSAGES+=("GPU container failed to start")
        else
            # Wait for OpenWebUI to become available (timeout after 120 seconds)
            if ! wait_for_service "test-openwebui-gpu" 8081 120; then
                echo -e "${RED}Failed to connect to OpenWebUI on GPU container.${NC}"
                echo "Container logs:"
                docker logs test-openwebui-gpu
                GPU_TEST_FAILED=true
                FAILURE_MESSAGES+=("OpenWebUI on GPU container did not respond within timeout")
            else
                # Test Ollama API
                echo "Testing Ollama API..."
                OLLAMA_RESPONSE=$(docker exec -it test-openwebui-gpu curl -s http://localhost:11434/api/tags)
                if [ ! -z "$OLLAMA_RESPONSE" ]; then
                    echo -e "${GREEN}Ollama API is working on GPU container.${NC}"
                else
                    echo -e "${RED}Failed to connect to Ollama API on GPU container.${NC}"
                    docker logs test-openwebui-gpu
                    docker exec -it test-openwebui-gpu cat /var/log/supervisor/ollama.err.log
                    GPU_TEST_FAILED=true
                    FAILURE_MESSAGES+=("Ollama API on GPU container failed")
                fi

                # Test GPU accessibility
                echo "Testing GPU accessibility..."
                if docker exec -it test-openwebui-gpu nvidia-smi &> /dev/null; then
                    echo -e "${GREEN}GPU is accessible inside the container.${NC}"
                else
                    echo -e "${RED}GPU is not accessible inside the container.${NC}"
                    GPU_TEST_FAILED=true
                    FAILURE_MESSAGES+=("GPU not accessible inside container")
                fi
            fi
        fi

        # Stop and remove GPU container
        echo "Stopping GPU test container..."
        docker stop test-openwebui-gpu > /dev/null 2>&1
        docker rm test-openwebui-gpu > /dev/null 2>&1
    fi
else
    echo -e "\n${YELLOW}Skipping GPU tests as no NVIDIA GPU was detected.${NC}"
fi

# Final cleanup
cleanup

# Print test summary
echo -e "\n${BLUE}========== TEST SUMMARY ==========${NC}"

if [ "$CPU_TEST_FAILED" = true ] || [ "$GPU_TEST_FAILED" = true ]; then
    echo -e "${RED}Some tests failed:${NC}"
    for message in "${FAILURE_MESSAGES[@]}"; do
        echo -e "  ${RED}✘${NC} $message"
    done

    if [ "$CPU_TEST_FAILED" = true ] && [ "$GPU_TEST_FAILED" = false ] && [ "$(command -v nvidia-smi &> /dev/null && echo "yes" || echo "no")" = "yes" ]; then
        echo -e "\n${YELLOW}Note: CPU tests failed but GPU tests passed. The GPU image appears to be working correctly.${NC}"
    fi

    exit 1
else
    echo -e "${GREEN}All tests passed successfully!${NC}"
    exit 0
fi
