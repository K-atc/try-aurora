#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TRY_AURORA_DIR="$SCRIPT_DIR/.."
PROJECT_DIR="$TRY_AURORA_DIR/.."
TRY_CLANG_DIR="$PROJECT_DIR/try-clang"
MAGMA_DIR="$TRY_AURORA_DIR/magma-v1.2"
EVALUATION_DIR="$PROJECT_DIR/evaluation"
target_openssl="$MAGMA_DIR/targets/openssl"

EVAL_DIR=$SCRIPT_DIR/result
set -x

### Place the initial crashing seed:
mkdir -p $EVAL_DIR/seed
# cp $EVALUATION_DIR/input-file/34c773c1bffb7389c434899395211077dcebf8c9/crash-000005 ${EVAL_DIR}/seed/

### fuzzing (timeout 43200)
### MEMO: "exec speed : 46.15/sec (slow!)"
export MAGMA_TERM_ID=SSL020
# $target_openssl/server_trace ${EVAL_DIR}/seed/crash-000005 # => [!] Aborted by canary SSL020
timeout --preserve-status 43200 \
    $AFL_DIR/afl-fuzz -C -d -m none -i ${EVAL_DIR}/seed/ -o $AFL_WORKDIR -- \
    $target_openssl/server.afl @@

### move (non-)crashes to eval dir
rm -rf $EVAL_DIR/inputs
mkdir -p $EVAL_DIR/inputs/non_crashes
cp -r $AFL_WORKDIR/queue/ $EVAL_DIR/inputs/crashes/
cp -r $AFL_WORKDIR/non_crashes/ $EVAL_DIR/inputs/