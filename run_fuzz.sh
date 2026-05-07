#!/bin/bash

MESA_DIR="$PWD/mesa"
ASAN_DIR="/usr/lib/llvm-20/lib/clang/20/lib/linux"
ASAN_RT="$ASAN_DIR/libclang_rt.asan-x86_64.so"

ENABLE_COVERAGE=1

while [[ "$#" -gt 0 && "$1" == -* ]]; do
    case "$1" in
        --no-coverage)
            ENABLE_COVERAGE=0
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--no-coverage] [setup | amd|intel|llvmpipe <command...>]"
            exit 1
            ;;
    esac
done

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
    echo "Usage: $0 [--no-coverage] [amd|intel|llvmpipe] <command...>"
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

### Coverage ###
if [ "$ENABLE_COVERAGE" -eq 1 ]; then
    OUT_DIR="${PROFRAW_DIR:-.}"
    COUNTER_FILE="$OUT_DIR/.fuzz_coverage_counter"

    mkdir -p "$OUT_DIR"

    COUNTER=$( (
      flock -x 200
      VAL=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
      VAL=$((VAL + 1))
      echo "$VAL" > "$COUNTER_FILE"
      echo "$VAL"
    ) 200>"$COUNTER_FILE.lock" )

    export LLVM_PROFILE_FILE="$OUT_DIR/fuzz_coverage_${COUNTER}_%p.profraw"
else
    unset LLVM_PROFILE_FILE
fi
### Coverage ###

echo "=== Running backend faked as $GPU_TARGET ==="
exec "$@"
