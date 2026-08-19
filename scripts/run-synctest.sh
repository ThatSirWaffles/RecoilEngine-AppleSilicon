#!/bin/bash
# Run the tracked streflop cross-architecture reference test.
set -euo pipefail

BAR="${BAR:-$(cd "$(dirname "$0")/.." && pwd)}"
BUILD_DIR="${SYNCTEST_BUILD_DIR:-$BAR/build-synctest}"
OUTPUT_PREFIX="${SYNCTEST_OUTPUT_PREFIX:-$BUILD_DIR/streflop_results_NEON_arm64}"

while [ $# -gt 0 ]; do
  case "$1" in
    --build-dir) BUILD_DIR=$2; shift 2;;
    *) echo "unknown arg: $1"; exit 2;;
  esac
done

REFERENCE="$BAR/tools/sync-test/reference/streflop_results_NEON_arm64.bin"
COMPARATOR="$BAR/tools/sync-test/compare_results.py"
[ -f "$REFERENCE" ] || { echo "FATAL: missing sync-test reference: $REFERENCE"; exit 2; }
[ -f "$COMPARATOR" ] || { echo "FATAL: missing sync-test comparator: $COMPARATOR"; exit 2; }

cmake -S "$BAR/tools/sync-test" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DSTREFLOP_MODE=NEON
cmake --build "$BUILD_DIR" --target streflop-float-test
"$BUILD_DIR/streflop-float-test" -n 10000 "$OUTPUT_PREFIX"
python3 "$COMPARATOR" "$REFERENCE" "${OUTPUT_PREFIX}.bin"
echo "STREFLOP_SYNC_TEST_OK"