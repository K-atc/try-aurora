#!/bin/bash

# build_openssl.sh - Converted from Airflow DAG
# Description: 2024/01/03 v3 テイント解析エンジン版

set -eu

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

CC="clang-16"
CXX="clang++-16"
# NOTE: -fno-discard-value-names を入れるとビルド時間15分越え
CFLAGS="-w -g -O0 -DMAGMA_ENABLE_CANARIES -include ${TRY_CLANG_DIR}/canary.h -Wno-error=int-conversion"
CXXFLAGS="${CFLAGS}"
LDFLAGS=""
LIBS="${MAGMA_DIR}/fuzzers/vanilla/afl_driver.o"
AR="llvm-ar-16"

target_openssl="${MAGMA_DIR}/targets/openssl"
WORKDIR="${target_openssl}/repo"

# Function to log task execution
log_task() {
    echo "================================================"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting task: $1"
    echo "================================================"
}

# Task: build_vanilla_fuzzer
build_vanilla_fuzzer() {
    log_task "build_vanilla_fuzzer"
    cd "${WORKDIR}" && FUZZER="${MAGMA_DIR}/fuzzers/vanilla" OUT="${FUZZER}" CXX="${CXX}" CXXFLAGS="" ${MAGMA_DIR}/fuzzers/vanilla/build.sh
}

# Task: fetch_sh
fetch_sh() {
    log_task "fetch_sh"
    ls "${WORKDIR}" || TARGET="${target_openssl}" OUT="${target_openssl}" "${target_openssl}/fetch.sh"
}

# Task: reset_tracee
reset_tracee() {
    log_task "reset_tracee"
    git -C "${WORKDIR}" reset --hard
    git -C "${WORKDIR}" clean -dfx
}

# Task: apply_patch
apply_patch() {
    log_task "apply_patch"
    cd "${WORKDIR}"
    TARGET="${target_openssl}" "${MAGMA_DIR}/magma/apply_patches.sh"
}

# Task: apply_manual_patch
apply_manual_patch() {
    log_task "apply_manual_patch"
    cd "${WORKDIR}"
    patch -p1 -i "${EVALUATION_DIR}/openssl/openssl.patch"
}

# Task: build_tracee_with_afl
build_tracee_with_afl() {
    log_task "build_tracee_with_afl"
    CC=/opt/evaluation/afl-fuzz/afl-gcc CXX=/opt/evaluation/afl-fuzz/afl-g++ \
        CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" LIBS="${LIBS}" TARGET="${target_openssl}" OUT="${target_openssl}" AR=${AR} RANLIB="" ${target_openssl}/build.sh
    cp ${target_openssl}/repo/fuzz/server ${target_openssl}/server.afl
}

# Task: build_tracee
build_tracee() {
    log_task "build_tracee"
    CC=${CC} CXX=${CXX} CFLAGS=${CFLAGS} CXXFLAGS=${CXXFLAGS} LDFLAGS="${LDFLAGS}" LIBS="${LIBS}" TARGET=${target_openssl} OUT=${target_openssl} AR=${AR} RANLIB="" ${target_openssl}/build.sh
    cp ${target_openssl}/repo/fuzz/server ${target_openssl}/server_trace
}

# Main execution with proper task dependencies
main() {
    echo "Starting build_openssl pipeline"
    echo "Start time: $(date)"
    
    fetch_sh
    reset_tracee
    build_vanilla_fuzzer
    apply_patch
    apply_manual_patch    
    build_tracee_with_afl
    build_tracee
    
    echo "========================================"
    echo "Pipeline completed successfully at: $(date)"
}

# Error handling
trap 'echo "Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Execute main function
main "$@"