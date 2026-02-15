#pragma once

namespace app {

class App {
public:
    void init();
    void loop();
};

// Single global instance accessor (simple + embedded-friendly)
App& instance();

} // namespace app
