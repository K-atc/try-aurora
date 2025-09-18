#!/bin/bash

# build_libtiff.sh - Converted from Airflow DAG
# Description: 2025/09/07 ACSAC Artifact Evaluation
# Tags: project-ultimate-sanitizer, taint-tracking

set -eu  # Exit on any error

export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/go/bin
source ~/.profile

# Get the script directory and set up paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up project directories
PROJECT_DIR="$SCRIPT_DIR/../.."
TRY_AURORA_DIR="$SCRIPT_DIR/.."
TRY_CLANG_DIR="$PROJECT_DIR/try-clang"
MAGMA_DIR="$TRY_AURORA_DIR/magma-v1.2"
EVALUATION_DIR="$PROJECT_DIR/evaluation"

# Set up build environment
CC="clang-16"
CXX="clang++-16"
CFLAGS="-w -g -DMAGMA_ENABLE_CANARIES -include $TRY_CLANG_DIR/canary.h -Wno-error=int-conversion"
CXXFLAGS=$CFLAGS
LDFLAGS=""
LIBS="$MAGMA_DIR/fuzzers/vanilla/afl_driver.o"

# Target specific paths
target_libtiff="$MAGMA_DIR/targets/libtiff"
WORKDIR="$target_libtiff/repo"

export PATH=$PATH:$HOME/go/bin


echo "Starting build_libtiff pipeline..."
echo "========================================"

# Task: fetch_sh
echo "Task: fetch_sh"
ls "$WORKDIR" || (TARGET="$target_libtiff" OUT="$target_libtiff" "$target_libtiff/fetch.sh")

# Task: build_vanilla_fuzzer 
echo "Task: build_vanilla_fuzzer"
cd $WORKDIR && FUZZER=$MAGMA_DIR/fuzzers/vanilla OUT=$FUZZER CXX=$CXX CXXFLAGS="" $MAGMA_DIR/fuzzers/vanilla/build.sh

# Task: reset_tracee
echo "Task: reset_tracee"
git -C "$WORKDIR" reset --hard && git -C "$WORKDIR" clean -dfx

# Task: apply_patch
echo "Task: apply_patch"
cd "$WORKDIR" && TARGET="$target_libtiff" "$MAGMA_DIR/magma/apply_patches.sh"

# Task: manual_patch
echo "Task: manual_patch"
cd "$WORKDIR" && patch -p1 -i "$EVALUATION_DIR/libtiff/libtiff.no-va_arg.patch"

# Task: build_tracee_with_afl 
echo "Task: build_tracee_with_afl"
CC=/opt/evaluation/afl-fuzz/afl-gcc CXX=/opt/evaluation/afl-fuzz/afl-g++ \
    CFLAGS=$CFLAGS CXXFLAGS=$CXXFLAGS LDFLAGS=$LDFLAGS LIBS=$LIBS TARGET=$target_libtiff OUT=$target_libtiff $target_libtiff/build.sh
cp $target_libtiff/tiff_read_rgba_fuzzer $target_libtiff/tiff_read_rgba_fuzzer.afl

# Task: build_tracee
echo "Task: build_tracee"
CC=$CC CXX=$CXX \
    CFLAGS=$CFLAGS CXXFLAGS=$CXXFLAGS LDFLAGS=$LDFLAGS LIBS=$LIBS TARGET=$target_libtiff OUT=$target_libtiff $target_libtiff/build.sh
### NOTE: _trace required for AURORA's rca module
cp $target_libtiff/tiff_read_rgba_fuzzer $target_libtiff/tiff_read_rgba_fuzzer_trace


echo "========================================"
echo "[*] build_libtiff pipeline completed successfully!"