# Packaging

This folder turns MetaGhost into a proper per-user desktop install on
Kali Linux (or any Debian-based, freedesktop-compliant distro).

## Install

```bash
cd MetaGhost
./packaging/install.sh
```

This will:

1. Check for `python3`, `pip3`, `node`, `npm`, `rsync`, and `exiftool`,
   offering to `apt-get install` anything missing.
2. Copy the app into `~/.local/share/metaghost` (source files, not your
   working copy — the clone you ran this from is untouched).
3. Create a Python venv and install `requirements.txt` into it.
4. Run `npm install` inside `hud/` (pulls down Electron).
5. Install the app icon into `~/.local/share/icons/hicolor/scalable/apps/`
   and `~/.local/share/pixmaps/`.
6. Install the `metaghost` launcher command to `~/.local/bin/metaghost`.
7. Install a `MetaGhost.desktop` menu entry to
   `~/.local/share/applications/`.

No `sudo` is needed for the app itself — only for installing missing
system packages, and only with your confirmation.

After installing, launch MetaGhost either from your Applications menu
(search "MetaGhost") or from any terminal:

```bash
metaghost
```

If `metaghost` isn't found right after install, add `~/.local/bin` to
your `PATH` as the installer's output will tell you, or just use the
Applications menu entry.

## Uninstall

```bash
./packaging/uninstall.sh
```

Removes the install directory (`~/.local/share/metaghost` — including any
reports, cleaned files, and backups stored there), the launcher, the
menu entry, and the icon. Asks for confirmation first.

## Files in this folder

| File | Purpose |
|---|---|
| `install.sh` | Per-user installer (see above). |
| `uninstall.sh` | Reverses everything `install.sh` did. |
| `bin/metaghost` | The launcher script that gets copied to `~/.local/bin/metaghost`. Starts the API in the background, launches the Electron HUD in the foreground, and stops the API automatically when the HUD window closes. |
| `metaghost.desktop` | Freedesktop menu entry template. `install.sh` substitutes `__LAUNCHER__` with the real path to the installed launcher before copying it into `~/.local/share/applications/`. |

No rasterized PNG icon set is bundled — MetaGhost ships one scalable SVG
(`assets/metaghost-logo.svg`), installed straight into the `scalable/apps`
hicolor directory, which every modern desktop environment can use directly.
If you want a Glacier-style multi-resolution PNG set instead, rasterize the
SVG at 16/24/32/48/64/128/256/512/1024px (e.g. with `rsvg-convert` or
Inkscape) into `packaging/icons/hicolor/<size>x<size>/apps/metaghost.png`
and update `install.sh`'s icon step to loop over them the same way Glacier's
installer does.
