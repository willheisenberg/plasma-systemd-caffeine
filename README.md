# ☕ Plasma Caffeine (systemd-based)

A **minimal, Wayland-native replacement for caffeine-ng** using:

- `systemd-inhibit`
- KDE Plasma
- the **Command Output** widget

No Python.  
No tray hacks.  
No X11 dependencies.

---

## ✨ Features

- ✅ Works on **Wayland**
- ✅ Plasma 6 compatible
- ✅ systemd-native (future-proof)
- ✅ Zero background services
- ✅ Click-to-toggle
- ✅ Visual state via icon

---

## 🔧 How it works

- A background `systemd-inhibit` process blocks idle/sleep
- A PID file tracks state
- Plasma periodically runs a **status script**
- Clicking the widget toggles inhibit on/off

This avoids:
- deprecated X11 APIs
- Python ABI breakage
- broken tray icons

---

## 📦 Installation

```bash
git clone https://github.com/YOURNAME/plasma-caffeine-widget.git
cd plasma-caffeine-widget
./install.sh
