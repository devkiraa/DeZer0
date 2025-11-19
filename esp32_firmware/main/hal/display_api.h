#ifndef DISPLAY_API_H
#define DISPLAY_API_H

#include <string>
#include "driver/gpio.h"
#include "driver/spi_master.h"

class DisplayAPI {
public:
    static DisplayAPI& getInstance() {
        static DisplayAPI instance;
        return instance;
    }
    
    bool initialize();
    void deinit();
    
    void clear();
    void update();
    
    void drawText(int x, int y, const std::string& text, int size);
    void drawPixel(int x, int y, bool color);
    void drawLine(int x1, int y1, int x2, int y2, bool color);
    void drawRect(int x, int y, int width, int height, bool fill, bool color);
    void drawCircle(int x, int y, int radius, bool fill, bool color);
    
    void setBrightness(uint8_t brightness);
    void setContrast(uint8_t contrast);
    
    int getWidth() const { return width_; }
    int getHeight() const { return height_; }
    
private:
    DisplayAPI() = default;
    ~DisplayAPI() = default;
    DisplayAPI(const DisplayAPI&) = delete;
    DisplayAPI& operator=(const DisplayAPI&) = delete;
    
    void sendCommand(uint8_t cmd);
    void sendData(uint8_t* data, size_t len);
    
    bool initialized_;
    int width_;
    int height_;
    uint8_t* framebuffer_;
    spi_device_handle_t spi_;
    
    // SSD1306 default pins
    static constexpr int PIN_SCK = 18;
    static constexpr int PIN_MOSI = 23;
    static constexpr int PIN_DC = 16;
    static constexpr int PIN_RST = 17;
    static constexpr int PIN_CS = 5;
};

#endif // DISPLAY_API_H
