#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include "ble_comms.h"
#include "menu_ui.h"
#include "wifi_tools.h"

extern bool deviceConnected;
extern UI_State uiState;
extern UIData uiData;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define LOG_CHAR_UUID       "beb5483f-36e1-4688-b7f5-ea07361b26a8"

BLECharacteristic *pLogCharacteristic = nullptr;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      uiState = STATE_CONNECTED;
      Serial.println("Device connected");
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      uiState = STATE_IDLE; // When disconnected, go back to the idle/advertising state
      Serial.println("Device disconnected, restarting advertising");
      BLEDevice::startAdvertising();
    }
};

void sendBleNotification(std::string message) {
  if (deviceConnected && pLogCharacteristic != nullptr) {
    pLogCharacteristic->setValue(message);
    pLogCharacteristic->notify();
  }
}

void sendDeviceInfo() {
  JsonDocument doc;
  doc["type"] = "device_info";
  doc["firmware_version"] = "1.0.0";
  doc["build_date"] = __DATE__;
  doc["ram_total"] = ESP.getHeapSize();
  doc["ram_used"] = ESP.getHeapSize() - ESP.getFreeHeap();
  doc["flash_total"] = ESP.getFlashChipSize();

  std::string output;
  serializeJson(doc, output);
  sendBleNotification(output);
}

class CommandCallback: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      if (value.length() > 0) {
        JsonDocument doc;
        deserializeJson(doc, value);
        const char* command = doc["command"];
        
        unsigned long executionStart = millis();
        
        if (strcmp(command, "scan_wifi") == 0) {
          strncpy(uiData.toolName, "WI-FI SCAN", sizeof(uiData.toolName));
          strncpy(uiData.targetName, "2.4GHz Channels", sizeof(uiData.targetName));
          uiState = STATE_EXECUTING;
          runWifiScan();
          uiData.executionTime = (millis() - executionStart) / 1000;
          uiState = STATE_COMPLETE;
        } else if (strcmp(command, "get_device_info") == 0) {
          sendDeviceInfo();
        }
      }
    }
};

void initBLE() {
  BLEDevice::init("DeZer0");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *pCommandCharacteristic = pService->createCharacteristic(
                                         COMMAND_CHAR_UUID,
                                         BLECharacteristic::PROPERTY_WRITE);
  pCommandCharacteristic->setCallbacks(new CommandCallback());
  pLogCharacteristic = pService->createCharacteristic(
                                         LOG_CHAR_UUID,
                                         BLECharacteristic::PROPERTY_NOTIFY);
  pLogCharacteristic->addDescriptor(new BLE2902());
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
}