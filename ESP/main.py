# main.py - Final, Stable Application Server

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

# --- Tool Functions ---
def get_device_info():
    mac = ubinascii.hexlify(network.WLAN(network.STA_IF).config('mac'),':').decode().upper()
    cpu_freq = machine.freq() // 1000000
    gc.collect()
    alloc = gc.mem_alloc()
    free = gc.mem_free()
    return {
        "type": "device_info", "firmware_version": "8.2-FINAL",
        "mac_address": mac, "cpu_freq": cpu_freq,
        "ram_used": alloc, "ram_total": alloc + free
    }

# --- TCP Server Logic ---
async def command_handler(reader, writer):
    addr = writer.get_extra_info('peername')
    print(f"Client connected from {addr}")
    display_status("CLIENT CONNECTED")
    
    buffer = b''
    try:
        while True:
            chunk = await reader.read(64)
            if not chunk: break
            
            buffer += chunk
            
            while b'\n' in buffer:
                line, _, buffer = buffer.partition(b'\n')
                message = line.decode().strip()
                print("Command received:", message)
                
                try:
                    command_json = ujson.loads(message)
                    cmd = command_json.get("command")
                    response = {}

                    if cmd == "get_device_info":
                        response = get_device_info()
                    
                    if response:
                        writer.write((ujson.dumps(response) + '\n').encode('utf-8'))
                        await writer.drain()
                        print("Sent response")

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