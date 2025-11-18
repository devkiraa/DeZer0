# DeZer0 Web Flasher

## What is this?

The DeZer0 Web Flasher is a simple, browser-based tool for flashing the DeZer0 firmware onto an ESP32 device. It allows users to prepare their ESP32 for use with the DeZer0 companion app without needing to install any command-line tools or drivers.

## Why does this exist?

Getting started with a new hardware project can often be intimidating, especially for users who are not familiar with the command line or complex development environments. The primary goal of the Web Flasher is to **lower the barrier to entry** for new DeZer0 users.

By providing a tool that runs entirely in a web browser, we simplify the initial setup process to just a few clicks. This makes it significantly easier and faster for anyone to get their ESP32 device running the DeZer0 firmware.

## How to Use It

1.  **Connect your ESP32**: Plug your ESP32 device into your computer using a USB cable.
2.  **Enter Bootloader Mode**: Hold down the `BOOT` or `FLASH` button on your ESP32, and while holding it, press and release the `RESET` or `EN` button. You can then release the `BOOT` button. This puts the device in a state where it's ready to receive new firmware.
3.  **Open the Web Flasher**: Navigate to the web flasher URL in a compatible browser (like Google Chrome or Microsoft Edge).
4.  **Connect to the Device**: Click the "Connect" button and select the serial port corresponding to your ESP32 from the list that appears.
5.  **Flash the Firmware**: Once connected, click the "Flash" button. The tool will automatically flash both the MicroPython firmware and the DeZer0 application files.
6.  **Wait for Completion**: The log window will show the flashing progress. Once it's complete, you can disconnect the device and restart it. It is now ready to be used with the DeZer0 app!

## Technical Details

This application is built with [Next.js](https://nextjs.org/) and uses the [`esp-web-tools`](https://github.com/esphome/esp-web-tools) library, which leverages the [Web Serial API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Serial_API) to communicate with the ESP32 directly from the browser.
