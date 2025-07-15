#include <Arduino.h>
#include "menu_ui.h"
#include "wifi_tools.h"
#include "ble_comms.h"

// Global flag for connection status
bool deviceConnected = false;

// Global variable to control the UI's animation state
UI_State uiState = STATE_BOOTING; 
UIData uiData;

unsigned long startTime = 0;

void setup() {
  Serial.begin(115200);
  randomSeed(analogRead(A0));
  
  // Initialize peripherals first
  initDisplay();
  initWiFi();
  initBLE();

  // Set the initial state to BOOTING and record start time
  uiState = STATE_BOOTING;
  startTime = millis();
}

void loop() {
  // The main UI animation and state loop
  switch (uiState) {
    case STATE_BOOTING:
      // Play the boot sequence once
      playBootSequence();
      // After booting is done, switch to idle/advertising state
      uiState = STATE_IDLE;
      break;

    case STATE_IDLE:
      // Play the continuous advertising animation
      drawIdleScreen(millis() - startTime);
      break;
    
    case STATE_CONNECTED:
      // When connected, show a static screen.
      // The BLE onConnect callback will set this state.
      drawConnectedScreen();
      delay(200); // Prevent busy-looping
      break;

    case STATE_EXECUTING:
      drawExecutingScreen(uiData);
      break;

    case STATE_COMPLETE:
      drawCompleteScreen(uiData);
      delay(3000); // Pause on the complete screen for 3 seconds
      uiState = STATE_CONNECTED; // Go back to connected state
      break;
  }
}