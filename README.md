# 🏎️ Need for Speed: Most Wanted (2005) on Apple Silicon macOS

> **Play Need for Speed: Most Wanted (2005)** natively on Apple Silicon Macs (**M1 / M2 / M3 / M4**) with 100% free tools (Whisky/Wine + Custom MoltenVK-compatible DXVK build).
> 
> Features **Retina Fullscreen Auto-Scaling (up to 2560×1600 / 4K)**, **60+ FPS butter-smooth gameplay**, **Zero shader compilation bugs**, and **All Full-Motion Videos (FMV) & cutscenes working**.

---

## ⚡ Highlights & Fixes Included

- 🖥️ **Native Retina Fullscreen**: Automatically scales and stretches the DirectX 9 backbuffer to fill your MacBook/iMac display without display-mode switching crashes (`0x006E6D5F`).
- 🎨 **Patched MoltenVK Shader Compiler**: Resolved the MSL shader compiler failure (`use of undeclared identifier 's0_2d_shadowSmplr'`) in DXSO for SM1.x/SM2 shaders on Apple Silicon.
- ⚡ **Asynchronous Pipeline Compilation**: Pre-configured with `DXVK_ASYNC=1` for stutter-free 60+ FPS gameplay.
- 🎬 **All Story Cutscenes & FMVs**: All 34 videos and 89 NIS cutscenes intact and playing in high quality.
- 🔆 **Bloom Flickering Fix**: Automatically disables the broken Direct3D 9 visual treatment bloom flickering on Metal.
- 🛑 **1-Click Launch & Quit**: Double-clickable `.command` launchers for seamless Mac experience.

---

## 🚀 Quick Setup (1-Click)

### 1. Prerequisites
- **Mac with Apple Silicon** (M1, M2, M3, M4 running macOS Monterey, Ventura, Sonoma, or Sequoia).
- **[Whisky](https://getwhisky.link/)** (Free Wine wrapper for macOS) or Homebrew:
  ```bash
  brew install --cask whisky
  ```
- Your **Need for Speed: Most Wanted (2005)** PC game installation folder.

### 2. Prepare Whisky Bottle
1. Open **Whisky.app**.
2. Click **Create Bottle** (Name: `NFS-MostWanted`, Windows Version: `Windows 10`).
3. Under Bottle Configuration, ensure **DXVK** is enabled.

### 3. Run Setup Script
Clone this repository and run the setup script:
```bash
git clone https://github.com/udaydomadiya08/nfsMW2005_MAC.git
cd nfsMW2005_MAC
./setup.sh
```
*(Optionally pass your game path: `./setup.sh "/path/to/NFS Most Wanted (EA)"`)*

---

## 🎮 How to Play & Quit

### To Start the Game:
- **Option 1 (Double-Click):** Double-click `launch.command` inside your game folder.
- **Option 2 (Terminal):** Run `./launch.sh`

### To Quit the Game:
- **In-Game:** Press `Esc` → `Quit to Windows`
- **Force Close (Double-Click):** Double-click `quit.command` inside your game folder.
- **Terminal:** Run `./quit.sh`

---

## ⚙️ Recommended In-Game Settings

Inside the game's **Options > Video**:
- **Resolution:** 1024×768 (DXVK automatically scales to your MacBook's native Retina resolution).
- **Visual Treatment:** Low / Off (Eliminates Metal shader bloom artifacts).
- **Frame Rate:** VSync On (locked smooth 60 FPS).

---

## 🤖 100% Free Autonomous Speedrun Bot (`bot.py`)

An automated speedrun controller that progresses through Career mode, navigates menus, drives races, and tracks total playtime:

- **100% Local & Free:** Zero paid APIs, zero cloud fees. Uses OpenCV + Tesseract OCR and macOS Quartz events.
- **In-Engine AI Driving:** Uses native game pathfinding via `NFSMWExtraOptions` (AutoDrive).
- **Live Stopwatch HUD:** Displays real-time progress and logs Blacklist split times to `speedrun_splits.json`.

### How to Run:
- **Double-click:** `run_bot.command`
- **Or in terminal:** `python3 bot.py`

---

## 🛠️ Technical Details (For Developers & Modders)

### Patches Applied in Custom `d3d9.dll`:
1. **`src/dxso/dxso_compiler.cpp`**:
   - Fixed MoltenVK / SPIRV-Cross translation bug where SM 1.x implicit sampler declarations generated shadow/3D/Cube parameter types not present in Metal entry point signatures.
2. **`src/d3d9/d3d9_swapchain.cpp`**:
   - Intercepted `EnterFullscreenMode`, `LeaveFullscreenMode`, and `ChangeDisplayMode` to no-ops to eliminate macOS screen mode switching page faults.
   - Patched `D3D9SwapChainEx` constructor and `Reset` to dynamically resize the Win32 `HWND` to `GetSystemMetrics(SM_CXSCREEN, SM_CYSCREEN)` with borderless style (`WS_POPUP`), triggering Vulkan swapchain backbuffer scaling across the full display surface.
3. **`src/d3d9/d3d9_device.cpp` & `src/dxvk/dxvk_adapter.cpp`**:
   - Made unsupported Vulkan features (`geometryShader`, `extRobustness2`, `maintenance4`) optional to enable clean device initialization on Apple Silicon.

---

## 📄 License & Disclaimer

- DXVK is licensed under the [Zlib License](https://github.com/doitsujin/dxvk/blob/master/LICENSE).
- Need for Speed and EA Games are trademarks of Electronic Arts Inc. This repository does not contain proprietary game binaries or copyrighted assets.
