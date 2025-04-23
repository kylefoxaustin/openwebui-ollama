# OpenWebUI with GPU-Accelerated Ollama

This repository provides Docker configurations to run [OpenWebUI](https://github.com/open-webui/open-webui) with [Ollama](https://github.com/ollama/ollama), optionally accelerated by NVIDIA GPUs for faster inference on local large language models.

## Overview

This setup provides:
* OpenWeb UI browser interface locally for your PC to interacting with large language models (LLMs)
* Instantiates a full Ollama engine in the container (again local)
* GPU acceleration for faster model inference (when available)
* Persistent storage for models and conversation history
* Containerized environment for easy deployment and management
* Goal is for the user to pull this image to any AMD64 based PC running docker for a full OWUI+Ollama experience

## Repository Structure

```
openwebui/
├── Docker_Compose/
│   ├── docker-compose.yml              # Main file (uses official images, no Dockerfile needed)
│   ├── docker-compose-cpu.yml          # CPU-only version (uses official images, no Dockerfile needed)
│   ├── docker-compose-custom-cpu.yml   # Custom CPU build (uses Dockerfile.cpu)
│   └── docker-compose-custom-gpu.yml   # Custom GPU build (uses Dockerfile.gpu)
├── Dockerfiles/
│   ├── Dockerfile.cpu                  # For custom CPU builds only
│   └── Dockerfile.gpu                  # For custom GPU builds only
└── README.md                           # Documentation
```

The main docker-compose files (docker-compose.yml and docker-compose-cpu.yml) pull pre-built images directly from their official repositories, so no Dockerfiles are required for these methods. The Dockerfiles are only used with the custom build options.

## Quick Start (Recommended)

The default configuration automatically detects if you have an NVIDIA GPU with the required drivers and uses it. Otherwise, it falls back to CPU.
However this implies your host machine has installed the necessary NVIDIA GPU infrastructure (e.g. nvidia-smi, drivers, and nvidia build container). 
Instructions for how to do this pre-step is below under **Setup for GPU Acceleration on Linux**

```bash
# Clone the repository
git clone https://github.com/kylefoxaustin/openwebui.git
cd openwebui

# Start the containers
docker compose -f Docker_Compose/docker-compose.yml up -d

# Access the web interface
# http://localhost:8080
```

That's it! For most users, this is all you need to do.

## Detailed Setup Instructions

### System Requirements

#### For All Systems
- Docker Engine (version 20.10.0 or higher)
- Docker Compose (version 2.0.0 or higher)
- 8GB+ RAM recommended (16GB+ for larger models)
- 20GB+ free disk space for models

#### For GPU Acceleration (Optional)
- NVIDIA GPU with CUDA support
- NVIDIA Driver (version 470.xx or higher)
- NVIDIA Container Toolkit (nvidia-docker2)

### Installation Options

This repository offers three deployment options:

1. **Option 1: Quick Start** (`docker-compose.yml`) - Uses official pre-built images with automatic GPU detection (no Dockerfile needed)
2. **Option 2: CPU-Only** (`docker-compose-cpu.yml`) - Explicitly uses CPU-only configuration with official images (no Dockerfile needed)
3. **Option 3: Custom Build** - Builds containers from Dockerfiles for CPU (`Dockerfile.cpu`) or GPU (`Dockerfile.gpu`)

### Setup for GPU Acceleration on Linux

If you have an NVIDIA GPU and want to use it for acceleration, you'll need to install the NVIDIA Container Toolkit:

```bash
# Set up the package repository and GPG key
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

# Create directory for keyrings if it doesn't exist
sudo mkdir -p /etc/apt/keyrings

# Download and install the GPG key
curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | sudo gpg --dearmor -o /etc/apt/keyrings/nvidia-docker.gpg

# Add the repository
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sed 's#deb https://#deb [signed-by=/etc/apt/keyrings/nvidia-docker.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Update package listings
sudo apt-get update

# Install nvidia-container-toolkit
sudo apt-get install -y nvidia-container-toolkit

# Configure the runtime
sudo nvidia-ctk runtime configure --runtime=docker

# Restart Docker to apply changes
sudo systemctl restart docker
```

Verify the installation:

```bash
sudo docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

If the above command shows your GPU information, the toolkit is properly set up.

### Deployment Options

#### Option 1: Quick Start with Official Images (Recommended)

This approach pulls pre-built images directly from their repositories and is the quickest way to get started. No Dockerfiles are needed for this method.

```bash
# Auto-detects GPU if available, otherwise uses CPU
docker compose -f Docker_Compose/docker-compose.yml up -d
```

#### Option 2: CPU-Only with Official Images

Use this option if you specifically want to ensure only CPU is used, even if you have a GPU available.

```bash
# Explicitly uses CPU-only configuration
docker compose -f Docker_Compose/docker-compose-cpu.yml up -d
```

#### Option 3: Custom Build

This approach builds the containers from the provided Dockerfiles, giving you more control but taking longer.

For CPU-only systems:
```bash
# Builds and runs a custom CPU-only container
docker compose -f Docker_Compose/docker-compose-custom-cpu.yml up -d --build
```

For systems with NVIDIA GPU:
```bash
# Builds and runs a custom GPU-enabled container
docker compose -f Docker_Compose/docker-compose-custom-gpu.yml up -d --build
```

### Windows Installation

This setup can run on Windows through Docker Desktop, with some specific considerations:

#### For Windows with CPU-only mode:

1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. Ensure WSL2 (Windows Subsystem for Linux) is enabled and configured as the default engine for Docker Desktop
3. In PowerShell or Command Prompt:

```powershell
# Clone the repository
git clone https://github.com/kylefoxaustin/openwebui.git
cd openwebui

# Start the containers (note the path format for Windows)
docker compose -f Docker_Compose\docker-compose.yml up -d
```

#### For Windows with NVIDIA GPU acceleration:

1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. Install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install)
3. Install the [NVIDIA CUDA drivers for Windows](https://developer.nvidia.com/cuda-downloads)
4. Install the latest [NVIDIA Container Toolkit for WSL2](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)
5. Ensure Docker Desktop is configured to use WSL2
6. In PowerShell or from the Ubuntu WSL2 terminal:

```bash
# Clone the repository
git clone https://github.com/kylefoxaustin/openwebui.git
cd openwebui

# Start the containers
docker compose -f Docker_Compose/docker-compose.yml up -d  # in WSL2 bash
# or
docker compose -f Docker_Compose\docker-compose.yml up -d  # in PowerShell
```

**Note:** GPU acceleration on Windows requires more configuration than on Linux and may have some performance differences. For best performance with GPU acceleration, a Linux environment is recommended.

## Building and Pushing Docker Images

If you want to build and push these images to your own Docker Hub repository:

```bash
# Clone the repository
git clone https://github.com/kylefoxaustin/openwebui.git
cd openwebui

# Login to Docker Hub
docker login

# Build CPU-only image
docker build -f Dockerfiles/Dockerfile.cpu -t yourusername/openwebui:cpu-only Dockerfiles

# Build GPU-enabled image
docker build -f Dockerfiles/Dockerfile.gpu -t yourusername/openwebui:gpu-cpu Dockerfiles

# Tag the GPU image as generic
docker tag yourusername/openwebui:gpu-cpu yourusername/openwebui:generic

# Push all images to Docker Hub
docker push yourusername/openwebui:cpu-only
docker push yourusername/openwebui:gpu-cpu
docker push yourusername/openwebui:generic

# Also push a latest tag
docker tag yourusername/openwebui:generic yourusername/openwebui:latest
docker push yourusername/openwebui:latest
```

## Usage

### Accessing the Interface

Once the containers are running, access the OpenWebUI interface at:

```
http://localhost:8080
```

### Downloading and Running Models

1. Open the OpenWebUI interface in your browser
2. Go to the "Models" section
3. Choose a model from the available options (like Llama 3, Mistral, etc.)
4. Click "Download" to download the model
5. Once downloaded, start a conversation with the model

### Verifying GPU Acceleration

To verify that GPU acceleration is working:

1. Start a conversation with a model
2. While the model is generating a response, run this command:

```bash
nvidia-smi  # Linux or WSL2
```

You should see the Ollama process in the list, confirming GPU usage.

For a more dynamic view, you can run:

```bash
watch -n 1 nvidia-smi  # Linux or WSL2
```

On Windows without WSL2 access, you can check GPU usage through the Task Manager's Performance tab.

## Configuration

### Port Configuration

By default, the services use the following ports:

- `8080`: OpenWebUI interface
- `11436`: Ollama API (changed from the default 11434 to avoid conflicts with locally installed Ollama)

If you need to change these ports, modify the appropriate docker-compose.yml file.

### Persistent Storage

The configuration includes persistent volumes for:

- `open-webui-data`: Stores conversation history and OpenWebUI configurations
- `ollama-data`: Stores downloaded models and Ollama configurations

These volumes persist even when the containers are stopped or removed.

## Troubleshooting

### Check Container Status

```bash
docker ps | grep -E 'open-webui|ollama'
```

### View Container Logs

```bash
# OpenWebUI logs
docker logs -f open-webui

# Ollama logs
docker logs -f ollama
```

### Common Issues

#### Port Conflicts

If you see an error like "port is already allocated", it means another service is using the same port. Edit the docker-compose.yml file to use a different port.

#### GPU Not Being Used

If the GPU is not being used:

1. Verify NVIDIA Container Toolkit is installed correctly
2. Ensure your GPU is supported and drivers are installed
3. Check Ollama logs for any error messages

#### Windows-Specific Issues

1. **WSL2 Not Enabled**: Ensure WSL2 is properly enabled and Docker Desktop is configured to use it
2. **Path Format Issues**: Windows uses backslashes (`\`) in paths, while Linux/WSL2 uses forward slashes (`/`)
3. **GPU Passthrough Problems**: GPU passthrough to WSL2 requires specific drivers and configuration

#### Models Running Slowly

- If using GPU, check that your GPU is properly detected with `nvidia-smi`
- Ensure you have enough system memory (16GB+ recommended for larger models)
- Try a smaller model that better fits your hardware capabilities

#### Cannot Access Web Interface

- Check if the containers are running with `docker ps`
- Verify port 8080 is not being used by another application
- Check container logs for any startup errors

## Additional Commands

### Stopping the Containers

```bash
docker compose -f Docker_Compose/docker-compose.yml down
```

### Updating the Containers

```bash
cd openwebui
docker compose -f Docker_Compose/docker-compose.yml pull
docker compose -f Docker_Compose/docker-compose.yml up -d
```

### Removing Volumes (Caution: This will delete all models and data)

```bash
docker compose -f Docker_Compose/docker-compose.yml down -v
```

## Compatibility

### Hardware Support

This project has been tested with:

- **CPUs**: Intel and AMD x86_64 processors
- **GPUs**: NVIDIA Quadro RTX 8000, RTX series, and Tesla series

### Operating Systems

- Ubuntu 22.04 LTS (primary test platform)
- Other Linux distributions with Docker support
- Windows 10/11 with WSL2 and Docker Desktop
- macOS with Docker Desktop (CPU-only)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [OpenWebUI](https://github.com/open-webui/open-webui) for the web interface
- [Ollama](https://github.com/ollama/ollama) for the model inference server
- [NVIDIA](https://github.com/NVIDIA/nvidia-docker) for the Container Toolkit
