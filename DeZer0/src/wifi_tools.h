#ifndef WIFI_TOOLS_H
#define WIFI_TOOLS_H

#include <Arduino.h>

void initWiFi();
void runWifiScan();
void startDeauthAttack(const uint8_t* bssid, int channel);

#endif