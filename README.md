# OpenWebUI with Ollama in a single container 
# Creating Docker Images 

Welcome to the OpenWebUI-Ollama single container repository!

This will enable you to build Docker images combining [OpenWebUI](https://github.com/open-webui/open-webui) with [Ollama](https://github.com/ollama/ollama) in a single container for a seamless AI development experience.

I created this container so that I can use OpenWebUI to quickly create a new LLM model with Knowledge bases (RAG) attached via OWUI's simple browser interface.

It also allows me to push that container into a new image such as "Kyle's Home A/C Equipment Expert:Tinyllama and push to my docker.hub. 

In effect, give me the ability to easily create my own RAG models (using whatever LLM i want to) which are 'experts' on topics I am interested in.

But I am able to do this 100% locally to whatever machine I pull the image into, no server's or communication needed with outside entities. 

## Repository Structure

```
openwebui-ollama/
├── Dockerfiles/
│   ├── Dockerfile.cpu        # Dockerfile for CPU-only container
│   └── Dockerfile.gpu        # Dockerfile for GPU-enabled container
├── tools/
│   ├── tag_push.sh           # Script for tagging and pushing images
│   └── test_script_cpu_gpu_containers.sh  # Test script for validating containers
└── README.md                 # This documentation
```



## Table of Contents
- [Repository Structure](#repository-structure)
- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Building the Docker Images](#building-the-docker-images)
- [Running the Containers](#running-the-containers)
- [Usage Scenarios](#usage-scenarios)
- [Environment Variables](#environment-variables)
- [Data Persistence](#data-persistence)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Security Considerations](#security-considerations)
- [Updating](#updating)
- [Performance Tuning](#performance-tuning)
- [Testing](#testing)
- [License](#license)

## Overview

These Docker images provide a combined deployment of OpenWebUI and Ollama in a single container, managed by supervisord. This approach offers several advantages over the traditional multi-container setup:

- **Simplified deployment** - Only one container to manage
- **Reduced configuration complexity** - No need to configure network communication between containers
- **Shared resources** - More efficient resource utilization
- **Consistent state** - Both applications start and stop together

The images are available in both CPU and GPU variants to suit different hardware configurations. The GPU version will automatically fall back to CPU operation if no compatible NVIDIA GPU is detected, making it versatile for different environments.

## System Requirements

### CPU Version
- **Architecture**: x86_64 only (Intel or AMD CPUs, not ARM64/Apple Silicon)
- **Minimum**: 4 CPU cores, 8GB RAM
- **Recommended**: 8+ CPU cores, 16GB+ RAM
- At least 10GB free disk space (more needed for models)

### GPU Version
- **Architecture**: x86_64 only (Intel or AMD CPUs, not ARM64/Apple Silicon)
- **Minimum**: NVIDIA GPU with 4GB VRAM, CUDA 11.7+
- **Recommended**: NVIDIA GPU with 8GB+ VRAM
- NVIDIA drivers 525.60.13 or later
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) installed
- At least 10GB free disk space (more needed for models)

## Building the Docker Images

This repository contains Dockerfiles to build both CPU and GPU versions of the combined OpenWebUI and Ollama container.

### Clone the repository

```bash
# Clone the repository
git clone https://github.com/kylefoxaustin/openwebui-ollama.git
cd openwebui-ollama
```

### Building the CPU Image

```bash
# Build the CPU image
docker build -f Dockerfiles/Dockerfile.cpu -t openwebui:cpu .
```

### Building the GPU Image

```bash
# Build the GPU image (requires NVIDIA Container Toolkit)
docker build -f Dockerfiles/Dockerfile.gpu -t openwebui:gpu .
```

Note: The GPU image will automatically fall back to CPU operation if no compatible NVIDIA GPU is detected or if the proper NVIDIA drivers and container toolkit are not installed. This makes it safe to use the GPU image even if you're unsure about your GPU configuration.

## Running the Containers

After building the images, you can run them as follows:

### CPU Version

```bash
docker run -d \
  --name openwebui \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  openwebui:cpu
```

### GPU Version

```bash
docker run -d \
  --name openwebui-gpu \
  --gpus all \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  openwebui:gpu
```

Note: If you run the GPU version without the `--gpus all` flag or on a system without a compatible NVIDIA GPU, the container will automatically operate in CPU-only mode. This makes the GPU image versatile for deployment across different environments.

Access the web interface at: http://localhost:8080

## Usage Scenarios

### Coexisting with Local Ollama Installation

If you already have Ollama running on your host machine, you'll need to map the container's Ollama port to a different host port:

```bash
docker run -d \
  --name openwebui \
  -p 8080:8080 \
  -p 11435:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  kylefoxaustin/openwebui-ollama:latest
```

### Running CPU and GPU Containers Simultaneously

To run both CPU and GPU containers at the same time, use different port mappings:

```bash
# CPU Container
docker run -d \
  --name openwebui-cpu \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-cpu-data:/root/.ollama \
  -v openwebui-cpu-data:/app/backend/data \
  kylefoxaustin/openwebui-ollama:latest-cpu

# GPU Container
docker run -d \
  --name openwebui-gpu \
  --gpus all \
  -p 8081:8080 \
  -p 11435:11434 \
  -v ollama-gpu-data:/root/.ollama \
  -v openwebui-gpu-data:/app/backend/data \
  kylefoxaustin/openwebui-ollama:latest-gpu
```

Access the interfaces at:
- CPU version: http://localhost:8080
- GPU version: http://localhost:8081

### Using with External Ollama

To use your OpenWebUI image with an external Ollama instance (e.g., running on another server or container):

```bash
docker run -d \
  --name openwebui-only \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://<ollama-host>:11434 \
  -v openwebui-data:/app/backend/data \
  openwebui:cpu
```

Replace `<ollama-host>` with the hostname or IP address of your Ollama server.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OLLAMA_HOST` | Host for Ollama to listen on | `0.0.0.0` |
| `PORT` | Port for OpenWebUI to listen on | `8080` |
| `HOST` | Host for OpenWebUI to listen on | `0.0.0.0` |
| `OLLAMA_BASE_URL` | URL for OpenWebUI to connect to Ollama | `http://localhost:11434` |
| `NVIDIA_VISIBLE_DEVICES` | (GPU only) Controls which GPUs are visible | `all` |
| `NVIDIA_DRIVER_CAPABILITIES` | (GPU only) Required NVIDIA capabilities | `compute,utility` |

## Data Persistence

The following volumes are used for data persistence:

- `/root/.ollama`: Ollama models and configuration
- `/app/backend/data`: OpenWebUI data (conversations, settings, etc.)

For data backup, you can simply create archives of these volumes:

```bash
# Create a backup directory
mkdir -p ~/openwebui-backups

# Backup Ollama data
docker run --rm -v ollama-data:/data -v ~/openwebui-backups:/backup \
  ubuntu tar czf /backup/ollama-data-$(date +%Y%m%d).tar.gz -C /data .

# Backup OpenWebUI data
docker run --rm -v openwebui-data:/data -v ~/openwebui-backups:/backup \
  ubuntu tar czf /backup/openwebui-data-$(date +%Y%m%d).tar.gz -C /data .
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**: If you see "address already in use" errors, you likely have another service using the same port. Use alternative ports as shown in the usage scenarios.

2. **GPU not detected**: Ensure your NVIDIA drivers are properly installed and the NVIDIA Container Toolkit is set up correctly. Test with:
   ```bash
   docker run --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
   ```

3. **Container crashes**: Check logs with:
   ```bash
   docker logs openwebui
   ```

   For more detailed logs:
   ```bash
   # Ollama logs
   docker exec -it openwebui cat /var/log/supervisor/ollama.err.log
   docker exec -it openwebui cat /var/log/supervisor/ollama.out.log

   # OpenWebUI logs
   docker exec -it openwebui cat /var/log/supervisor/openwebui.err.log
   docker exec -it openwebui cat /var/log/supervisor/openwebui.out.log

   # Supervisor logs
   docker exec -it openwebui cat /var/log/supervisor/supervisord.log
   ```

4. **Models not loading**: The first time you pull a model might take some time. Check the Ollama logs:
   ```bash
   docker exec -it openwebui cat /var/log/supervisor/ollama.err.log
   ```

   You can directly pull models with:
   ```bash
   docker exec -it openwebui ollama pull <model-name>
   ```

5. **Web UI not accessible**: Make sure that the internal Ollama instance is properly running:
   ```bash
   docker exec -it openwebui curl -s http://localhost:11434/api/tags
   ```

   Check if the OpenWebUI process is running:
   ```bash
   docker exec -it openwebui supervisorctl status
   ```

6. **Out of memory errors**: Larger models require substantial RAM and VRAM. Try a smaller model or increase your container's memory limit:
   ```bash
   docker update --memory 16G --memory-swap 32G openwebui
   ```

7. **Slow model performance**: For GPU containers, make sure CUDA is properly detected:
   ```bash
   docker exec -it openwebui-gpu nvidia-smi
   ```

## Advanced Configuration

### Docker Compose

After building your images, you can use Docker Compose for more complex setups. Here's an example configuration:

```yaml
version: '3.8'

services:
  openwebui:
    image: openwebui:gpu  # Use the image you built
    container_name: openwebui
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
      - openwebui-data:/app/backend/data
    environment:
      - OLLAMA_HOST=0.0.0.0
      - PORT=8080
      - HOST=0.0.0.0
      - OLLAMA_BASE_URL=http://localhost:11434
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

volumes:
  ollama-data:
  openwebui-data:
```

Save this to `docker-compose.yml` and run with:
```bash
docker-compose up -d
```

### Resource Limits

To control CPU and memory usage when running your container:

```bash
docker run -d \
  --name openwebui \
  --cpus 4 \
  --memory 8G \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  openwebui:cpu
```

### Custom Network Configuration

To place your container on a specific network:

```bash
# Create a custom network
docker network create ai-network

# Run the container on that network
docker run -d \
  --name openwebui \
  --network ai-network \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  openwebui:cpu
```

## Security Considerations

These containers are designed for development and testing purposes. If deploying in a production environment, consider the following security measures:

1. **Do not expose the container to the public internet** without proper authentication and TLS encryption.

2. **Use a reverse proxy** like Nginx or Traefik with proper SSL/TLS termination.

3. **Run containers with limited privileges**:
   ```bash
   docker run -d \
     --name openwebui \
     --security-opt=no-new-privileges \
     --cap-drop=ALL \
     -p 8080:8080 \
     -p 11434:11434 \
     -v ollama-data:/root/.ollama \
     -v openwebui-data:/app/backend/data \
     openwebui:cpu
   ```

4. **Consider network isolation** using Docker networks to limit container communication.

5. **Regularly update** the images to get the latest security patches.



## Updating

To update to the latest version:

```bash
# Pull the latest repository changes
git pull

# Rebuild the images
docker build -f Dockerfiles/Dockerfile.cpu -t openwebui:cpu .
docker build -f Dockerfiles/Dockerfile.gpu -t openwebui:gpu .

# Restart your containers
docker stop openwebui
docker rm openwebui
docker run -d \
  --name openwebui \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  openwebui:cpu
```

## Performance Tuning

### CPU Performance

For better CPU performance:

1. **Allocate more CPU cores**:
   ```bash
   docker run -d --cpus 8 ... openwebui:cpu
   ```

2. **Enable CPU optimization**:
   ```bash
   docker run -d --cpuset-cpus="0-7" ... openwebui:cpu
   ```

### GPU Performance

For better GPU performance:

1. **Select specific GPUs** if you have multiple:
   ```bash
   docker run -d --gpus '"device=0,1"' ... openwebui:gpu
   ```

2. **Increase shared memory**:
   ```bash
   docker run -d --shm-size=8g ... openwebui:gpu
   ```

3. **Optimize for specific CUDA capabilities**:
   ```bash
   docker run -d \
     -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
     ... openwebui:gpu
   ```

## Testing

### Using the Tag and Push Script

After building your images, you can tag and push them to Docker Hub:

1. Update the username in the script:
   ```bash
   cd tools
   nano tag_push.sh
   # Change DOCKER_HUB_USERNAME to your Docker Hub username
   ```

2. Run the script:
   ```bash
   chmod +x tag_push.sh
   ./tag_push.sh
   ```

### Using the Test Script

To verify that your built images are working correctly:

```bash
cd tools
chmod +x test_script_cpu_gpu_containers.sh
./test_script_cpu_gpu_containers.sh
```

The test script will:
1. Test if both CPU and GPU images can be used
2. Verify that the containers start properly
3. Test that OpenWebUI is accessible
4. Confirm that the Ollama API is working
5. For GPU containers, verify GPU accessibility
6. Provide a detailed test summary

## License

These Docker images combine OpenWebUI and Ollama, each with their respective licenses. See the original projects for more information.

- OpenWebUI: [MIT License](https://github.com/open-webui/open-webui/blob/main/LICENSE)
- Ollama: [MIT License](https://github.com/ollama/ollama/blob/main/LICENSE)

---

Maintained by [kylefoxaustin](https://github.com/kylefoxaustin/openwebui-ollama)

Last updated: April 2025
