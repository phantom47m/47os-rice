#!/usr/bin/env python3
"""Middle mouse button hold → spacebar hold (for Claude Code voice input).

Listens for XI2 raw button events so it works regardless of X grabs.
When middle mouse button (button 2) is pressed, sends keydown space.
When released, sends keyup space.
"""
import subprocess
import signal
import sys
import os

space_held = False

def cleanup(*_):
    global space_held
    if space_held:
        subprocess.run(['xdotool', 'keyup', 'space'], stderr=subprocess.DEVNULL)
    sys.exit(0)

signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)

def main():
    global space_held

    # Kill any other instance of this script
    pid = os.getpid()
    try:
        out = subprocess.check_output(
            ['pgrep', '-f', 'middle-click-hold.py'],
            text=True
        )
        for line in out.strip().splitlines():
            other_pid = int(line.strip())
            if other_pid != pid:
                os.kill(other_pid, signal.SIGTERM)
    except (subprocess.CalledProcessError, ValueError):
        pass

    # Use xinput test-xi2 --root to get raw events (bypass X grabs)
    proc = subprocess.Popen(
        ['xinput', 'test-xi2', '--root'],
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1
    )

    current_event = None

    try:
        for line in proc.stdout:
            stripped = line.strip()

            if 'RawButtonPress' in stripped:
                current_event = 'press'
            elif 'RawButtonRelease' in stripped:
                current_event = 'release'
            elif stripped.startswith('detail:') and current_event is not None:
                button = stripped.split(':')[1].strip()
                if button == '2':
                    if current_event == 'press' and not space_held:
                        subprocess.Popen(['xdotool', 'keydown', 'space'])
                        space_held = True
                    elif current_event == 'release' and space_held:
                        subprocess.Popen(['xdotool', 'keyup', 'space'])
                        space_held = False
                current_event = None
            elif stripped.startswith('EVENT'):
                current_event = None
    except Exception:
        pass
    finally:
        cleanup()

if __name__ == '__main__':
    main()
