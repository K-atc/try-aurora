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

export MAGMA_TERM_ID=SSL020
cp $target_openssl/server_trace $EVAL_DIR/
# $EVAL_DIR/server_trace $EVAL_DIR/seed/crash-000117 # => [!] Aborted by canary SSL020
llvm-objdump-16 -d -S $EVAL_DIR/server_trace > $EVAL_DIR/server_trace.objdump

rm -rf $EVAL_DIR/traces
mkdir -p $EVAL_DIR/traces
### requires at least python 3.6
cd $AURORA_GIT_DIR/tracing/scripts
python3 tracing.py "$EVAL_DIR/server_trace @@" $EVAL_DIR/inputs $EVAL_DIR/traces
### extract stack and heap addr ranges from logfiles
python3 addr_ranges.py --eval_dir $EVAL_DIR $EVAL_DIR/traces
cd -
