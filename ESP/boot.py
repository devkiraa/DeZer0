# boot.py — with WebSocket + TCP‑JSON fallback

import machine, time, uasyncio as asyncio, ujson, esp32, network
import usocket as socket, uhashlib as hashlib, ubinascii, ure
from ssd1306 import SSD1306_I2C  # assumed present; wrap in try/except if needed

# — Wi‑Fi credentials —
WIFI_SSID = "KIRANFI"
WIFI_PASSWORD = "m1670529"

# — OLED setup (optional) —
i2c = machine.I2C(0, scl=machine.Pin(22), sda=machine.Pin(21))
try:
    oled = SSD1306_I2C(128, 64, i2c)
except ImportError:
    oled = None

def display_status(line1, line2=""):
    if oled:
        oled.fill(0)
        oled.text(line1[:16], 0, 20)
        if line2: oled.text(line2[:16], 0, 35)
        oled.show()
    print(line1, line2)

# — Utility commands —
def get_device_info():
    mac = ubinascii.hexlify(network.WLAN(network.STA_IF).config('mac'),':').decode().upper()
    cpu_mhz = machine.freq() // 1_000_000
    used, free = esp32.heap_info()
    return {
        "type":"device_info", "firmware_version":"7.0-FINAL", "build_date":"2025-07-16",
        "mac_address":mac, "cpu_freq":cpu_mhz,
        "ram_used":used, "ram_total":used+free,
        "flash_total":4*1024*1024
    }

def scan_wifi():
    sta = network.WLAN(network.STA_IF)
    nets = sta.scan()
    return {
        "type":"wifi_scan_results",
        "networks":[{"ssid":s.decode(), "rssi":r} for s, *_ ,r,_ in nets[:5]]
    }

# — Connection handler with WebSocket + TCP‑JSON fallback —
async def handle_websocket(reader, writer):
    display_status("CLIENT CONNECTED")
    print("Client connected, peeking for WebSocket handshake…")

    # read first 1KB or until newline
    initial = await reader.read(1024)
    # try WebSocket handshake
    match = ure.search(b"Sec-WebSocket-Key: (.*)\r\n", initial)
    if match:
        # — WebSocket path (unchanged) —
        key = match.group(1)
        magic = b"258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        resp = ubinascii.b2a_base64(hashlib.sha1(key + magic).digest()).strip()
        hdr = (b"HTTP/1.1 101 Switching Protocols\r\n"
               b"Upgrade: websocket\r\n"
               b"Connection: Upgrade\r\n"
               b"Sec-WebSocket-Accept: " + resp + b"\r\n\r\n")
        writer.write(hdr)
        await writer.drain()
        print("WebSocket handshake complete.")

        # process frames
        while True:
            hdr = await reader.readexactly(2)
            opcode = hdr[0] & 0x0F
            if opcode == 0x8: break  # close frame
            length = hdr[1] & 0x7F
            if length == 126:
                length = int.from_bytes(await reader.readexactly(2), "big")
            mask = await reader.readexactly(4)
            data = await reader.readexactly(length)
            msg = bytes(b ^ mask[i%4] for i, b in enumerate(data)).decode()
            cmd = ujson.loads(msg).get("command")
            resp_obj = {}
            if cmd == "get_device_info": resp_obj = get_device_info()
            elif cmd == "scan_wifi":      resp_obj = scan_wifi()
            # send back
            out = ujson.dumps(resp_obj)
            frame = bytearray([0x81])
            L = len(out)
            if L < 126: frame.append(L)
            else:
                frame.append(126); frame.extend(L.to_bytes(2, "big"))
            writer.write(frame + out.encode())
            await writer.drain()

    else:
        # — TCP JSON fallback —
        print("No Sec‑WebSocket‑Key found; entering TCP‑JSON mode.")
        display_status("TCP JSON MODE")
        # process the remainder of 'initial' plus future lines
        buf = initial
        while True:
            # accumulate until newline
            if b"\n" not in buf:
                more = await reader.read(256)
                if not more:
                    break
                buf += more
            line, _, buf = buf.partition(b"\n")
            try:
                data = ujson.loads(line.decode().strip())
            except:
                continue
            cmd = data.get("command")
            resp_obj = {}
            if cmd == "get_device_info": resp_obj = get_device_info()
            elif cmd == "scan_wifi":      resp_obj = scan_wifi()
            # write back as JSON + newline
            writer.write(ujson.dumps(resp_obj).encode() + b"\n")
            await writer.drain()

    # teardown
    print("Client disconnected.")
    writer.close()
    await writer.wait_closed()
    try:
        ip = network.WLAN(network.STA_IF).ifconfig()[0]
        display_status("READY", ip)
    except:
        display_status("DISCONNECTED")

# — Main entry point —
async def main():
    display_status("DeZer0 Booting")
    sta = network.WLAN(network.STA_IF)
    if not sta.isconnected():
        display_status("Connecting to", WIFI_SSID)
        sta.active(True)
        sta.connect(WIFI_SSID, WIFI_PASSWORD)
        deadline = time.time() + 15
        while not sta.isconnected() and time.time() < deadline:
            await asyncio.sleep_ms(100)
    if not sta.isconnected():
        display_status("WIFI FAILED"); return
    ip = sta.ifconfig()[0]
    display_status("READY", ip)
    print("IP:", ip)

    server = await asyncio.start_server(handle_websocket, "0.0.0.0", 80)
    await server.wait_closed()

print("Boot: DeZer0 FINAL")
try:
    asyncio.run(main())
except OSError as e:
    if e.args[0] == 112:  # EADDRINUSE
        machine.reset()
    else:
        print("Fatal OSError:", e)
except Exception as e:
    print("Fatal error:", e)

