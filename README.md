<p align="center">
  <a>
    <img src="logo.svg" alt='Probe Tech Control logo' height="152">
    <h1 align="center">Probe Tech Control</h1>
  </a>
</p>
<p align="center">
  A lightweight, responsive web user interface for Klipper, designed for high-performance 3D printer control and monitoring.
</p>

## ✨ Features

- **Responsive Web Interface:** Optimized for desktops, tablets, and mobile devices.
- **Advanced Manager:** Comprehensive `install.sh` for multi-instance management.
- **Vibrant Design:** A premium, dark-mode focused experience with smooth micro-animations.
- **Full Klipper Support:** Integrated bed mesh visualisation, G-code viewing, and powerful macro management.
- **Probe Tech Integration:** Optimized for advanced sensing and automated hardware probes.
- **Multi-Instance Support:** Easily manage multiple 3D printers from a single dashboard.

## 🚀 Installation Guide

Choose the method that best suits your needs:

### Option 1: Quick Install (Recommended)
Run this single command to download and install automatically:
```bash
wget -O - https://raw.githubusercontent.com/PravarHegde/probe-tech-control/master/bootstrap.sh | bash
```
*Supports seamless auto-installation on fresh systems.*

### Option 2: Manual / Developer Install
If you prefer to clone the repository manually:
```bash
git clone https://github.com/PravarHegde/probe-tech-control ptc
cd ptc
chmod +x install.sh
./install.sh
```

### Option 3: Fresh Re-Install (Troubleshooting)
If you have a broken installation and want to start fresh (WARNING: Deletes existing `~/ptc` folder):
```bash
cd ~ && rm -rf ptc && git clone https://github.com/PravarHegde/probe-tech-control ptc && cd ptc && chmod +x install.sh && ./install.sh
```

### Option 2: Manual Setup
For detailed manual configuration, requirements, and advanced setups, please refer to the:
👉 **[INSTALL.md](INSTALL.md)**

## 🛠 Help and Support

If you find a bug or have a feature request, please create an [Issue](https://github.com/PravarHegde/probe-tech-control/issues).

---
*Probe Tech Control is a branded fork of Probe Tech Control. Special thanks to the original authors and the Klipper community.*
