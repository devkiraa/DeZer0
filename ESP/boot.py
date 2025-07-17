# boot.py - Final TCP JSON Server

import machine
import time
import uasyncio as asyncio
import ujson
import esp32
import network

# --- WIFI CREDENTIALS ---
WIFI_SSID = "KIRANFI"
WIFI_PASSWORD = "m1670529"
# -------------------------

# --- OLED Display Setup ---
i2c = machine.I2C(0, scl=machine.Pin(22), sda=machine.Pin(21))
try:
    from ssd1306 import SSD1306_I2C
    oled = SSD1306_I2C(128, 64, i2c)
except ImportError:
    oled = None

def display_status(line1, line2=""):
    if oled:
        oled.fill(0)
        oled.text(line1[:16], 2, 28)
        if line2: oled.text(line2[:16], 2, 40)
        oled.show()
    print(line1, line2)

# --- Tool Functions ---
def get_device_info():
    mac = ubinascii.hexlify(network.WLAN(network.STA_IF).config('mac'),':').decode()
    return {
        "type": "device_info", "firmware_version": "8.0-TCP",
        "mac_address": mac.upper(),
    }

# --- TCP Server Logic ---
async def command_handler(reader, writer):
    addr = writer.get_extra_info('peername')
    print(f"Client connected from {addr}")
    display_status("CLIENT CONNECTED")
    try:
        while True:
            # Read data until a newline character
            data = await reader.readline()
            if not data:
                break
            
            message = data.decode().strip()
            print("Command received:", message)
            
            try:
                command_json = ujson.loads(message)
                cmd = command_json.get("command")
                
                # The script execution engine
                if cmd == "execute_script":
                    script_to_run = command_json.get("script")
                    if script_to_run:
                        print("--- Executing Script ---")
                        try:
                            # Note: exec() is powerful. In a production system,
                            # you would want to sandbox this.
                            exec(script_to_run)
                        except Exception as e:
                            print(f"Script Error: {e}")
                        print("--- Execution Finished ---")

            except Exception as e:
                print(f"Error processing command: {e}")

    except Exception as e:
        print(f"Connection error: {e}")
    finally:
        print("Client disconnected")
        writer.close()
        await writer.wait_closed()
        ip = network.WLAN(network.STA_IF).ifconfig()[0]
        display_status("READY", ip)

# --- Main Program Execution ---
async def main():
    display_status("DeZer0 Booting")
    
    sta_if = network.WLAN(network.STA_IF)
    if not sta_if.isconnected():
        display_status("Connecting to", WIFI_SSID)
        sta_if.active(True)
        sta_if.connect(WIFI_SSID, WIFI_PASSWORD)
        timeout = time.time() + 15
        while not sta_if.isconnected() and time.time() < timeout:
            await asyncio.sleep_ms(200)

    if not sta_if.isconnected():
        display_status("WIFI FAILED")
        return

    ip = sta_if.ifconfig()[0]
    display_status("READY", ip)
    print("Connected! IP Address:", ip)

    # Start a TCP server on port 8888
    server = await asyncio.start_server(command_handler, "0.0.0.0", 8888)
    print("TCP Server started on port 8888")
    await server.wait_closed()

print("Boot: DeZer0 FINAL TCP")
try:
    asyncio.run(main())
except OSError as e:
    if e.args[0] == 112: # EADDRINUSE
        print("Address in use, resetting...")
        machine.reset()
except Exception as e:
    print(f"Fatal Error: {e}")
