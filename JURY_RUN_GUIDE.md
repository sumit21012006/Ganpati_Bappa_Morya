# 🎯 Complete Jury Demonstration & Execution Guide
### Legal Metrology Automated Enforcement Core Engine (SIH 2026)

This document provides exact, copy-paste commands to run every component of the system:
- **Database** (PostgreSQL / SQLite fallback)
- **Backend Core API** (FastAPI / Uvicorn on Port 8000)
- **Web Portal** (Next.js on Port 3000)
- **Mobile App**:
  - **Case 1: Running with USB** (Physical Phone + USB Debugging)
  - **Case 2: Running completely Wirelessly** (Physical Phone + Standalone APK, NO USB)
  - **Case 3: Running WITHOUT any Mobile Phone** (Windows Desktop / Chrome / Emulator)

---

## ⚡ Quick Reference Matrix

| Component | Default Port / URL | Working Directory | Primary Run Command |
| :--- | :--- | :--- | :--- |
| **PostgreSQL Database** | `localhost:5432` | Root / Service | `Start-Service postgresql*` or Docker |
| **FastAPI Backend** | `http://localhost:8000` | `e:\SIH_2026\Stay_Calm` | `python -m uvicorn backend.server:app --host 0.0.0.0 --port 8000 --reload` |
| **Next.js Web Portal** | `http://localhost:3000` | `e:\SIH_2026\Stay_Calm\sih-web` | `npm run dev` |
| **Mobile (USB Debugging)** | Connected Device | `e:\SIH_2026\Stay_Calm\mobile_app` | `adb reverse tcp:8000 tcp:8000` then `flutter run` |
| **Mobile (Wireless APK)** | Standalone APK on Phone | `e:\SIH_2026\Stay_Calm\mobile_app` | `flutter build apk --debug --dart-define=API_BASE_URL=http://<HOTSPOT_IP>:8000/api/v1` |
| **Mobile (NO PHONE / PC)** | Windows Native Window | `e:\SIH_2026\Stay_Calm\mobile_app` | `flutter run -d windows` |

---

## 1. 🗄️ Database Setup & Commands

### Option A: Local Windows PostgreSQL Service (Active Setup)
The backend is configured to connect to PostgreSQL at `postgresql://postgres:Vit%402024@localhost:5432/legal_metrology`.

- **Check if PostgreSQL is running:**
  ```powershell
  Get-Service -Name postgres*
  ```
- **Start PostgreSQL if stopped:**
  ```powershell
  Start-Service postgresql-x64-16
  # (or use services.msc and start "postgresql-x64-XX")
  ```

### Option B: Automatic SQLite Fallback (Zero Setup Needed)
If PostgreSQL is not running or fails during presentation, the backend **automatically falls back to SQLite** (`legal_metrology.db`). You do not need to do anything; the backend handles this transparently!

---

## 2. ⚙️ Backend Core (FastAPI / Python)

The backend powers the OCR Engine, Legal Metrology Rule Engine, Notice Generator, and REST API.

### Run Command:
Open a new PowerShell terminal:
```powershell
cd e:\SIH_2026\Stay_Calm

# If you use a python virtual environment:
# .\venv\Scripts\activate

# Run Uvicorn server bound to 0.0.0.0 so external phones can reach it:
python -m uvicorn backend.server:app --host 0.0.0.0 --port 8000 --reload
```

### Verification:
Open your browser and verify:
- Health Check: `http://localhost:8000/api/v1/health` (Should return `{"status":"healthy"}`)
- Swagger API Docs: `http://localhost:8000/docs`

---

## 3. 🌐 Web Portal (Next.js / Controller & Business Dashboard)

Open a second PowerShell terminal:
```powershell
cd e:\SIH_2026\Stay_Calm\sih-web

# Run Next.js Development Server:
npm run dev
```

### Access URLs:
- **Local Browser:** `http://localhost:3000`
- **Network Access:** `http://<YOUR_LAPTOP_IP>:3000`

---

## 4. 📱 Mobile App — Scenario 1: Running WITH USB (USB Debugging)

Use this when your physical Android phone is connected to your laptop via a USB cable.

### Step 1: Enable USB Debugging on Phone
1. Go to **Settings > About Phone** -> Tap **Build Number** 7 times to enable Developer Mode.
2. Go to **Developer Options** -> Turn **ON** `USB Debugging`.
3. Plug in the USB cable and tap **Allow USB Debugging** on the phone prompt.

### Step 2: The Magic Command (ADB Reverse Port Forwarding)
Run this command in PowerShell. It routes port 8000 from the phone directly into your laptop over the USB cable, meaning `localhost:8000` works on the phone!
```powershell
adb reverse tcp:8000 tcp:8000
```

### Step 3: Check Connected Device & Run
```powershell
cd e:\SIH_2026\Stay_Calm\mobile_app

# Check your device is detected:
flutter devices

# Run the app directly to your phone:
flutter run
```
*(If multiple devices appear, specify the ID: `flutter run -d <DEVICE_ID>` e.g., `flutter run -d a8f57b0`)*

---

## 5. 📡 Mobile App — Scenario 2: Running WITHOUT USB (Completely Wireless)

Use this to hold your phone freely in your hand in front of the jury with **zero cables attached**.

### Step 1: Personal Mobile Hotspot (Crucial)
1. Turn ON **Mobile Hotspot** on your phone (or teammate's phone).
2. Connect your **Laptop** to that same hotspot. *(Do not use college/hall Wi-Fi, as public networks block device-to-device communication).*
3. Find your Laptop's Hotspot IP in PowerShell:
   ```powershell
   ipconfig
   ```
   Look for `Wireless LAN adapter Wi-Fi` -> **IPv4 Address** (e.g. `192.168.43.150`).

### Step 2: Test Laptop Reachability from Phone
Open Google Chrome on your phone and browse to:
```text
http://192.168.43.150:8000/api/v1/health
```
If you see `{"status":"healthy"}`, your phone and laptop are talking wirelessly!

### Step 3: Build & Install Standalone APK
Build the debug APK embedded with your hotspot IP:
```powershell
cd e:\SIH_2026\Stay_Calm\mobile_app

flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.43.150:8000/api/v1
```

### Step 4: Transfer APK & Install
1. Locate the built APK:
   `e:\SIH_2026\Stay_Calm\mobile_app\build\app\outputs\flutter-apk\app-debug.apk`
2. Send this APK file to your phone via WhatsApp Web, Google Drive, Bluetooth, or quick one-time file copy.
3. Tap the file on the phone to install.
4. **Disconnect USB completely!** Launch the installed "Legal Metrology" app. It will seamlessly talk to your laptop backend over Wi-Fi.

---

## 6. 💻 Mobile App — Scenario 3: Running WITHOUT ANY MOBILE (No Phone Needed)

If your phone battery dies or you do not have a physical mobile phone at the presentation table, you can run the mobile inspector app **directly on your laptop screen**!

### Method A: Native Windows Desktop App (⭐ Recommended & Fastest)
Flutter can run the mobile inspector app natively as a high-performance Windows desktop program:
```powershell
cd e:\SIH_2026\Stay_Calm\mobile_app

# Run on Windows:
flutter run -d windows
```
- **Why it's awesome:** It opens in a neat Windows window right next to your Chrome browser.
- Uses `http://127.0.0.1:8000/api/v1` automatically.
- No phone, no cables, no emulator overhead.

### Method B: Chrome Web Browser (Zero Installation)
Run the inspector UI directly in Google Chrome:
```powershell
cd e:\SIH_2026\Stay_Calm\mobile_app

flutter run -d chrome --web-port 5000
```
- Opens at `http://localhost:5000`. You can resize the browser window to mobile size using Chrome DevTools (`Ctrl + Shift + M`).

### Method C: Android Studio Emulator
If you have an Android Virtual Device (AVD) configured:
```powershell
cd e:\SIH_2026\Stay_Calm\mobile_app

# Start on Android Emulator:
# (Android emulator maps laptop localhost to 10.0.2.2)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

---

## 7. 🎬 Jury Demo Flow & Screen Layout

### Recommended Presentation Setup:
- **Left 50% of Laptop Screen:** Web Portal (`http://localhost:3000`) logged in as **Legal Metrology Controller** (`controller@gov.in`).
- **Right 50% of Laptop Screen (or Handheld Phone):** Inspector Mobile App logged in as **Inspector Sumit** (`sumit@gov.in`).

### Demo Narrative:
1. **Inspector Conducts Inspection (Phone / Desktop App):**
   - Open Inspector Dashboard -> Tap **New Inspection**.
   - Perform OCR check on product label.
   - Flag offence under Section 36 (packaged commodities).
   - Go to **Step 6: Supplier Declaration** -> Search and select registered supplier `biz-a4edae`.
   - Submit declaration.
2. **Real-Time Controller Action (Web Portal):**
   - Switch to the Web Dashboard. Show the jury the newly created Supply Chain Link and Case `insp-sc-77afd036`.
   - Assign the case to an inspector or review the auto-calculated compounding penalty.
   - Click **Issue Notice** -> Show the auto-generated legal PDF notice preview with digital signature.
3. **Loop Closure (Phone):**
   - Refresh the Inspector's cases on the mobile app — the newly assigned case appears live!

---

## 8. 🚨 Emergency Troubleshooting & Rescue Commands

### 1. Port 8000 is already in use
```powershell
# Find process using port 8000:
netstat -ano | findstr :8000

# Kill the process by PID:
Stop-Process -Id <PID> -Force
```

### 2. Port 3000 is already in use
```powershell
netstat -ano | findstr :3000
Stop-Process -Id <PID> -Force
```

### 3. Clear Flutter cache & rebuild
```powershell
cd e:\SIH_2026\Stay_Calm\mobile_app
flutter clean
flutter pub get
```

### 4. ADB device not responding
```powershell
adb kill-server
adb start-server
adb devices
```
