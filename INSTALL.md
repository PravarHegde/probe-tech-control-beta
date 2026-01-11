# Installation Guide - Probe Tech Control

This guide provides detailed instructions for installing Probe Tech Control (PTC) manually or using the automated installer.

## Prerequisites

- A Raspberry Pi or Linux server (Ubuntu 22.04+ recommended).
- Network access.

## Option 1: Automated Installation (Recommended)

The easiest way to install PTC, Moonraker, and Klipper is using our advanced manager script:

```bash
git clone https://github.com/PravarHegde/probe-tech-control ptc
cd ptc
chmod +x install.sh
./install.sh
```

Choose **Option 1 (Auto-Install All)** to set up a complete stack.

## Option 2: Manual Installation

If you prefer to install components manually, follow these steps:

### 1. Install Klipper
```bash
git clone https://github.com/Klipper3d/klipper.git
./klipper/scripts/install-ubuntu-22.04.sh # Or relevant script for your OS
```

### 2. Install Moonraker
```bash
git clone https://github.com/Arksine/moonraker.git
./moonraker/scripts/install-moonraker.sh
```

### 3. Deploy Probe Tech Control Web Interface
1. Download the latest `probe-tech-control.zip` from the [releases](https://github.com/PravarHegde/probe-tech-control/releases).
2. Extract it to `~/probe-tech-control`.
3. Configure your web server (e.g., Nginx or use our Python-based service).

### 4. Link Configuration
Add the following to your `printer.cfg`:
```
[include probe_tech.cfg]
```

## Systemd Service

We provide a lightweight Python web server service for PTC.
1. Copy `probe-tech.service` to `/etc/systemd/system/`.
2. Edit the service to match your user and paths.
3. Run `sudo systemctl enable --now probe-tech`.

## Configuration

The web interface configuration is stored in `config.json` inside the web root. By default, it looks for Moonraker on **port 7125**.
