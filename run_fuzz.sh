#!/bin/bash

MESA_DIR="$HOME/wgslsmith/mesa"
ASAN_DIR="/usr/lib/llvm-20/lib/clang/20/lib/linux"
ASAN_RT="$ASAN_DIR/libclang_rt.asan-x86_64.so"

if [ "$1" == "setup" ]; then
    ICD_PATH="$MESA_DIR/share/vulkan/icd.d"
    OLD_PATH="/home/runner/work/mesaASAN/mesaASAN/mesa/builddir/install"
    
    for icd in intel_icd.x86_64.json radeon_icd.x86_64.json lvp_icd.x86_64.json; do
        if [ -f "$ICD_PATH/$icd" ]; then
            sed -i "s|$OLD_PATH|$MESA_DIR|g" "$ICD_PATH/$icd"
        fi
    done
    exit 0
fi

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 [amd|intel|llvmpipe] <command...>"
    exit 1
fi

GPU_TARGET=$1
shift

if [ "$GPU_TARGET" == "amd" ]; then
    export VK_ICD_FILENAMES="$MESA_DIR/share/vulkan/icd.d/radeon_icd.x86_64.json"
    DRM_SHIM="$MESA_DIR/lib/x86_64-linux-gnu/libamdgpu_noop_drm_shim.so"
elif [ "$GPU_TARGET" == "intel" ]; then
    export VK_ICD_FILENAMES="$MESA_DIR/share/vulkan/icd.d/intel_icd.x86_64.json"
    DRM_SHIM="$MESA_DIR/lib/x86_64-linux-gnu/libintel_noop_drm_shim.so"
elif [ "$GPU_TARGET" == "llvmpipe" ]; then
    export VK_ICD_FILENAMES="$MESA_DIR/share/vulkan/icd.d/lvp_icd.x86_64.json"
    DRM_SHIM=""
else
    echo "Error: Target must be 'amd', 'intel', or 'llvmpipe'"
    exit 1
fi

export LD_LIBRARY_PATH="$ASAN_DIR:$MESA_DIR/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

if [ -n "$DRM_SHIM" ]; then
    export LD_PRELOAD="$ASAN_RT $DRM_SHIM"
else
    export LD_PRELOAD="$ASAN_RT"
fi

export ASAN_OPTIONS="detect_odr_violation=0:detect_leaks=0"

echo "=== Running wgslsmith faked as $GPU_TARGET ==="
exec "$@"
