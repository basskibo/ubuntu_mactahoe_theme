# MacTahoe setup

A macOS Tahoe look for Ubuntu (GNOME 46, Wayland) in one command.

It uses the existing [MacTahoe](https://github.com/vinceliuice/MacTahoe-gtk-theme) theme by vinceliuice, adds our own tweaks on top, and installs [Dynamic Island](https://extensions.gnome.org/extension/11268/dynamic-island/).

## What gets installed

| Part | What |
|------|------|
| Theme | MacTahoe Dark: opaque for GTK3 apps, translucent (with blur) for GNOME/GTK4 apps |
| Top bar | MacTahoe Dark, Apple logo, 45% opacity |
| Icons | MacTahoe dark |
| Firefox | MacTahoe theme (only if Firefox is closed) |
| Font | Inter Variable, grayscale antialiasing like macOS |
| Windows | buttons on the left (close, minimize, maximize) |
| Wallpapers | MacTahoe day/night, added to the picker (not applied) |
| Blur | translucent sidebars in Files, Settings…, lighter dock, sharper lock screen wallpaper |
| Dynamic Island | our extension from extensions.gnome.org |
| Login screen | MacTahoe, via the separate `gdm.sh` script (needs sudo) |

## Installing on a new machine

### 1. Prepare the system

```bash
sudo apt install git sassc libglib2.0-dev-bin libxml2-utils gnome-shell-extensions
```

Then install:

- the **User Themes** extension (ships with `gnome-shell-extensions`) and enable it in the Extensions app,
- the **[Blur my Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)** extension,
- the **[Inter](https://rsms.me/inter/)** font (put `InterVariable.ttf` in `~/.local/share/fonts/`).

### 2. Get this folder

Clone or copy the whole `mactahoe-setup` folder (not just the script), e.g. into `~/xProjects/`.

### 3. Run

```bash
~/xProjects/mactahoe-setup/install.sh
```

Confirm the "Install Dynamic Island?" dialog when it appears. Close Firefox first if you want its theme too.

### 4. Login screen (optional)

```bash
~/xProjects/mactahoe-setup/gdm.sh
```

### 5. Log out and back in

Some parts only apply after that (title bars of X11 apps, the login screen…).

## Reverting

**Login screen** back to Ubuntu's original:

```bash
~/xProjects/mactahoe-setup/gdm.sh revert
```

If the login screen doesn't show up: press `Ctrl+Alt+F3`, log in on the console, run the command above, then `Ctrl+Alt+F1` or reboot.

**Theme** back to the Ubuntu default:

```bash
gsettings reset org.gnome.desktop.interface gtk-theme
gsettings reset org.gnome.desktop.interface icon-theme
gsettings reset org.gnome.shell.extensions.user-theme name
gsettings reset org.gnome.desktop.wm.preferences button-layout
```

**Firefox**: in the profile folder (`~/snap/firefox/common/.mozilla/firefox/<profile>/`) delete `user.js` and the `chrome` link.

## Customizing

Our tweaks live in two files that get appended to the theme files on every install:

- `gtk4-overrides.css`: Files and other GTK4 apps (flat toolbar buttons, no white rims)
- `shell-overrides.css`: top bar, quick settings, lock screen

Edit a file and re-run `install.sh`. Don't edit the files in `~/.themes` directly, every reinstall overwrites them.

## Known limitations

- Apple's font (SF Pro) may only be used on Apple devices, so Inter stands in for it.
- When Ubuntu updates the `yaru-theme-gnome-shell` package, the login screen goes back to the Ubuntu look. Re-run `gdm.sh`.
- Don't use MacTahoe's "blur" variant (`-b`): menus become almost fully transparent because Blur my Shell can't blur popup menus.
- On the lock screen the date sits below the clock (macOS has it above). A theme can't change that.
