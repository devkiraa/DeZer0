# boot.py - Final, Complete, Return-Based Runtime

import machine
import time
import uasyncio as asyncio
import ujson
import esp32
import network
import gc
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

# --- Built-in Tool Function ---
def get_device_info():
    mac = ubinascii.hexlify(network.WLAN(network.STA_IF).config('mac'),':').decode().upper()
    cpu_freq = machine.freq() // 1000000
    gc.collect()
    alloc = gc.mem_alloc()
    free = gc.mem_free()
    return {
        "type": "device_info", "firmware_version": "9.0-FINAL",
        "mac_address": mac, "cpu_freq": cpu_freq,
        "ram_used": alloc, "ram_total": alloc + free
    }

# --- TCP Server Logic ---
async def command_handler(reader, writer):
    addr = writer.get_extra_info('peername')
    print(f"Client connected from {addr}")
    display_status("CLIENT CONNECTED")
    
    async def send_response(data_to_send):
        try:
            writer.write((str(data_to_send) + '\n').encode('utf-8'))
            await writer.drain()
        except Exception as e:
            print(f"Failed to send response: {e}")

    try:
        while True:
            data = await reader.readline()
            if not data: break
            
            message = data.decode().strip()
            
            try:
                command_json = ujson.loads(message)
                cmd = command_json.get("command")
                
                # --- COMMAND INTERPRETER ---
                if cmd == "get_device_info":
                    response = get_device_info()
                    await send_response(ujson.dumps(response))

                elif cmd == "execute_script":
                    script_b64 = command_json.get("script")
                    if script_b64:
                        await send_response("--- Executing Script ---")
                        output = ""
                        try:
                            script_code = ubinascii.a2b_base64(script_b64).decode()
                            script_scope = {}
                            exec(script_code, script_scope)
                            
                            if 'run_tool' in script_scope:
                                output = script_scope['run_tool']()
                            else:
                                output = "Script Error: No 'run_tool()' function found."
                                
                        except Exception as e:
                            output = f"Script Error: {e}"
                        
                        await send_response(output)
                        await send_response("--- Execution Finished ---")

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

print("Boot: DeZer0 FINAL")
try:
    asyncio.run(main())
except OSError as e:
    if e.args[0] == 112: machine.reset()