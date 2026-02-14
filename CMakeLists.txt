cmake_minimum_required(VERSION 3.22)

project(stm32starterpack C ASM)

# -------------------- Board selection --------------------
set(STM32_BOARD "nucleo_h7a3ziq" CACHE STRING "Board name under platform/stm32/")
set(STM32_CUBEMX_DIR "${CMAKE_SOURCE_DIR}/platform/stm32/${STM32_BOARD}"
    CACHE PATH "CubeMX generated project root")

message(STATUS "STM32_BOARD     = ${STM32_BOARD}")
message(STATUS "STM32_CUBEMX_DIR = ${STM32_CUBEMX_DIR}")

if(NOT EXISTS "${STM32_CUBEMX_DIR}/Core" OR NOT EXISTS "${STM32_CUBEMX_DIR}/Drivers")
  message(FATAL_ERROR
    "CubeMX drop not found at: ${STM32_CUBEMX_DIR}\nExpected Core/ and Drivers/ inside it.")
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# -------------------- Firmware target --------------------
add_executable(${PROJECT_NAME})

# -------------------- Pull in CubeMX-generated CMake --------------------
add_subdirectory(
  "${STM32_CUBEMX_DIR}/cmake/stm32cubemx"
  "${CMAKE_BINARY_DIR}/stm32cubemx"
)

# IMPORTANT: CubeMX uses PLAIN target_link_libraries() in its generated cmake.
# Therefore we must also use the PLAIN signature here (no PRIVATE/PUBLIC/INTERFACE).
target_link_libraries(${PROJECT_NAME} stm32cubemx)

# -------------------- MCU compile flags --------------------
# These MUST apply to CubeMX driver compilation too, not just the top-level target.
# The correct place to attach them is the stm32cubemx INTERFACE library.
set(STM32_CPU_FLAGS
  -mcpu=cortex-m7
  -mthumb
  -mfpu=fpv5-d16
  -mfloat-abi=hard
)

target_compile_options(stm32cubemx INTERFACE
  ${STM32_CPU_FLAGS}
  -Wall -Wextra -Wpedantic
  -fdata-sections -ffunction-sections
  $<$<CONFIG:Debug>:-O0;-g3>
  $<$<CONFIG:Release>:-Os;-g0>
)

# If you add C++ later, keep embedded-friendly defaults
target_compile_options(stm32cubemx INTERFACE
  $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti;-fno-exceptions;-fno-threadsafe-statics>
)

# Startup asm is usually preprocessed
set_source_files_properties(
  "${STM32_CUBEMX_DIR}/startup_stm32h7a3xxq.s"
  PROPERTIES COMPILE_OPTIONS "-x;assembler-with-cpp"
)

# -------------------- Linker script + link flags --------------------
set(STM32_LINKER_SCRIPT "${STM32_CUBEMX_DIR}/STM32H7A3XX_FLASH.ld"
    CACHE FILEPATH "Linker script")

if(NOT EXISTS "${STM32_LINKER_SCRIPT}")
  message(FATAL_ERROR "Linker script not found: ${STM32_LINKER_SCRIPT}")
endif()

target_link_options(${PROJECT_NAME} PRIVATE
  ${STM32_CPU_FLAGS}
  -T "${STM32_LINKER_SCRIPT}"
  --specs=nano.specs
  -Wl,-Map=${PROJECT_NAME}.map
  -Wl,--gc-sections
  -Wl,--print-memory-usage
  -Wl,--start-group -lc -lm -Wl,--end-group
)

# -------------------- Your app code (outside CubeMX) --------------------
# target_sources(${PROJECT_NAME} PRIVATE app/src/foo.c)
# target_include_directories(${PROJECT_NAME} PRIVATE app/include)
