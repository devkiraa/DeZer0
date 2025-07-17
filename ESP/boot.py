# boot.py - Final version with a sandboxed script execution engine

import machine
import time
import uasyncio as asyncio
import ujson
import esp32
import network
import os
import ubinascii

# --- WIFI CREDENTIALS ---
WIFI_SSID = "KIRANFI"
WIFI_PASSWORD = "m1670529"
# -------------------------

# --- OLED Display Setup ---
i2c = machine.I2C(0, scl=machine.Pin(22), sda=machine.Pin(21))
try:
    from ssd1306 import SSD1306_I2C
    oled = SSD1306_I2C(128, 64, i2c)
except ImportError: oled = None

def display_status(line1, line2=""):
    if oled:
        oled.fill(0)
        oled.text(line1[:16], 2, 28)
        if line2: oled.text(line2[:16], 2, 40)
        oled.show()
    print(line1, line2)

# --- TCP Server Logic ---
async def command_handler(reader, writer):
    addr = writer.get_extra_info('peername')
    print(f"Client connected from {addr}")
    display_status("CLIENT CONNECTED")
    
    async def send_log_to_client(log_message):
        try:
            writer.write((str(log_message) + '\n').encode('utf-8'))
            await writer.drain()
        except Exception as e:
            print(f"Failed to send log: {e}")

    try:
        while True:
            data = await reader.readline()
            if not data: break
            
            message = data.decode().strip()
            print("Command received (first 50 chars):", message[:50])
            
            try:
                command_json = ujson.loads(message)
                cmd = command_json.get("command")
                
                # --- SCRIPT EXECUTION ENGINE ---
                if cmd == "execute_script":
                    script_to_run = command_json.get("script")
                    if script_to_run:
                        # FIX: Create a dictionary of all the modules and functions
                        # that we want to make available to the scripts.
                        script_globals = {
                            "send_log": send_log_to_client,
                            "ujson": ujson,
                            "network": network,
                            "time": time,
                            "machine": machine,
                            "esp32": esp32,
                            "ubinascii": ubinascii,
                            "__name__": "__main__", # Makes scripts behave like they are the main file
                        }
                        
                        await send_log_to_client("--- Executing Script ---")
                        try:
                            # Decode the script from Base64
                            script_code = ubinascii.a2b_base64(script_to_run).decode()
                            # Execute the script within the 'sandbox' of our globals
                            exec(script_code, script_globals)
                        except Exception as e:
                            await send_log_to_client(f"Script Error: {e}")
                        
                        await send_log_to_client("--- Execution Finished ---")
            except Exception as e:
                print(f"Error processing command: {e}")

    except Exception as e:
        print(f"Connection error: {e}")
    finally:
        print("Client disconnected")
        writer.close(); await writer.wait_closed()
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
        display_status("WIFI FAILED"); return

    ip = sta_if.ifconfig()[0]
    display_status("READY", ip)
    print("Connected! IP Address:", ip)

    server = await asyncio.start_server(command_handler, "0.0.0.0", 8888)
    print("TCP Server started on port 8888")
    await server.wait_closed()

print("Boot: DeZer0 FINAL TCP")
try:
    asyncio.run(main())
except OSError as e:
    if e.args[0] == 112: machine.reset()
except Exception as e:
    print(f"Fatal Error: {e}")
