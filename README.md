# Printers

My printer configuration as a nixos flake.

## Builds

### Voron Blue

A 350 Voron 2.4 build with the following:

- LDO Leviathan 1.3
- LDO Leviathan Extension board
- LDO AWD kit
- 8x LDO 42STH48-2504AH
- BTT EBB36 Gen2
- Cartographer probe v3
- BTT HBB
- Mean Well UHP 24V and 48V PSU
- BTT HDMI 5 touch screen
- A4T Toolhead with a WWG2 extruder
- BTT SFS V2.0
- Rapido UHF Plus
- Nevermore V6
- Raspberry PI 5
- Logitech c920 HD Pro Webcam

## Features

### Webcam Streaming

The configuration includes [camera-streamer](https://github.com/ayufan/camera-streamer) for high-performance, low-latency webcam streaming with hardware acceleration.

**Configuration:**
- **Camera**: Logitech c920 HD Pro Webcam
- **Format**: MJPEG (hardware encoded by the camera)
- **Resolution**: 1920x1080 @ 30 FPS
- **Idle FPS**: 5 FPS (to reduce CPU usage when not actively monitoring)

**Features:**
- Hardware MJPEG encoding offloaded to the camera
- Low CPU usage on the Raspberry Pi
- Full integration with Moonraker and Mainsail
- High framerate streaming for monitoring prints

**Access:**
- Stream URL: `http://<printer-hostname>.lan/webcam/stream`
- Snapshot URL: `http://<printer-hostname>.lan/webcam/snapshot`
- Mainsail automatically configures the webcam integration
