#!/usr/bin/env bash
set -euo pipefail

# patch_cubemx.sh
# Fix CubeMX-generated cmake/stm32cubemx/CMakeLists.txt that wrongly uses ${CMAKE_SOURCE_DIR}
# When CubeMX output is nested inside a larger repo, ${CMAKE_SOURCE_DIR} points to the repo root,
# so paths like ${CMAKE_SOURCE_DIR}/Core/Src/main.c break.
#
# This patch:
#   1) Defines CUBEMX_ROOT as the CubeMX project root (computed from this CMakeLists location)
#   2) Replaces ${CMAKE_SOURCE_DIR}/... with ${CUBEMX_ROOT}/...
#
# Usage:
#   ./patch_cubemx.sh <path-to-cubemx-root>
#
# Example:
#   ./patch_cubemx.sh nucleo_h7a3ziq/cubemx
#   ./patch_cubemx.sh platform/stm32/nucleo_h7a3ziq/

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <board-root>"
  exit 2
fi

BOARD_ROOT="$(cd "$1" && pwd)"
FILE="$BOARD_ROOT/cmake/stm32cubemx/CMakeLists.txt"

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: Not found: $FILE"
  echo "Expected: <board-root>/cmake/stm32cubemx/CMakeLists.txt"
  exit 1
fi

echo "[patch] TARGET = $FILE"
echo "[patch] BOARD_ROOT = $BOARD_ROOT"

# If the file doesn't contain the problematic pattern, do nothing.
if ! grep -q '\${CMAKE_SOURCE_DIR}/' "$FILE"; then
  echo "[patch] No \${CMAKE_SOURCE_DIR}/ pattern found. Nothing to do."
  exit 0
fi

# 1) Remove any previous injected patch block (safe to run multiple times).
perl -0777 -i -pe '
  s/\n# ---- patch_cubemx\.sh.*?# ---- end patch\n//gs
' "$FILE"

# 2) Insert a correct definition right after cmake_minimum_required(...)
#    Inject the absolute path as a literal string.
perl -0777 -i -pe 's/(cmake_minimum_required\([^\)]*\)\s*\n)/$1
# ---- patch_cubemx.sh (manual patch; rerun after CubeMX regen)
set(CUBEMX_ROOT "__BOARD_ROOT__")
# ---- end patch
/;' "$FILE"

# Replace placeholder with actual path (escape backslashes just in case).
ESCAPED_BOARD_ROOT=$(printf '%s\n' "$BOARD_ROOT" | sed 's/[\/&]/\\&/g')
sed -i "s/__BOARD_ROOT__/${ESCAPED_BOARD_ROOT}/g" "$FILE"

# 3) Rewrite paths
echo "[patch] Rewriting \${CMAKE_SOURCE_DIR}/ -> \${CUBEMX_ROOT}/ ..."
perl -i -pe 's/\$\{CMAKE_SOURCE_DIR\}\//\$\{CUBEMX_ROOT\}\//g' "$FILE"

echo "[patch] DONE."