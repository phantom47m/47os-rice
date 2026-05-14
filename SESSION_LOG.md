# 47 OS Rice — Session Log

## 2026-05-14 — Repo sync & README polish
- Restored real clone URL in README install command (was `<repo-url>` placeholder)
- Trimmed applet list in README to match reality (VPN applet was removed from default install)
- Added `__pycache__/`, `.mcp.json`, `launch-project.sh` to `.gitignore` (user-specific paths / build artifacts)
- Committed `setup-47os.sh` (fresh Linux Mint bootstrap script — clones repo and runs installer)
- Committed `SESSION_LOG.md` to repo

## 2026-03-25 — Massive Bug Sweep & Hardening (10 commits)
- **27+ bugs fixed** across installer, uninstaller, applets, extensions, and scripts
- Key fixes:
  - 12 of 13 keybindings were dead (custom-list only had custom0) — fixed
  - Brave→Safari icon swap ran before icons were installed — reordered to STEP 10
  - Brightness applet read transparency state from wrong path (/tmp/ → ~/.config/)
  - SSID command injection in fake-wifi applet — switched to array-based spawn
  - Keyboard backlight used sudo tee (hangs in applet) — switched to brightnessctl
  - Compiz extension memory leak — `this` context lost in forEach cleanup
  - Lock screen sound got killed before playing — now plays synchronously
  - cd /tmp never recovered on git clone failure — moved recovery outside if/else
  - Uninstaller only cleaned ~30% of files — now cleans ~95%
  - All Perl regex (grep -oP) replaced with portable alternatives
- Stripped personal data from dconf: NYC coordinates, window positions, docker command, webcam, warpinator ID, hyprland references, 47magazine path
- Removed Ghost Mode references, dead code (47sound-inject.sh 160 lines), phantom dock items
- Added lock file cleanup (atexit+SIGTERM) to Python sound scripts
- Atomic state writes in 47sound (tmp+mv instead of double echo)
- Autostart delays for devilspie2 and middle-click-hold
- Auto-extract MIME types expanded (rar, 7z, tar, bz2, xz)
- Nemo action filename mismatch fixed in uninstaller
- **Desktop icon grid**: enabled snap-to-grid with 1.3x spacing, collision avoidance (Windows-style)
- **Terminal title lock**: added `title "name"` command to pin tab names across sessions
- All changes pushed to GitHub (10 commits)

### What's next
- VM test the full install on clean Linux Mint
- Rebuild ISO with updated install.sh
- Test uninstall flow end-to-end

## 2026-03-21 — Login Screen Avatar Polish
- Changed login screen avatar circle background from gray (#1a1a1a) to black (#000000)
- Reduced avatar circle size from 160px to 130px to better match macOS lock screen
- File changed: `system/web-greeter/themes/47-macos/index.html`
- Verified install.sh copies the theme directory (line 622), so changes will deploy on install

## 2026-03-20 — Session Setup
- Created persistent Claude Code session (CLAUDE.md, SESSION_LOG.md, launcher)
- Previous work spans 5+ sessions from March 7–20
- Key milestones: full installer script, custom applets/extensions, sound system, macOS features, VM-tested install
