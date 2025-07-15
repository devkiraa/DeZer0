#ifndef MENU_UI_H
#define MENU_UI_H

// The different states our UI can be in
enum UI_State {
  STATE_BOOTING,
  STATE_IDLE,
  STATE_CONNECTED,
  STATE_EXECUTING,
  STATE_COMPLETE
};

// A struct to hold all the dynamic data for the UI
struct UIData {
  char toolName[20] = "N/A";
  char targetName[20] = "N/A";
  int packetCount = 0;
  int executionTime = 0;
};

// --- Function Declarations ---
void initDisplay();

// Boot sequence
void playBootSequence();

// Main UI state screens
void drawIdleScreen(unsigned long uptime);
void drawConnectedScreen();
void drawExecutingScreen(const UIData& data);
void drawCompleteScreen(const UIData& data);

#endif