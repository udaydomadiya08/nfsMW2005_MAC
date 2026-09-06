#!/usr/bin/env python3
"""
NFS Most Wanted (2005) - Autonomous Speedrun & Progression Bot
100% Free & Local (macOS Apple Silicon + Wine/Whisky)
Zero Paid APIs | Zero Subscriptions | Pure Local Vision & Native Controls
"""

import os
import sys
import time
import subprocess
import datetime
import json
from PIL import Image
import numpy as np
import cv2
import pytesseract
import Quartz
from AppKit import NSWorkspace, NSApplicationActivateIgnoringOtherApps

# Set tesseract binary location
pytesseract.pytesseract.tesseract_cmd = "/opt/homebrew/bin/tesseract"

# macOS Virtual Key Codes
KEY_RETURN = 36
KEY_SPACE = 49
KEY_ESCAPE = 53
KEY_UP = 126
KEY_DOWN = 125
KEY_LEFT = 123
KEY_RIGHT = 124
KEY_F6 = 97       # Auto-Drive toggle in Extra Options
KEY_1 = 18
KEY_2 = 19
KEY_M = 46        # World Map

class NFMWBot:
    def __init__(self):
        self.window_id = None
        self.pid = None
        self.start_time = None
        self.state = "INITIALIZING"
        self.last_state = None
        self.consecutive_in_race = 0
        self.autodrive_engaged = False
        self.races_completed = 0
        self.current_blacklist = 15
        self.screen_cache_path = "/tmp/nfsmw_bot_screen.png"
        self.log_path = os.path.expanduser("~/Documents/uday_projects/nfsformac/speedrun_bot.log")
        self.splits_path = os.path.expanduser("~/Documents/uday_projects/nfsformac/speedrun_splits.json")
        self.splits = {}

    def log(self, msg: str):
        timestamp = datetime.datetime.now().strftime("%H:%M:%S")
        formatted = f"[{timestamp}] {msg}"
        print(formatted)
        try:
            with open(self.log_path, "a") as f:
                f.write(formatted + "\n")
        except Exception:
            pass

    def find_game_window(self) -> bool:
        """Find the Wine / NFS Most Wanted window on macOS."""
        window_list = Quartz.CGWindowListCopyWindowInfo(
            Quartz.kCGWindowListOptionAll, Quartz.kCGNullWindowID
        )
        for win in window_list:
            owner = win.get("kCGWindowOwnerName", "").lower()
            name = win.get("kCGWindowName", "").lower()
            bounds = win.get("kCGWindowBounds", {})
            w = bounds.get("Width", 0)
            h = bounds.get("Height", 0)
            if "wine" in owner and (w >= 800 and h >= 600 or "need for speed" in name):
                self.window_id = win.get("kCGWindowNumber")
                self.pid = win.get("kCGWindowOwnerPID")
                return True
        return False

    def focus_game(self):
        """Bring the Wine game process to the front."""
        try:
            ws = NSWorkspace.sharedWorkspace()
            for app in ws.runningApplications():
                if "wine" in app.localizedName().lower():
                    app.activateWithOptions_(NSApplicationActivateIgnoringOtherApps)
        except Exception:
            pass

    def send_key(self, key_code: int, delay: float = 0.15):
        """Send a synthetic keycode to Wine using System Events."""
        applescript = f'''
        tell application "System Events"
            repeat with p in (every process whose name is "wine")
                set frontmost of p to true
                delay 0.05
                key code {key_code}
            end repeat
        end tell
        '''
        try:
            subprocess.run(["osascript", "-e", applescript], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(delay)
        except Exception as e:
            self.log(f"Key event error: {e}")

    def capture_screen(self) -> np.ndarray:
        """Capture the current game window frame."""
        if not self.window_id:
            self.find_game_window()
        if not self.window_id:
            return None

        # Capture using native macOS screencapture
        cmd = ["screencapture", "-l", str(self.window_id), "-x", self.screen_cache_path]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        if os.path.exists(self.screen_cache_path):
            return cv2.imread(self.screen_cache_path)
        return None

    def analyze_screen(self, frame: np.ndarray) -> str:
        """Perform vision and OCR analysis on the game frame."""
        if frame is None:
            return "UNKNOWN"

        h, w, _ = frame.shape
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # 1. Check Bottom bar for prompt keywords (Back, Load, OK, Continue, Select)
        bottom_crop = gray[int(h * 0.85):, :]
        bottom_text = pytesseract.image_to_string(bottom_crop).lower()

        # 2. Check Center Dialog box
        dialog_crop = gray[int(h * 0.3):int(h * 0.7), int(w * 0.2):int(w * 0.8)]
        _, thresh = cv2.threshold(dialog_crop, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        dialog_text = pytesseract.image_to_string(thresh, config="--psm 6").lower()

        # Combined text
        full_sample = bottom_text + " " + dialog_text

        # Dialog / Confirmation prompt detection
        if any(k in full_sample for k in ["ok", "continue", "accept", "press enter", "found", "saving", "autosave", "confirm"]):
            return "DIALOG_PROMPT"

        # Profile selection
        if "load" in bottom_text or "load" in dialog_text:
            return "LOAD_PROFILE"

        # Post-Race results
        if any(k in full_sample for k in ["race won", "position", "bounty", "reward", "cost to state", "first place", "1st"]):
            return "RACE_WON"

        # Blacklist Marker Pick
        if any(k in full_sample for k in ["marker", "select marker", "bonus"]):
            return "PICK_MARKER"

        # Career Safehouse / Blacklist menu
        if any(k in full_sample for k in ["blacklist", "safe house", "garage", "car lot", "event", "milestone"]):
            return "CAREER_MENU"

        # Check motion / gameplay: Bottom right corner usually contains the analog speedometer in race
        speedo_roi = gray[int(h * 0.7):, int(w * 0.7):]
        # In race, the speedometer has high radial gradient variance
        if np.std(speedo_roi) > 40:
            return "IN_RACE"

        return "IDLE_MENU"

    def format_elapsed(self) -> str:
        if not self.start_time:
            return "00:00:00"
        elapsed = int(time.time() - self.start_time)
        return str(datetime.timedelta(seconds=elapsed))

    def print_hud(self):
        elapsed = self.format_elapsed()
        print("\033[H\033[J", end="") # Clear terminal screen
        print("=" * 65)
        print("🏎️   NFS: Most Wanted (2005) - Autonomous Speedrun Bot (Mac)")
        print("=" * 65)
        print(f"⏱️   Elapsed Time:       {elapsed}")
        print(f"🏆  Blacklist Rival:    #{self.current_blacklist}")
        print(f"🏁  Races Completed:    {self.races_completed}")
        print(f"🎮  Current State:      {self.state}")
        print(f"🤖  AutoDrive (AI):     {'🟢 ACTIVE (F6)' if self.autodrive_engaged else '⚪ STANDBY'}")
        print("=" * 65)
        print("Bot is autonomously monitoring and progressing the game...")
        print("Press Ctrl+C in this terminal to pause the bot.")
        print("=" * 65)

    def step(self):
        frame = self.capture_screen()
        if frame is None:
            if not self.find_game_window():
                self.state = "WAITING_FOR_GAME"
                self.print_hud()
                time.sleep(2)
                return

        state = self.analyze_screen(frame)
        self.state = state

        if state == "DIALOG_PROMPT":
            self.autodrive_engaged = False
            self.consecutive_in_race = 0
            self.log("Handling dialog prompt (pressing Enter/OK)...")
            self.send_key(KEY_RETURN)
            time.sleep(0.5)

        elif state == "LOAD_PROFILE":
            self.autodrive_engaged = False
            self.log("Loading career profile (pressing Enter)...")
            self.send_key(KEY_RETURN)
            time.sleep(0.5)

        elif state == "CAREER_MENU":
            self.autodrive_engaged = False
            self.consecutive_in_race = 0
            self.log("Safehouse/Career Hub detected. Starting next event...")
            # Select first available event
            self.send_key(KEY_RETURN)
            time.sleep(1.0)

        elif state == "IN_RACE":
            self.consecutive_in_race += 1
            if not self.autodrive_engaged:
                self.log("Race detected! Engaging game's internal AutoDrive AI (F6)...")
                self.send_key(KEY_F6)
                self.autodrive_engaged = True
            
            # Pulse Nitrous assist periodically during straightaways
            if self.consecutive_in_race % 5 == 0:
                self.send_key(KEY_SPACE, delay=0.1) # Nitro

        elif state == "RACE_WON":
            self.autodrive_engaged = False
            self.consecutive_in_race = 0
            self.races_completed += 1
            self.log(f"Race completed! Total races won: {self.races_completed}")
            self.send_key(KEY_RETURN)
            time.sleep(1.0)

        elif state == "PICK_MARKER":
            self.autodrive_engaged = False
            self.log("Blacklist Rival defeated! Picking reward marker...")
            self.send_key(KEY_LEFT)
            self.send_key(KEY_RETURN)
            time.sleep(0.8)
            self.send_key(KEY_RIGHT)
            self.send_key(KEY_RETURN)
            self.current_blacklist = max(1, self.current_blacklist - 1)
            self.splits[f"Blacklist_{self.current_blacklist}"] = self.format_elapsed()
            try:
                with open(self.splits_path, "w") as f:
                    json.dump(self.splits, f, indent=2)
            except Exception:
                pass

        elif state == "IDLE_MENU":
            # Advance splash screens / cutscenes
            self.autodrive_engaged = False
            self.send_key(KEY_RETURN, delay=0.2)

        self.print_hud()
        time.sleep(1.5)

    def run(self):
        print("Starting NFS Most Wanted Autonomous Bot...")
        self.focus_game()
        self.start_time = time.time()
        try:
            while True:
                self.step()
        except KeyboardInterrupt:
            print("\n⏹️ Bot paused by user.")
            print(f"Total time elapsed: {self.format_elapsed()}")

if __name__ == "__main__":
    bot = NFMWBot()
    bot.run()
