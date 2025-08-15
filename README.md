# DeZer0

Welcome to DeZer0, a platform forESP32 devices that allows you to run various scripts and tools directly from a companion app. This repository contains all the necessary files for the DeZer0 companion app, the ESP32 firmware, and the community-contributed tools.

## About The Project

DeZer0 is a comprehensive platform designed for interacting with ESP32 devices. It features a Flutter-based companion app that can connect to the ESP32 via Wi-Fi and execute various tools and scripts. The platform is designed to be easily extensible, allowing users to create and share their own tools.

### Features

  * **Companion App**: A cross-platform application built with Flutter that allows you to manage and interact with your DeZer0 device.
  * **Extensible Tool System**: Easily create and share your own tools for the DeZer0 platform.
  * **Wi-Fi Connectivity**: The companion app connects to the ESP32 device over Wi-Fi, allowing for remote control and data transfer.
  * **Real-time Console**: View the output of your scripts in real-time within the companion app.
  * **Tools Marketplace**: Browse and install new tools from the official DeZer0 Community Tools repository.

## Getting Started

To get started with DeZer0, you will need to flash the firmware onto your ESP32 device and install the companion app on your mobile device or computer.

### Prerequisites

  * An ESP32 device
  * A mobile device or computer to run the companion app
  * The appropriate tools for flashing the ESP32 firmware

### Installation

1.  Clone the repository:
    ```sh
    git clone https://github.com/devkiraa/DeZer0.git
    ```
2.  Flash the firmware located in the `DeZer0/ESP` directory onto your ESP32 device.
3.  Build and install the companion app from the `DeZer0/dezero_app` directory on your desired platform (iOS, Android, etc.).

## How to Use

1.  Power on your ESP32 device.
2.  Connect to the Wi-Fi network that the ESP32 is hosting.
3.  Launch the DeZer0 companion app.
4.  Navigate to the "Device" screen and connect to your ESP32.
5.  Once connected, you can browse and install tools from the "Tools" screen or run already installed tools from the "Apps" screen.

## File Structure

The repository is organized into the following directories:

  * `DeZer0/dezero_app`: Contains the source code for the Flutter companion app.
  * `DeZer0/ESP`: Contains the MicroPython firmware for the ESP32 device.
  * `DeZer0 Tools`: Contains the community-contributed tools, each in its own subdirectory.

Each tool in the `DeZer0 Tools` directory has a `manifest.json` file that describes the tool and a Python script that is executed on the ESP32.
