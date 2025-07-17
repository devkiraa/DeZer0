# main.py - Final Asynchronous WebSocket Server

import machine
import time
import uasyncio as asyncio
import ujson
import esp32
import network
from websockets.server import serve

# --- Global Objects & Setup ---
i2c = machine.I2C(0, scl=machine.Pin(22), sda=machine.Pin(21))
led = machine.Pin(2, machine.Pin.OUT)
try:
    from ssd1306 import SSD1306_I2C
    oled = SSD1306_I2C(128, 64, i2c)
except ImportError:
    oled = None

# --- UI & Status Functions ---
def display_status(line1, line2=""):
    if oled:
        oled.fill(0)
        oled.text(line1, int(64 - len(line1) * 4) if len(line1) < 16 else 0, 20)
        if line2:
            oled.text(line2, int(64 - len(line2) * 4) if len(line2) < 16 else 0, 35)
        oled.show()
    print(line1, line2)

# --- Tool Functions ---
def get_device_info():
    return {
        "type": "device_info", "firmware_version": "5.1-ASYNC",
        "build_date": "2025-07-15", "ram_total": esp32.heap_info()[0],
        "ram_used": esp32.heap_info()[0] - esp32.heap_info()[1],
        "flash_total": 4194304
    }

def scan_wifi():
    sta_if = network.WLAN(network.STA_IF)
    networks_found = sta_if.scan()
    results = {"type": "wifi_scan_results", "networks": []}
    for ssid, bssid, channel, rssi, authmode, hidden in networks_found[:5]:
        results["networks"].append({"ssid": ssid.decode('utf-8', 'ignore'), "rssi": rssi})
    return results

# --- WebSocket Handler ---
async def command_handler(websocket):
    print("WebSocket client connected.")
    display_status("CLIENT CONNECTED")
    try:
        async for message in websocket:
            print("Command received:", message)
            try:
                command_json = ujson.loads(message)
                cmd = command_json.get("command")
                response = {}
                if cmd == "get_device_info": response = get_device_info()
                elif cmd == "scan_wifi": response = scan_wifi()
                
                if response:
                    await websocket.send(ujson.dumps(response))
                    print("Sent response")
            except Exception as e:
                print(f"Error processing command: {e}")
    except Exception as e:
        print(f"WebSocket connection error: {e}")
    finally:
        print("Client disconnected.")
        ip_address = network.WLAN(network.STA_IF).ifconfig()[0]
        display_status("READY", ip_address)

# --- Main Asynchronous Tasks ---
async def main():
    ip_address = network.WLAN(network.STA_IF).ifconfig()[0]
    display_status("READY", ip_address)
    
    server_task = asyncio.create_task(serve(command_handler, "0.0.0.0", 80))
    led_task = asyncio.create_task(blink_task())
    await asyncio.gather(server_task, led_task)

async def blink_task():
    # We will just blink slowly to indicate the server is running
    while True:
        led.value(not led.value())
        await asyncio.sleep_ms(1000)

# --- Program Entry Point ---
try:
    print("Starting main application...")
    asyncio.run(main())
except KeyboardInterrupt:
    print("Application stopped.")
except Exception as e:
    print(f"An error occurred in main: {e}")