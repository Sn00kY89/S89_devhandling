# 🏎️ s89_devhandling (Advanced Real‑Time Handling Editor)

**s89_devhandling** is a professional, feature‑rich, and highly optimized handling editor for FiveM. It lets you tweak vehicle physics in real‑time, test performance with built‑in live telemetry, and instantly export a ready‑to‑use `handling.meta` configuration.

---

## ✨ Features

- **Real‑Time Adjustments** – Modify engine, brakes, traction, suspension, and other physics values on the fly while driving. Changes apply instantly.
- **Interactive Dynamic Charts** – Visualise tweaks instantly with beautiful Chart.js graphs:
  - Acceleration curves
  - Drag resistance over speed
  - Gear‑ratio steps
  - Brake‑bias split
  - Traction‑grip radar
  - Suspension stiffness indicators
- **Live Performance Telemetry** – Benchmark your tunes with recorded metrics:
  - 0‑100 km/h, 0‑150 km/h, 0‑200 km/h
  - ¼‑mile and ½‑mile drag times
  - Top‑speed tracking and gear monitoring
  - Real‑time performance graph while you drive
- **Simulated Physics Engine** – The UI automatically calculates theoretical top speed by comparing `fInitialDriveForce` against `fInitialDragCoeff`, indicating whether the vehicle is gear‑limited or drag‑limited.
- **Custom Parameter Limits** – Server admins can define `Min`/`Max` limits for any handling value via the UI. Limits are saved in `limits.json` and synced to all authorised players.
- **1‑Click XML Export** – Export a perfectly formatted `<Item type="CHandlingData">` block to your clipboard with a single click, ready to paste into `handling.meta`.
- **Multilingual Support** – Fully localised UI (English, Italian, Spanish, French, German, Portuguese). Language can be switched on the fly and is stored in the user's local storage.
- **Commercial‑Ready (Escrow Secure)** – Core calculation logic, telemetry loops and server‑side scripts are protected by FiveM Escrow. UI, `config.lua` and locale files remain open for customisation.

---

## 📦 Installation

1. Download the resource and place the `s89_devhandling` folder inside your server's `resources` directory.
2. Add the line `ensure s89_devhandling` (or the folder name you used) to your `server.cfg`.
3. Open `config.lua` to configure permissions:
   - By default access is controlled via a simple server‑side identifier check (license, steam ID, Ace permission, etc.). Adapt `Config.isAllowed` to match your framework (ESX, QBCore, Qbox, …).
4. Restart or start your server.

---

## 🎮 Usage

### Opening the Menu
- **Command**: `/handling` (configurable in `config.lua`).
- **Keybind**: Unbound by default; you can assign one in `config.lua`.

### Telemetry
1. Click the ⏱️ icon in the top‑right corner.
2. Choose a test duration (e.g., 30 s, 60 s).
3. Optionally enable auto‑reopen after the test finishes.
4. Accelerate – telemetry records the exact moment the vehicle starts moving.

### Exporting
- Click the 📋 icon in the top‑right corner to copy the formatted handling block to your clipboard.
- The script automatically converts sliders into the correct float, integer, or vector format for `handling.meta`.

---

## 🛠️ Configuration (`config.lua`)

The `config.lua` file is fully exposed and allows you to:
- Change the command name and keybind.
- Set the default language (`Config.Locale`).
- Modify base `Min`, `Max`, and `Step` values for every handling parameter slider.
- Add or remove individual handling properties from the menu.

---

## 🌐 Supported Frameworks

**100 % Standalone** – This resource does not depend on ESX, QBCore, Qbox, or any other framework. It works out‑of‑the‑box on any FiveM server.

---

## Support



For support, questions, or feature requests open a issue in the repository.


---

*Enjoy precise vehicle tuning without ever restarting your server!*
