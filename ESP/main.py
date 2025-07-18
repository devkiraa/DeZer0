# main.py - Final, Return-Based Runtime Engine

import uasyncio as asyncio
import network
import gc
import ujson
import machine
import esp32
import ubinascii

# --- OLED and Helper Functions ---
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

# --- Built-in Command Function ---
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
    
    try:
        while True:
            data = await reader.readline()
            if not data: break
            
            message = data.decode().strip()
            if not message: continue
            
            try:
                command_json = ujson.loads(message)
                cmd = command_json.get("command")

                if cmd == "get_device_info":
                    response = get_device_info()
                    writer.write((ujson.dumps(response) + '\n').encode('utf-8'))
                    await writer.drain()
                    print("Sent device info")

                elif cmd == "execute_script":
                    script_base64 = command_json.get("script", "")
                    output = ""
                    try:
                        script_content = ubinascii.a2b_base64(script_base64).decode('utf-8')
                        
                        # Create a scope for the script to run in
                        script_scope = {}
                        # Execute the script to define its functions
                        exec(script_content, script_scope)
                        
                        # The script MUST have a 'run_tool()' function
                        if 'run_tool' in script_scope:
                            # Execute the function and capture its return value
                            output = script_scope['run_tool']() 
                        else:
                            output = "Script Error: No 'run_tool()' function found."
                            
                    except Exception as e:
                        output = f"Script Error: {e}"
                    
                    # Send the entire captured output back to the app
                    writer.write((output + '\n').encode('utf-8'))
                    await writer.drain()
                    print(f"Script execution finished. Sent {len(output)} bytes.")

            except Exception as e:
                print(f"Error processing command: {e}")

    except Exception as e:
        print(f"Connection error: {e}")
    finally:
        print("Client disconnected")
        writer.close(); await writer.wait_closed()
        ip = network.WLAN(network.STA_IF).ifconfig()[0]
        display_status("READY", ip)

async def main():
    ip = network.WLAN(network.STA_IF).ifconfig()[0]
    print(f"Server starting on {ip}:8888")
    display_status("READY", ip)
    gc.collect()
    
    server = await asyncio.start_server(command_handler, "0.0.0.0", 8888)
    print("Server started successfully! Waiting for connections.")
    
    while True:
        await asyncio.sleep(10)

# --- Main entry point ---
if network.WLAN(network.STA_IF).isconnected():
    try:
        asyncio.run(main())
    except Exception as e:
        print(f"Error in main: {e}")
else:
    print("Wi-Fi not connected. Halting.")
