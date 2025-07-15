#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>
#include "menu_ui.h"

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

void initDisplay() {
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { for(;;); }
  display.setTextWrap(false);
}

// --- BOOT SEQUENCE ANIMATION HELPERS ---
void playWhiteFlash() {
  display.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, SSD1306_WHITE);
  display.display();
  delay(150);
}

void playDigitalNoise() {
  long startTime = millis();
  while (millis() - startTime < 800) {
    display.clearDisplay();
    display.setTextSize(1);
    for (int y = 0; y < SCREEN_HEIGHT; y += 8) {
      for (int x = 0; x < SCREEN_WIDTH; x += 6) {
        display.setCursor(x, y);
        display.print((char)random(33, 126));
      }
    }
    display.display();
    delay(50);
  }
}

void playMatrixRain() {
  display.clearDisplay();
  const int numColumns = 21;
  int yPos[numColumns];
  for (int i = 0; i < numColumns; i++) { yPos[i] = random(-SCREEN_HEIGHT, 0); }

  long startTime = millis();
  while (millis() - startTime < 1500) {
    display.clearDisplay();
    display.setTextSize(1);
    for (int i = 0; i < numColumns; i++) {
      display.setTextColor(SSD1306_WHITE);
      display.setCursor(i * 6, yPos[i]);
      display.print(random(2));
      yPos[i] += random(2, 5);
      if (yPos[i] > SCREEN_HEIGHT) { yPos[i] = 0; }
    }
    display.display();
    delay(30);
  }
}

void playLoadingBar() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(15, 18);
  display.print("Booting DeZer0...");
  display.drawRect(14, 28, 100, 8, SSD1306_WHITE);
  for(int i = 0; i < 98; i+=2) {
    display.fillRect(15 + i, 29, 2, 6, SSD1306_WHITE);
    display.display();
    delay(20);
  }
}

void playArmedMessage() {
  for (int i=0; i < 3; i++) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(10, 28);
    display.print(">> DEZER0 ARMED <<");
    display.display();
    delay(300);
    display.clearDisplay();
    display.display();
    delay(200);
  }
}

// --- MAIN BOOT SEQUENCE ---
void playBootSequence() {
  playWhiteFlash();
  playDigitalNoise();
  playMatrixRain();
  playLoadingBar();
  playArmedMessage();
}


// --- MAIN UI STATE DRAWING FUNCTIONS ---

void drawIdleScreen(unsigned long uptime) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  
  display.setCursor(28, 0);
  display.print("DEZER0 READY");
  display.drawFastHLine(0, 10, SCREEN_WIDTH, SSD1306_WHITE);

  display.setCursor(0, 14);
  display.print("Mode: STANDBY");
  display.setCursor(0, 24);
  display.print("BLE: ADVERTISING");
  
  // Uptime formatting
  char timeStr[9];
  int seconds = uptime / 1000;
  int hours = seconds / 3600;
  int minutes = (seconds % 3600) / 60;
  seconds %= 60;
  sprintf(timeStr, "%02d:%02d:%02d", hours, minutes, seconds);
  display.setCursor(0, 34);
  display.printf("Uptime: %s", timeStr);
  
  display.drawFastHLine(0, 44, SCREEN_WIDTH, SSD1306_WHITE);
  display.setCursor(0, 48);
  
  // Animated dots
  int dotCount = (millis() / 500) % 4;
  display.print("Waiting for connection");
  for(int i=0; i<dotCount; i++) display.print(".");

  display.display();
  delay(50); // Animation refresh rate
}

void drawConnectedScreen() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  
  display.setCursor(25, 0);
  display.print("DEZER0 CONNECTED");
  display.drawFastHLine(0, 10, SCREEN_WIDTH, SSD1306_WHITE);

  display.setCursor(0, 14);
  display.print("Client: MOBILE_APP [");
  display.setTextColor(SSD1306_BLACK, SSD1306_WHITE);
  display.print("V"); // Checkmark
  display.setTextColor(SSD1306_WHITE);
  display.print("]");
  
  display.setCursor(0, 24);
  display.print("Mode: CONTROLLED");
  display.setCursor(0, 34);
  display.print("Secure: TRUE");

  display.drawFastHLine(0, 44, SCREEN_WIDTH, SSD1306_WHITE);
  display.setCursor(12, 52);
  display.print("Ready for Commands");
  
  display.display();
}

void drawExecutingScreen(const UIData& data) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  display.setCursor(25, 0);
  display.printf("EXECUTING: %s", data.toolName);
  display.drawFastHLine(0, 10, SCREEN_WIDTH, SSD1306_WHITE);

  display.setCursor(0, 14);
  display.printf("Target: %s", data.targetName);
  display.setCursor(0, 24);
  display.printf("Packets: %06d", data.packetCount);

  display.drawFastHLine(0, 44, SCREEN_WIDTH, SSD1306_WHITE);
  display.setCursor(35, 52);
  display.print("Running...");

  // Animate a scan bar
  int barPosition = (millis() / 20) % (SCREEN_WIDTH + 6);
  display.fillRect(barPosition - 6, 46, 6, 4, SSD1306_WHITE);
  
  display.display();
}

void drawCompleteScreen(const UIData& data) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  
  display.setCursor(28, 0);
  display.print("TASK COMPLETE");
  display.drawFastHLine(0, 10, SCREEN_WIDTH, SSD1306_WHITE);
  
  display.setCursor(0, 14);
  display.printf("Tool: %s", data.toolName);
  display.setCursor(0, 24);
  display.printf("Duration: %ds", data.executionTime);
  
  display.drawFastHLine(0, 44, SCREEN_WIDTH, SSD1306_WHITE);
  display.setCursor(5, 52);
  display.print("Waiting for Next Command");

  display.display();
}