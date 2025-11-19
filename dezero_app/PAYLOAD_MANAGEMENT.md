# Payload Management Feature

## Overview

The Flutter app now includes comprehensive payload management capabilities that allow users to:
- View installed payloads on the DeZer0 device
- Execute payloads with configurable parameters
- Monitor payload execution status
- Upload new payloads to the device
- Delete payloads from the device

## Components

### Models
- **`lib/models/payload.dart`**: Complete payload data model including:
  - Payload metadata (id, name, version, author, description)
  - Payload configuration (type, runtime, entry point, size)
  - Requirements (firmware version, memory, storage, APIs)
  - Permissions list
  - Configurable parameters with types and validation
  - PayloadStatus enum for tracking execution state

### Services
- **`lib/services/payload_management_service.dart`**: Service layer handling:
  - Fetching installed payloads from device
  - Syncing payloads between device and local storage
  - Uploading payloads with multipart/form-data
  - Executing payloads with runtime parameters
  - Stopping running payloads
  - Deleting payloads
  - Checking payload execution status
  - Local storage management
  - Status tracking with ValueNotifier

### Screens
- **`lib/screens/payloads_screen.dart`**: Main payload management UI
  - Grid/list view of installed payloads
  - Category filtering (Security, Network, Utilities, IoT, Custom)
  - Quick execute/stop controls
  - Payload search and sorting
  - Upload dialog placeholder
  - Connection status checking

- **`lib/screens/payload_detail_screen.dart`**: Detailed payload view
  - Complete payload information display
  - Runtime status monitoring
  - Parameter configuration UI
  - Execute/stop controls
  - Memory and CPU usage display
  - Permission details
  - Requirements verification

## API Endpoints

The payload management service interacts with these device API endpoints:

- `GET /api/payloads` - List all installed payloads
- `POST /api/payloads/upload` - Upload a new payload (multipart/form-data)
- `DELETE /api/payloads/{id}` - Delete a payload
- `POST /api/payloads/{id}/execute` - Execute a payload with parameters
- `POST /api/payloads/{id}/stop` - Stop a running payload
- `GET /api/payloads/{id}/status` - Get payload execution status

## Payload Types Supported

1. **Native C++** (.so) - Compiled shared libraries for maximum performance
2. **MicroPython** (.mpy) - Cross-compiled Python bytecode
3. **Lua** (.lua) - Interpreted Lua scripts
4. **Built-in** - Pre-installed system modules

## Parameter Types

Payloads can define configurable parameters:
- **String**: Text input
- **Integer**: Numeric input with optional min/max
- **Boolean**: Toggle switch
- **Select**: Dropdown with predefined options

## Usage

### Accessing Payloads
1. Open the app drawer (hamburger menu)
2. Select "Payloads" under Quick Access
3. Ensure device is connected via WiFi

### Executing a Payload
1. Tap on a payload card
2. Review payload details and requirements
3. Click "Execute" button
4. Configure parameters if required
5. Confirm execution

### Monitoring Execution
- Running payloads show a "RUNNING" badge
- Tap payload to view detailed status
- Status includes uptime, memory usage, and CPU time
- Use "Stop" button to terminate execution

### Managing Payloads
- Swipe or long-press to delete
- Use category filters to organize
- Star favorites for quick access

## Local Storage

Payloads are cached locally in:
```
{AppDocuments}/payloads/{payload_id}/
  ├── manifest.json
  └── payload (binary file)
```

Installation state is persisted in SharedPreferences under the key `installed_payloads`.

## Integration

The payload management is integrated into the main navigation:
- Added to drawer menu under "Quick Access"
- Accessible alongside Favorites, Activity History, and Updates
- Follows the same design patterns as existing screens
- Uses FlipperColors theme for consistency

## Future Enhancements

- [ ] Implement payload upload from local files
- [ ] Add payload marketplace integration
- [ ] Support batch operations
- [ ] Add payload execution history
- [ ] Implement payload templates
- [ ] Add payload versioning and updates
- [ ] Support payload dependencies
- [ ] Add payload sandboxing controls
- [ ] Implement payload logging viewer
- [ ] Add payload performance profiling

## Security Considerations

- Payloads require explicit permissions
- Requirements are validated before execution
- Resource limits (memory, CPU time) are enforced
- Payloads run in isolated contexts
- User confirmation required for dangerous operations

## Testing

To test the payload management feature:
1. Connect to a DeZer0 device
2. Navigate to Payloads screen
3. Verify existing payloads are loaded
4. Test execute/stop functionality
5. Check parameter configuration UI
6. Verify status updates

Note: Requires firmware with payload API endpoints implemented.
