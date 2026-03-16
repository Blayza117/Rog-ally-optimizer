"""
ROG Ally Optimizer - EXE Launcher
Compiled by PyInstaller into ROGAllyOptimizer.exe
Bundles ROGAllyOptimizer.ps1 and runs it with best available PowerShell.
"""
import sys
import os
import subprocess

def find_ps1():
    if getattr(sys, 'frozen', False):
        base = sys._MEIPASS
    else:
        base = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base, 'ROGAllyOptimizer.ps1')

def find_powershell():
    ps7 = r"C:\Program Files\PowerShell\7\pwsh.exe"
    if os.path.exists(ps7):
        return ps7
    return "powershell.exe"

def main():
    script = find_ps1()

    if not os.path.exists(script):
        try:
            import ctypes
            ctypes.windll.user32.MessageBoxW(
                0,
                "ROGAllyOptimizer.ps1 not found inside the exe bundle.\nPlease re-download the app.",
                "ROG Ally Optimizer",
                0x10
            )
        except Exception:
            pass
        return 1

    # Unlock execution policy first (silent)
    subprocess.run(
        ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass",
         "-Command", "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force"],
        capture_output=True
    )

    # Launch the app
    ps = find_powershell()
    result = subprocess.run([
        ps,
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", script
    ])

    return result.returncode

if __name__ == "__main__":
    sys.exit(main())
