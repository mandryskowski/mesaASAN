# Mesa ASan Build

## Setup
1. Make sure you have all required libraries (and up-to-date llvm)
    ```bash
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y \
        wget curl unzip git build-essential \
        libvulkan1 vulkan-tools \
        libx11-xcb1 libxcb-dri3-0 libxshmfence1 libdrm2
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
    sudo ./llvm.sh 20
    ```
2. Download the artifact and unzip it to a directory named `mesa`:
    ```bash
    unzip mesa-llvmpipe-asan.zip -d mesa
    ```
3. Run the setup command to fix ICD paths from worker:
    ```bash
    mv mesa/run_fuzz.sh .
    ./run_fuzz.sh setup
    ```

## Usage
Run your Vulkan program using the wrapper:
```bash
./run_fuzz.sh <amd|intel|llvmpipe> <vulkan_program> [args...]
```