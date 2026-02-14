# STM32 Starter Pack

This repo is a **portable STM32 firmware starter** that keeps **CubeMX output isolated per board** under `platform/stm32/<board>/cubemx/`, while the **repo-level build** is controlled by a clean top-level `CMakeLists.txt` + `CMakePresets.json`.

The rule: **never hand-edit CubeMX-generated files** (they get overwritten). If CubeMX generates CMake that assumes `${CMAKE_SOURCE_DIR}` is the CubeMX root, we apply a **manual patch** after each re-generation.


## One-time (per CubeMX regen): Patch CubeMX CMake

CubeMX generates `cmake/stm32cubemx/CMakeLists.txt` with paths rooted at `${CMAKE_SOURCE_DIR}`.
In this repo, CubeMX is nested under `platform/`, so you must patch after every CubeMX re-generation.

From repo root:

```bash
bash platform/stm32/patch_cubemx.sh platform/stm32/nucleo_h7a3ziq/cubemx
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
