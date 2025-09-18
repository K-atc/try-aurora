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

cp $SCRIPT_DIR/arguments.txt $EVAL_DIR/

# go to directory
cd $AURORA_GIT_DIR/root_cause_analysis

# run root cause analysis
cargo run --release --bin rca -- --eval-dir $EVAL_DIR --trace-dir $EVAL_DIR --monitor --rank-predicates

# (Optional) enrich with debug symbols
# cargo run --release --bin addr2line -- --eval-dir $EVAL_DIR

python3 $TRY_AURORA_DIR/addr2line.py $EVAL_DIR/server_trace $EVAL_DIR/ranked_predicates.txt > $EVAL_DIR/ranked_predicates_addr2line.txt

echo "[*] Done"