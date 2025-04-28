# OpenWebUI with Ollama in a single container 
# Creating Docker Images 

Welcome to the OpenWebUI-Ollama single container repository!

This will enable you to build Docker images combining [OpenWebUI](https://github.com/open-webui/open-webui) with [Ollama](https://github.com/ollama/ollama) in a single container for a seamless AI development experience.

I created this container for my own personal use. I wanted a super easy way to build a RAG model using an LLM. Reason is so I can create and run locally my own 'expert' system on whatever I wanted (e.g. "AC_Equip_expert"). 

You can already achieve this using separate OWUI and ollama containers, but that is a hassle. I wanted a single container to use and build from. The ease of use comes from using OWUI to pull an ollama model, then add .pdfs to a knowledge base (Rag), attach that KB to the ollama LLM model.

Viola, instant expert system! 

I have already built the containers and placed in my docker.hub repository here: ([https://hub.docker.com/r/kylefoxaustin/openwebui-ollama](https://hub.docker.com/r/kylefoxaustin/openwebui-ollama))
so that you do not have to build them yourself. Just pull the container and run it. 

These containers are designed to internally store the LLM you pull into it as well as the RAG data you add to a Knowledge Base. That way, once it is exactly how you want it, you can use docker to push the container as a new image to your docker.hub site. e.g. "my_expert:latest". 

This container will run 100% locally on the machine it is run on. The only internet traffic would be when you pull a new model from ollama.  

Finally, I made sure this container will run on an Intel/AMD CPU or ARM64 CPU by default (CPU-Only container). However I built the GPU container to use an NVIDIA GPU which is installed on the system. Note that if the GPU 'fails' to be seen, the GPU container will default to use the main cores.

Lastly I chose not to build a multi-architecture Dockerfile for the build.   The Dockerfile.cpu (gpu) are Intel/AMD and the Dockerfile.cpu(gpu)-ARM64 files are DIFFERENT.  You cannot take the Intel/AMD dockerfiles and build them on an ARM platform.  You must use the -ARM64 files.

Have fun!

## Repository Structure

```
openwebui-ollama/
├── Dockerfiles/
│   ├── Dockerfile.cpu           # Dockerfile for CPU-only container
│   ├── Dockerfile.gpu           # Dockerfile for GPU-enabled container
│   ├── Dockerfile_ARM64.cpu     # Dockerfile for ARM64 CPU-only container
│   └── Dockerfile_ARM64.gpu     # Dockerfile for ARM64 GPU-enabled container
├── tools/
│   ├── tag_push.sh              # Script for tagging and pushing images
│   └── test_script_cpu_gpu_containers.sh  # Test script for validating containers
└── README.md                    # This documentation
```

## Table of Contents
- [Repository Structure](#repository-structure)
- [Overview](#overview)
- [System Requirements](#system-requirements)
  - [Intel/AMD (x86_64) Requirements](#intelamd-x86_64-requirements)
  - [ARM64 Requirements](#arm64-requirements)
- [Building and Running](#building-and-running)
  - [Intel/AMD Builds](#intelamd-builds)
  - [ARM64 Builds](#arm64-builds)
- [Usage Scenarios](#usage-scenarios)
- [Environment Variables](#environment-variables)
- [Data Persistence](#data-persistence)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
  - [ARM64-Specific Issues](#arm64-specific-issues)
- [Advanced Configuration](#advanced-configuration)
- [Security Considerations](#security-considerations)
- [Updating](#updating)
- [Performance Tuning](#performance-tuning)
  - [Intel/AMD Performance](#intelamd-performance)
  - [ARM64 Performance](#arm64-performance)
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

### Intel/AMD (x86_64) Requirements

#### CPU Version
- **Architecture**: x86_64 only (Intel or AMD CPUs)
- **Minimum**: 4 CPU cores, 8GB RAM
- **Recommended**: 8+ CPU cores, 16GB+ RAM
- At least 10GB free disk space (more needed for models)

#### GPU Version
- **Architecture**: x86_64 only (Intel or AMD CPUs)
- **Minimum**: NVIDIA GPU with 4GB VRAM, CUDA 11.7+
- **Recommended**: NVIDIA GPU with 8GB+ VRAM
- NVIDIA drivers 525.60.13 or later
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) installed
- At least 10GB free disk space (more needed for models)

### ARM64 Requirements

- **Architecture**: ARM64-based device (NVIDIA Jetson, Raspberry Pi 4/5 with 64-bit OS)
- **CPU Version**:
  - 8GB+ RAM recommended
  - At least 10GB free disk space

- **GPU Version** (NVIDIA Jetson only):
  - NVIDIA Jetson device (Nano, Xavier, Orin)
  - JetPack 5.1.2 or later (JetPack 6.0 recommended for Orin)
  - At least 8GB RAM (16GB+ recommended for larger models)
  - At least 10GB free disk space

> **Note:** The ARM64 GPU containers have been successfully tested on an NVIDIA Jetson Orin AGX platform with 64GB RAM and a 1TB SSD.

## Building and Running

Begin by cloning the repository:

```bash
# Clone the repository
git clone https://github.com/kylefoxaustin/openwebui-ollama.git
cd openwebui-ollama
```

### Intel/AMD Builds

#### Building Intel/AMD Images

```bash
# Build the CPU image
docker build -f Dockerfiles/Dockerfile.cpu -t openwebui:cpu .

# Build the GPU image (requires NVIDIA Container Toolkit)
docker build -f Dockerfiles/Dockerfile.gpu -t openwebui:gpu .
```

Note: The GPU image will automatically fall back to CPU operation if no compatible NVIDIA GPU is detected or if the proper NVIDIA drivers and container toolkit are not installed.

#### Running Intel/AMD Containers

##### CPU Version

```bash
docker run -d \
  --name openwebui \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  openwebui:cpu
```

##### GPU Version

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

### ARM64 Builds

#### Building ARM64 Images

```bash
# Build the ARM64 CPU image
docker build -f Dockerfiles/Dockerfile_ARM64.cpu -t openwebui:arm64-cpu .

# Build the ARM64 GPU image (Jetson only)
docker build -f Dockerfiles/Dockerfile_ARM64.gpu -t openwebui:arm64-gpu .
```

#### Running ARM64 Containers

##### CPU Version

```bash
docker run -d \
  --name openwebui-arm \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  kylefoxaustin/openwebui-ollama:arm64-cpu
```

##### GPU Version (Jetson only)

```bash
docker run -d \
  --name openwebui-arm-gpu \
  --runtime nvidia \
  -p 8080:8080 \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  -v openwebui-data:/app/backend/data \
  -v /usr/local/cuda:/usr/local/cuda \
  -e OLLAMA_HOST=0.0.0.0 \
  -e OLLAMA_NUM_PARALLEL=1 \
  -e OLLAMA_GPU_LAYERS=20 \
  -e OLLAMA_MAX_QUEUE=1 \
  kylefoxaustin/openwebui-ollama:arm64-gpu
```

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
| `OLLAMA_GPU_LAYERS` | Number of model layers to offload to GPU | `0` (CPU) or full model (GPU) |
| `OLLAMA_NUM_PARALLEL` | Concurrent request processing | `1` |
| `OLLAMA_MAX_QUEUE` | Maximum queued requests | `5` |
| `OLLAMA_LOAD_TIMEOUT` | Model loading timeout | `5m` |

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

### ARM64-Specific Issues

#### ARM64 CPU Version

1. **Package Installation Failures**: Some Python packages may not have ARM64 wheels available. If you encounter build errors, try modifying the requirements or building packages from source.

2. **Performance Issues**: ARM CPUs are typically less powerful than x86_64 CPUs. Consider using smaller models optimized for less powerful hardware.

#### Jetson GPU Troubleshooting

1. **GPU Not Detected**: Ensure your Jetson device has the proper NVIDIA drivers installed and that you're using the `--runtime nvidia` flag when running the container.

2. **Internal Server Errors (HTTP 500)**: This often indicates that the model is overwhelming the GPU. Solutions include:

   - **Reduce GPU layers**: Lower the `OLLAMA_GPU_LAYERS` value to offload fewer layers to the GPU
   - **Mount CUDA libraries**: Ensure `-v /usr/local/cuda:/usr/local/cuda` is present
   - **Limit parallelism**: Use `-e OLLAMA_NUM_PARALLEL=1`
   - **Control queue depth**: Add `-e OLLAMA_MAX_QUEUE=1`

3. **Slow Model Loading or Timeouts**: Jetson devices have limited GPU memory and bandwidth:
   
   - Use smaller quantized models (e.g., Llama3-8B-Q4, TinyLlama)
   - Increase timeouts with `-e OLLAMA_LOAD_TIMEOUT=10m`
   - For Nano, consider sticking with CPU-only mode for larger models

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

### Intel/AMD Performance

#### CPU Performance

For better CPU performance:

1. **Allocate more CPU cores**:
   ```bash
   docker run -d --cpus 8 ... openwebui:cpu
   ```

2. **Enable CPU optimization**:
   ```bash
   docker run -d --cpuset-cpus="0-7" ... openwebui:cpu
   ```

#### GPU Performance

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

### ARM64 Performance

#### Optimizing for Different Jetson Models

Each Jetson platform has different capabilities requiring specific tuning:

**Jetson Nano (4GB):**
- Best with CPU-only container for most models
- For GPU usage, limit to very small models with high quantization (TinyLlama, Q4)
- Set `OLLAMA_GPU_LAYERS=5` to minimize GPU memory usage

**Jetson Xavier:**
- Can handle medium-sized models with Q4 quantization
- Set `OLLAMA_GPU_LAYERS=15` for balanced performance
- Limit to 1-2 parallel processes

**Jetson Orin Nano:**
- Works well with 7B-8B class models
- Try `OLLAMA_GPU_LAYERS=20` as a starting point
- Can handle some parallelism with `-e OLLAMA_NUM_PARALLEL=2`

**Jetson Orin AGX:**
- Can run larger models (up to 13B with quantization)
- Effective with `OLLAMA_GPU_LAYERS=20` for stability
- Can handle higher parallelism depending on model size

#### GPU Layer Configuration for Jetson Devices

The `OLLAMA_GPU_LAYERS` parameter is particularly important as it determines how many model layers are offloaded to the GPU:

- **Higher values** (e.g., all layers): Pushes more computation to the GPU but may overwhelm memory bandwidth on Jetson devices
- **Lower values** (e.g., 20 layers): Creates a better balance between GPU and CPU processing for Jetson's architecture
- **Setting to 0**: Forces CPU-only operation even in the GPU container

The `OLLAMA_NUM_PARALLEL` parameter controls concurrent processing tasks, which should be limited on constrained devices:

- Use `1` for Nano and Xavier
- Try `2-4` for Orin models with sufficient RAM

## Testing

### Using the Tag and Push Script (tag_push.sh)

After building your images, you can tag and push them to Docker Hub:

1. Update the username in the script:
   ```bash
   cd tools
   nano tag_push.sh
   # Change DOCKER_HUB_USERNAME, IMAGENAME, VERSION to your Docker Hub username, image, version
   ```

2. Run the script:
   ```bash
   chmod +x tag_push.sh
   ./tag_push.sh
   ```

### Using the Test Script(test_script_cpu_gpu_containers.sh)

To verify that your built images are working correctly:

1. Update the username in the script:
```bash
cd tools
nano test_script_cpu_gpu_containers.sh
# Change DOCKER_HUB_USERNAME, IMAGENAME, VERSION to your Docker Hub username, image, version
```

2. Run the script:
   ```bash
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
