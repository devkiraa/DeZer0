# boot.py - Eye Animation Boot + Wi-Fi Connect

import machine
import network
import time

# --- WIFI CREDENTIALS ---
WIFI_SSID = "DeZer0"
WIFI_PASSWORD = "dev0whostpot"
# -------------------------

# --- OLED SETUP ---
i2c = machine.I2C(0, scl=machine.Pin(22), sda=machine.Pin(21))
try:
    from ssd1306 import SSD1306_I2C
    oled = SSD1306_I2C(128, 64, i2c)
except ImportError:
    oled = None

def eye_frame(opened=True):
    oled.fill(0)
    # Eye outline
    oled.rect(34, 22, 60, 20, 1)
    
    if opened:
        # Eye open pupil
        oled.fill_rect(60, 30, 8, 4, 1)
    else:
        # Eye closed - just a line
        oled.hline(34, 32, 60, 1)

    oled.show()

def eye_animation():
    if not oled:
        return

    # Eye blinks 3 times
    for _ in range(2):
        eye_frame(opened=True)
        time.sleep(0.4)
        eye_frame(opened=False)
        time.sleep(0.3)

    # Final open frame + text
    eye_frame(opened=True)
    oled.text("DeZer0 Boot", 28, 48)
    oled.show()
    time.sleep(1)

def update_oled(line1, line2=""):
    if oled:
        oled.fill(0)
        oled.text(line1[:16], 0, 24)
        oled.text(line2[:16], 0, 40)
        oled.show()

# --- BOOT START ---
print("Executing boot.py...")
eye_animation()

sta_if = network.WLAN(network.STA_IF)

if not sta_if.isconnected():
    print(f"Connecting to network '{WIFI_SSID}'...")
    sta_if.active(True)
    sta_if.connect(WIFI_SSID, WIFI_PASSWORD)

    update_oled("Connecting to", WIFI_SSID)

    max_wait = 15
    while max_wait > 0 and not sta_if.isconnected():
        max_wait -= 1
        time.sleep(1)

if sta_if.isconnected():
    ip = sta_if.ifconfig()[0]
    print(f"Connected. IP Address: {ip}")
    update_oled("Connected", ip)
else:
    print("Wi-Fi connection failed.")
    update_oled("Wi-Fi Failed", ":(")

# End of boot.py

