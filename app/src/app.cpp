#include "app.h"     // C API
#include "app.hpp"   // C++ API

// If you want to use CubeMX-generated handles/macros, include main.h.
// This is common and works because CubeMX typically declares extern handles in main.h.
extern "C" {
#include "main.h"
}

namespace app {

static App g_app;

App& instance() { return g_app; }

void App::init() {
    // Example: toggle an LED pin defined by CubeMX in main.h
    // HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);

    // Example: use a UART handle declared in main.h (if CubeMX provides extern UART_HandleTypeDef huart3;)
    // const char msg[] = "app_init()\r\n";
    // HAL_UART_Transmit(&huart3, (uint8_t*)msg, sizeof(msg)-1, 100);
}

void App::loop() {
    // LED Blinking
    HAL_GPIO_TogglePin(LED2_GPIO_PORT, LED2_PIN);
    HAL_Delay(100);
}

} // namespace app

// ---------------- C wrappers called from main.c ----------------
extern "C" void app_init(void) { app::instance().init(); }
extern "C" void app_loop(void) { app::instance().loop(); }
