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
#   ./patch_cubemx.sh platform/stm32/nucleo_h7a3ziq/cubemx

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <cubemx-root>"
  exit 2
fi

CUBEMX_ROOT="$(cd "$1" && pwd)"
FILE="$CUBEMX_ROOT/cmake/stm32cubemx/CMakeLists.txt"

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: Not found: $FILE"
  exit 1
fi

echo "[patch] Target: $FILE"

# 0) If the file doesn't contain the problematic pattern, do nothing.
if ! grep -q '\${CMAKE_SOURCE_DIR}/' "$FILE"; then
  echo "[patch] No \${CMAKE_SOURCE_DIR}/ pattern found. Nothing to do."
  exit 0
fi

# 1a) Repair the common broken patch variant ("/../..")
perl -i -pe 's|get_filename_component\(CUBEMX_ROOT\s+"\/\.\.\/\.\."\s+ABSOLUTE\)|get_filename_component(CUBEMX_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)|g' "$FILE"

# 1) Insert CUBEMX_ROOT definition once (right after cmake_minimum_required(...)).
# CubeMX root is two levels up from cmake/stm32cubemx/
if ! grep -q 'get_filename_component(CUBEMX_ROOT' "$FILE"; then
  echo "[patch] Inserting CUBEMX_ROOT definition..."
  perl -0777 -i -pe '
    s/(cmake_minimum_required\([^\)]*\)\s*\n)/$1
# ---- patch_cubemx.sh (manual patch; rerun after CubeMX regen)
get_filename_component(CUBEMX_ROOT "${CMAKE_CURRENT_LIST_DIR}\/..\/.." ABSOLUTE)
# ---- end patch
/;
  ' "$FILE"
else
  echo "[patch] CUBEMX_ROOT already present."
fi

# 2) Rewrite paths
echo "[patch] Rewriting \${CMAKE_SOURCE_DIR}/ -> \${CUBEMX_ROOT}/ ..."
perl -i -pe 's/\$\{CMAKE_SOURCE_DIR\}\//\$\{CUBEMX_ROOT\}\//g' "$FILE"

echo "[patch] Done."
