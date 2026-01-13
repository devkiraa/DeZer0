# Example Payloads

This directory contains example payloads demonstrating the different runtime types supported by DeZer0 firmware v2.0.

## Payload Structure

Each payload must follow this structure:
```
payloads/
└── example-payload/
    ├── manifest.json       # Payload metadata
    └── payload             # Executable (native .so, .mpy, or .lua)
```

## Example Manifests

### 1. Native C/C++ Payload
```json
{
  "id": "wifi-deauther-native",
  "name": "WiFi Deauther",
  "version": "1.0.0",
  "author": "DeZer0 Team",
  "description": "Sends deauthentication frames to disconnect devices from WiFi networks",
  "category": "WiFi",
  "payload": {
    "type": "native",
    "runtime": "native",
    "entry": "payload",
    "checksum": "sha256:abc123...",
    "size": 51200
  },
  "requirements": {
    "min_firmware_version": "2.0.0",
    "apis": ["wifi", "display"],
    "memory_kb": 64,
    "storage_kb": 10
  },
  "permissions": [
    "wifi_scan",
    "wifi_inject",
    "display_write"
  ],
  "parameters": [
    {
      "name": "target_bssid",
      "type": "string",
      "label": "Target BSSID",
      "required": true
    },
    {
      "name": "duration",
      "type": "integer",
      "label": "Duration (seconds)",
      "required": false,
      "default": "60"
    }
  ]
}
```

### 2. MicroPython Payload
```json
{
  "id": "ble-scanner-mpy",
  "name": "BLE Scanner",
  "version": "1.0.0",
  "author": "Community",
  "description": "Scans for nearby Bluetooth Low Energy devices",
  "category": "Bluetooth",
  "payload": {
    "type": "micropython",
    "runtime": "micropython",
    "entry": "payload",
    "checksum": "sha256:def456...",
    "size": 8192
  },
  "requirements": {
    "min_firmware_version": "2.0.0",
    "apis": ["ble", "display"],
    "memory_kb": 32,
    "storage_kb": 5
  },
  "permissions": [
    "ble_scan",
    "display_write"
  ],
  "parameters": [
    {
      "name": "scan_duration",
      "type": "integer",
      "label": "Scan Duration (ms)",
      "required": false,
      "default": "5000"
    }
  ]
}
```

### 3. Lua Payload
```json
{
  "id": "gpio-blinker-lua",
  "name": "GPIO Blinker",
  "version": "1.0.0",
  "author": "Example",
  "description": "Blinks an LED connected to a GPIO pin",
  "category": "GPIO",
  "payload": {
    "type": "lua",
    "runtime": "lua",
    "entry": "payload",
    "checksum": "sha256:ghi789...",
    "size": 2048
  },
  "requirements": {
    "min_firmware_version": "2.0.0",
    "apis": ["gpio"],
    "memory_kb": 16,
    "storage_kb": 2
  },
  "permissions": [
    "gpio_write"
  ],
  "parameters": [
    {
      "name": "pin",
      "type": "integer",
      "label": "GPIO Pin Number",
      "required": true,
      "default": "2"
    },
    {
      "name": "interval",
      "type": "integer",
      "label": "Blink Interval (ms)",
      "required": false,
      "default": "500"
    }
  ]
}
```

## Payload Categories

- **WiFi**: WiFi scanning, deauth, packet injection, etc.
- **Bluetooth**: BLE scanning, advertising, attacks
- **Radio**: SDR, RFID, NFC operations
- **GPIO**: Hardware interfacing, sensors, actuators
- **Security**: Password cracking, hash analysis
- **Utilities**: System tools, diagnostics
- **Social**: Rickroll, fake portals, pranks

## Creating Your Own Payload

### Native C/C++ (.so)
1. Write code using DeZer0 Payload API (`payload_api.h`)
2. Compile as shared library with ESP-IDF toolchain
3. Create manifest.json
4. Package and upload via mobile app

### MicroPython (.mpy)
1. Write Python script using DeZer0 module
2. Cross-compile to .mpy: `mpy-cross script.py`
3. Create manifest.json
4. Package and upload via mobile app

### Lua (.lua)
1. Write Lua script using DeZer0 API bindings
2. No compilation needed
3. Create manifest.json
4. Package and upload via mobile app

## Payload API Reference

See `firmware/main/include/payload_api.h` for complete API documentation.

### Available APIs

#### WiFi API
- `dezero_wifi_scan_start()`
- `dezero_wifi_scan_get_results()`
- `dezero_wifi_connect()`
- `dezero_wifi_send_deauth()` (requires `wifi_inject` permission)

#### BLE API
- `dezero_ble_scan_start()`
- `dezero_ble_scan_get_results()`
- `dezero_ble_advertise_start()` (requires `ble_advertise` permission)

#### GPIO API
- `dezero_gpio_config()`
- `dezero_gpio_read()`
- `dezero_gpio_write()` (requires `gpio_write` permission)

#### Display API
- `dezero_display_clear()`
- `dezero_display_text()`
- `dezero_display_rect()`
- `dezero_display_update()`

#### Storage API
- `dezero_storage_open()`
- `dezero_storage_read()`
- `dezero_storage_write()` (requires `storage_write` permission)

#### System API
- `dezero_log_info()`, `dezero_log_error()`
- `dezero_delay()`
- `dezero_get_param()` - Get parameter values
- `dezero_send_output()` - Send data to mobile app

## Security Considerations

- All payloads run in sandboxed environment
- Memory and execution time limits enforced
- Permissions must be explicitly requested
- Dangerous operations require user confirmation
- Payloads cannot access system memory directly

## Testing Payloads

1. Upload payload via mobile app
2. Select payload from list
3. Configure parameters if needed
4. Execute and monitor output
5. Check logs via serial monitor or app

## Payload Marketplace

Publish your tools using [Nex package manager](https://github.com/nexhq/nex):

```bash
# Install Nex CLI
iwr https://raw.githubusercontent.com/nexhq/nex/main/cli/install.ps1 | iex

# Create new package in your tool directory
nex init

# Publish to Nex Registry
nex publish
```

Your package will be automatically available in the DeZer0 marketplace once published.
