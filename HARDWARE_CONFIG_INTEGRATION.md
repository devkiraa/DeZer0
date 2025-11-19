# Hardware Configuration Integration Guide

## Quick Start

The Hardware Configuration system is now fully implemented. Here's how to integrate it into your app navigation:

## Adding to Main Screen Drawer

In `lib/main_screen.dart`, add the hardware config screen option to the drawer menu:

### 1. Add Import
```dart
import 'screens/hardware_config_screen.dart';
```

### 2. Add Menu Item
Add this after the "Payloads" item in the drawer (around line 200):

```dart
_buildModernDrawerItem(
  icon: Icons.developer_board_rounded,
  title: 'Hardware Config',
  subtitle: 'Pin management',
  onTap: () {
    Navigator.pop(context);
    
    // Get device IP from WiFi service if connected
    String? deviceIP;
    if (_wifiService.connectionState == WifiConnectionState.connected) {
      // You'll need to add a getter for deviceIP in WifiService
      // or get it from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      deviceIP = prefs.getString('last_connected_ip');
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HardwareConfigScreen(
          deviceIP: deviceIP,
        ),
      ),
    );
  },
),
```

## Alternative: Add as Bottom Nav Tab

If you want hardware config as a main tab (next to Device, Apps, Tools):

### 1. Update `_widgetOptions` list
```dart
List<Widget> get _widgetOptions => [
  DeviceScreen(...),
  AppsScreen(...),
  ToolsScreen(...),
  HardwareConfigScreen(deviceIP: _getDeviceIP()), // Add this
];
```

### 2. Add Bottom Nav Item
```dart
BottomNavigationBarItem(
  icon: const Icon(Icons.developer_board),
  label: 'Hardware',
  backgroundColor: FlipperColors.surface,
),
```

## Standalone Usage

You can also navigate to hardware config from anywhere:

```dart
// From any screen with context
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HardwareConfigScreen(
      deviceIP: '192.168.4.1', // Optional: pass device IP if known
    ),
  ),
);
```

## Features Available

### Without Device Connection (Offline Mode)
- Create hardware configurations
- Add/remove modules
- Manual pin assignment
- Auto pin allocation
- Validation
- Code generation
- Local storage

### With Device Connection (Online Mode)
All offline features PLUS:
- Fetch current config from ESP32
- Upload config to ESP32
- View device info (chip model, memory, etc.)
- Real-time validation against actual hardware

## Usage Flow

1. **Initial Setup**: User opens Hardware Config screen
2. **Device Detection**: If `deviceIP` provided, app fetches device info and current config
3. **Configuration**: User adds modules and assigns pins (manually or auto)
4. **Validation**: Real-time validation shows any errors
5. **Code Generation**: Generate Python/C++/JSON code
6. **Upload**: Push config to ESP32 (requires connection)

## Testing Without ESP32

You can test the full UI without an ESP32:

```dart
// Just don't pass deviceIP
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HardwareConfigScreen(),
  ),
);
```

This works in offline mode with all features except device sync.

## ESP32 Firmware Requirements

For full functionality, ESP32 firmware needs these HTTP endpoints:

### GET `/api/device/info`
Returns device specs (chip model, memory, MAC, etc.)

### GET `/api/hardware/config`  
Returns current hardware configuration

### POST `/api/hardware/config`
Accepts new configuration and applies it

See `HARDWARE_CONFIG.md` for detailed API schemas.

## Complete File List

Files added for this feature:
```
dezero_app/
├── lib/
│   ├── models/
│   │   ├── hardware_config.dart       ✅ Complete
│   │   └── esp32_pins.dart            ✅ Complete
│   ├── services/
│   │   └── hardware_config_service.dart  ✅ Complete
│   └── screens/
│       └── hardware_config_screen.dart   ✅ Complete
└── docs/
    ├── HARDWARE_CONFIG.md             ✅ Full documentation
    └── HARDWARE_CONFIG_INTEGRATION.md ✅ This guide
```

All files compile without errors ✅

## Next Steps

1. Add menu item to drawer (see code above)
2. Test offline mode first
3. Implement ESP32 API endpoints
4. Test with real device
5. Enjoy automated pin management! 🎉

## Questions?

See `HARDWARE_CONFIG.md` for:
- Detailed architecture
- Pin reference tables
- API specifications
- Code generation examples
- Troubleshooting guide
