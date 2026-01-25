<!-- # gas_detector_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference. -->

# 🚨 IoT Smart Gas Detection System

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![ESP32](https://img.shields.io/badge/ESP32-Hardware-red)

A complete IoT solution for monitoring gas leakage in real-time. This project integrates an **ESP32** hardware module with a **Flutter** mobile application to provide instant push notifications and local alerts when hazardous gas levels are detected.

## 📋 Table of Contents
- [🚨 IoT Smart Gas Detection System](#-iot-smart-gas-detection-system)
  - [📋 Table of Contents](#-table-of-contents)
  - [🧐 Overview](#-overview)
  - [✨ Features](#-features)
    - [📱 Mobile App (Flutter)](#-mobile-app-flutter)
    - [🤖 Hardware (IoT)](#-hardware-iot)
  - [🛠 Hardware Requirements](#-hardware-requirements)
  - [💻 Tech Stack](#-tech-stack)
  - [🔌 Circuit Diagram](#-circuit-diagram)
  - [🚀 Getting Started](#-getting-started)
    - [1. Hardware Setup](#1-hardware-setup)
    - [2. App Setup](#2-app-setup)
  - [📸 Screenshots](#-screenshots)
  - [📄 License](#-license)

---

## 🧐 Overview

Safety is paramount. This system uses an **MQ-6 Gas Sensor** to detect LPG, butane, and propane gas leaks. When the sensor data exceeds a defined safety threshold:
1.  **Locally:** The active buzzer sounds an alarm, and the OLED display shows a "DANGER" warning.
2.  **Remotely:** The ESP32 communicates with **Firebase**, triggering a high-priority Push Notification to the Flutter app, alerting the user immediately, anywhere in the world.

---

## ✨ Features

### 📱 Mobile App (Flutter)
* **User Authentication:** Secure Sign Up and Login using Firebase Authentication.
* **Real-time Alerts:** Instant Push Notifications via Firebase Cloud Messaging (FCM) when gas is detected.
* **Live Monitoring:** View current gas status (Safe/Danger) within the app dashboard.
* **Cross-Platform:** Runs seamlessly on both Android and iOS.

### 🤖 Hardware (IoT)
* **Gas Sensing:** Continuous monitoring using the MQ-6 sensor.
* **Visual Output:** Real-time status display on an OLED screen display.
* **Audio Alert:** Loud buzzer activation for immediate local warning.
* **Wi-Fi Connectivity:** ESP32 connects directly to the internet to sync data.

---

## 🛠 Hardware Requirements

To build the physical device, you will need:
* **Microcontroller:** ESP32 Development Board (e.g., ESP32-WROOM-32)
* **Sensor:** MQ-6 Gas Sensor (LPG/Butane/Propane)
* **Display:** 0.96" I2C OLED Display (SSD1306)
* **Alarm:** Active Buzzer
* **Power:** 5V Power Supply or Micro USB cable
* **Misc:** Jumper wires, Breadboard

---

## 💻 Tech Stack

* **Mobile Framework:** Flutter (Dart)
* **Backend & Cloud:** Google Firebase
    * *Authentication* (Email/Password)
    * *Cloud Messaging* (Push Notifications)
    * *Realtime Database* (Sensor Data Sync)
* **Firmware:** C++ (Arduino IDE or PlatformIO)

---

## 🔌 Circuit Diagram

Connect the components to the ESP32 as follows:

| Component | ESP32 Pin | Note |
| :--- | :--- | :--- |
| **MQ-6 A0** | GPIO 34 | Analog Input |
| **Buzzer (+)** | GPIO 19 | Digital Output |
| **OLED SDA** | GPIO 21 | I2C Data |
| **OLED SCL** | GPIO 22 | I2C Clock |
| **VCC** | VIN / 5V | Power |
| **GND** | GND | Ground |

> **Note:** Ensure your MQ-6 sensor is pre-heated for at least 24 hours for accurate readings if it is brand new.

---

## 🚀 Getting Started

### 1. Hardware Setup
1.  Assemble the circuit according to the pinout above.
2.  Open the `firmware/` folder in Arduino IDE.
3.  Install the required libraries via Library Manager:
    * `FirebaseESP32`
    * `Adafruit_SSD1306`
    * `Adafruit_GFX`
4.  Update the following credentials in the code:
    ```cpp
    #define WIFI_SSID "YOUR_WIFI_NAME"
    #define WIFI_PASSWORD "YOUR_WIFI_PASS"
    #define FIREBASE_HOST "YOUR_PROJECT.firebaseio.com"
    #define FIREBASE_AUTH "YOUR_DATABASE_SECRET"
    ```
5.  Upload the code to the ESP32.

### 2. App Setup
1.  Clone this repository:
    ```bash
    git clone [https://github.com/bolaji2274/gas-detection-app.git](https://github.com/bolaji2274/gas-detection-app.git)
    ```
2.  Navigate to the app directory:
    ```bash
    cd app
    ```
3.  **Firebase Configuration:**
    * Create a new project in the [Firebase Console](https://console.firebase.google.com/).
    * Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
    * Place them in `android/app/` and `ios/Runner/` respectively.
    * Enable **Authentication** (Email/Password).
    * Enable **Cloud Messaging**.
4.  Install dependencies:
5.  
    ```bash
    flutter pub get
    ```
6.  Run the app:
    ```bash
    flutter run
    ```

---

## 📸 Screenshots

| Login Screen | Dashboard (Safe) | Alert Notification |
|:---:|:---:|:---:|
| <img src="assets/login_screenshot.png" width="200"> | <img src="assets/dashboard_screenshot.png" width="200"> | <img src="assets/alert_screenshot.png" width="200"> |

<!-- *(Make sure to upload images to an `assets` folder in your repo and update the paths above)* -->

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.