#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TRY_AURORA_DIR="$SCRIPT_DIR/.."
PROJECT_DIR="$TRY_AURORA_DIR/.."
TRY_CLANG_DIR="$PROJECT_DIR/try-clang"
MAGMA_DIR="$TRY_AURORA_DIR/magma-v1.2"
EVALUATION_DIR="$PROJECT_DIR/evaluation"
target_libtiff="$MAGMA_DIR/targets/libtiff"

EVAL_DIR=$SCRIPT_DIR/result
set -x

### Place the initial crashing seed:
mkdir -p $EVAL_DIR/seed
# cp $EVALUATION_DIR/input-file/7fcf1f3ea2333be518eac93dc8bcfc276272db21/crash-000117 ${EVAL_DIR}/seed/

### fuzzing (timeout 43200)
### FIXME: revert timeout
export MAGMA_TERM_ID=TIF008
# $target_libtiff/tiff_read_rgba_fuzzer.afl ${EVAL_DIR}/seed/crash-000117
timeout 10800 \
    $AFL_DIR/afl-fuzz -C -d -m none -i ${EVAL_DIR}/seed/ -o $AFL_WORKDIR -- \
    $target_libtiff/tiff_read_rgba_fuzzer.afl @@ \
    || true

### move (non-)crashes to eval dir
rm -rf $EVAL_DIR/inputs
mkdir -p $EVAL_DIR/inputs/non_crashes
cp -r $AFL_WORKDIR/queue/ $EVAL_DIR/inputs/crashes/
cp -r $AFL_WORKDIR/non_crashes/ $EVAL_DIR/inputs/