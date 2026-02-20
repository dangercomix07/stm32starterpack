# STM32 Starter Pack

This repo is a **portable STM32 firmware starter** that keeps **CubeMX output isolated per board** under `platform/stm32/<board>/cubemx/`, while the **repo-level build** is controlled by a clean top-level `CMakeLists.txt` + `CMakePresets.json`.

The rule: **never hand-edit CubeMX-generated files** (they get overwritten). If CubeMX generates CMake that assumes `${CMAKE_SOURCE_DIR}` is the CubeMX root, we apply a **manual patch** after each re-generation.


## One-time (per CubeMX regen): Patch CubeMX CMake

CubeMX generates `cmake/stm32cubemx/CMakeLists.txt` with paths rooted at `${CMAKE_SOURCE_DIR}`.
In this repo, CubeMX is nested under `platform/`, so you must patch after every CubeMX re-generation.

From repo root:

```bash
./platform/stm32/patch_cubemx.sh platform/stm32/nucleo_h7a3ziq/cubemx
```

## Build using CMake Presets

### Debug

```bash
cmake --preset Debug
cmake --build --preset Debug
```

### Release

```bash
cmake --preset Release
cmake --build --preset Release
```

### Switch/Override board
```bash
cmake --preset Debug -DSTM32_BOARD=nucleo_h7a3ziq
cmake --build --preset Debug
```

## Build without presets (direct CMake commands)

### Debug

``` bash
cmake -S . -B build/debug -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_TOOLCHAIN_FILE=cmake/arm-gcc-toolchain.cmake \
  -DSTM32_BOARD=nucleo_h7a3ziq

cmake --build build/debug
```

### Release

```bash
cmake -S . -B build/release -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=cmake/arm-gcc-toolchain.cmake \
  -DSTM32_BOARD=nucleo_h7a3ziq

cmake --build build/release
```
---

## Application integration (CubeMX C main → C++ app)

CubeMX generates `Core/Src/main.c` (C). We keep it as the hardware bring-up entrypoint and call into our C++ application via a small C ABI shim.

### Files
- `app/include/app.h`  
  C header with:
  - `app_init()`
  - `app_loop()`

- `app/include/app.hpp`, `app/src/app.cpp`  
  C++ implementation of the application logic. `app.cpp` provides the `extern "C"` wrappers for `app_init/app_loop`.

### CubeMX main.c
Only edit USER CODE blocks in `Core/Src/main.c`:

```c
/* USER CODE BEGIN Includes */
#include "app.h"
/* USER CODE END Includes */

...

/* USER CODE BEGIN 2 */
app_init();
/* USER CODE END 2 */

while (1)
{
  /* USER CODE BEGIN WHILE */
  app_loop();
  /* USER CODE END WHILE */
}
```

Why this pattern:
- CubeMX regen preserves USER CODE blocks.
- Keeps hardware bring-up and HAL handle instantiation in generated code.
- Keeps application logic in C++ (outside generated files).
- Avoids needing to “own main()” or fight CubeMX static init functions.

### CMake wiring (Repo-level)
We build the application as a library and link it into the firmware target:

```cmake
add_library(app STATIC
  ${CMAKE_SOURCE_DIR}/app/src/app.cpp
)

target_include_directories(app PUBLIC
  ${CMAKE_SOURCE_DIR}/app/include
)

# app needs CubeMX headers/defines/flags (HAL, main.h, etc.)
target_link_libraries(app PUBLIC stm32cubemx)

# Firmware links both CubeMX interface and app (plain signature due to CubeMX CMake)
target_link_libraries(${PROJECT_NAME} stm32cubemx app)
```
---
