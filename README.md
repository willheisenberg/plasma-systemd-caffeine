# ☕ Plasma Caffeine (systemd)

A **native KDE Plasma 6 widget** that prevents your system from sleeping or blanking the screen — like GNOME's Caffeine extension, but built for Plasma with `systemd-inhibit`.

No Python. No tray hacks. No X11 dependencies. Fully Wayland-native.

---

## ✨ Features

- ☕ **Click-to-toggle** — left-click the coffee cup icon to inhibit/resume system sleep
- ⏱️ **Countdown timers** — right-click for timed activation (5 min, 15 min, 30 min, 1 hour, 2 hours)
- 🔄 **Auto-inhibit apps** — configure apps (e.g. `vlc`, `mpv`, `steam`) that automatically activate Caffeine when running
- 🚫 **Manual override** — temporarily force-deactivate Caffeine even when an auto-inhibit app is running by clicking the cup. It resumes auto-inhibition once the app is closed.
- 🔒 **Lock-screen pause** — automatically pauses inhibit when you lock your screen so monitors can still sleep, resumes on unlock
- 🎨 **Theme-adaptive icons** — symbolic SVG icons that match your Plasma color scheme (light & dark)
- 🔔 **Desktop notifications** — get notified when Caffeine activates or deactivates
- ⚙️ **systemd-native** — uses `systemd-inhibit` directly, no deprecated APIs

---

## 📸 How it works

```
┌──────────────────────────────────────────────────┐
│  Panel: [☕]  ← Coffee cup icon (theme-colored)  │
│                                                  │
│  Left-click  → Toggle caffeine on/off            │
│  Right-click → Timer menu (5m / 15m / ... / ∞)   │
│                                                  │
│  Widget Settings → Configure auto-inhibit apps   │
└──────────────────────────────────────────────────┘
```

### Icon states

| State | Icon | Description |
|-------|------|-------------|
| **OFF** | Empty cup | System sleep enabled |
| **ON** | Steaming cup | System sleep inhibited |
| **Paused** | Steaming cup (dimmed) | Screen locked, inhibit temporarily paused |

---

## 🔧 Architecture

```
main.qml (Plasma widget UI)
    │
    ├── caffeine-toggle.sh    — Toggles manual state on/off
    ├── caffeine-status.sh    — Polls state, manages systemd-inhibit process
    └── caffeine-lock-listener.sh — Monitors screen lock via D-Bus
```

- **caffeine-toggle.sh** creates/removes a state file to track manual activation
- **caffeine-status.sh** checks manual state + running apps, starts/stops `systemd-inhibit` accordingly
- **caffeine-lock-listener.sh** watches `org.freedesktop.ScreenSaver.ActiveChanged` to pause/resume on lock
- The QML widget polls `caffeine-status.sh` every 5 seconds and updates the icon

---

## 📦 Installation

```bash
git clone https://github.com/tesla/plasma-systemd-caffeine.git
cd plasma-systemd-caffeine
./install.sh
```

The installer:
1. Installs helper scripts to `~/.local/bin/`
2. Installs the Plasma widget via `kpackagetool6`
3. Provides instructions to add the widget to your panel

### After installation

1. Right-click your panel → **Add Widgets...** (or **Edit Mode** → **Add Widgets**)
2. Search for **"Caffeine (systemd)"** and drag it into your panel
3. Click the coffee cup icon to toggle!

### Optional: Restart Plasma

If the widget doesn't appear in the widget list:
```bash
systemctl --user restart plasma-plasmashell.service
```

---

## 🗑️ Uninstallation

```bash
./uninstall.sh
```

This removes the widget, all helper scripts, config files, and runtime state.

---

## ⚙️ Configuration

Right-click the widget in your panel → **Configure Caffeine (systemd)...**

### Auto-inhibit apps

Enter space-separated process names. Caffeine will automatically activate when any of these processes is running:

```
vlc mpv steam obs
```

> **Tip:** Use `pgrep -l <name>` to find the exact process name of an application.

### Icon preference

Toggle **"Use bundled Caffeine icons instead of system theme icons"** to choose between:
- **Disabled (Default):** Uses the icons provided by your current active system/panel icon theme (e.g. `Kora`, `Breeze`).
- **Enabled:** Forces the use of the original, bundled GNOME Caffeine coffee cup icons.

---

## 🧰 Requirements

- **KDE Plasma 6** (Wayland or X11)
- `systemd` (for `systemd-inhibit`)
- `dbus-monitor` (for screen lock detection, usually pre-installed)
- `notify-send` (for desktop notifications, usually pre-installed)

---

## 📜 License

GPL-2.0-or-later

The coffee cup icons are derived from the [GNOME Caffeine extension](https://github.com/eonpatapon/gnome-shell-extension-caffeine) (GPLv2).
