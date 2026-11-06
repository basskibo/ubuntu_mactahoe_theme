#!/usr/bin/env bash
# Installs MacTahoe (dark) from vinceliuice's repos and applies the local tweaks in this folder.
# Safe to re-run: it reinstalls the themes, which also resets the files the tweaks are appended to.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${TMPDIR:-/tmp}/mactahoe-setup
export TERM=${TERM:-xterm}  # the installer's progress animation fails without it
mkdir -p "$WORK"

fetch() {
    if [ -d "$WORK/$1" ]; then
        git -C "$WORK/$1" pull -q --ff-only
    else
        git clone -q --depth 1 "https://github.com/vinceliuice/$1.git" "$WORK/$1"
    fi
}
fetch MacTahoe-gtk-theme
fetch MacTahoe-icon-theme

echo "Installing themes..."
cd "$WORK/MacTahoe-gtk-theme"
# Opaque variant for GTK3 apps (window blur only works for the whitelisted GTK4 apps below)
./install.sh -c dark -o solid --round < /dev/null
# Translucent variant for the shell and libadwaita apps, with the Apple logo and a 45% panel
./install.sh -c dark -o normal -l --round --shell -i apple -p 45 < /dev/null
(cd "$WORK/MacTahoe-icon-theme" && ./install.sh < /dev/null)
# The Firefox installer refuses to run while Firefox is open; it replaces each profile's user.js
if pidof firefox firefox-bin > /dev/null; then
    echo "Firefox is running, skipping its theme (close it and re-run, or run: $WORK/MacTahoe-gtk-theme/tweaks.sh -f)"
else
    ./tweaks.sh -f < /dev/null
fi

echo "Applying tweaks..."
cat "$HERE/gtk4-overrides.css" >> "$HOME/.config/gtk-4.0/gtk.css"
cat "$HERE/shell-overrides.css" >> "$HOME/.themes/MacTahoe-Dark/gnome-shell/gnome-shell.css"

# The upstream wallpaper script writes the XML where the directory should be, so do it here
BG="$HOME/.local/share/backgrounds/MacTahoe"
PROPS="$HOME/.local/share/gnome-background-properties"
[ -f "$PROPS" ] && rm "$PROPS"
mkdir -p "$BG" "$PROPS"
cp "$WORK"/MacTahoe-gtk-theme/wallpaper/*.jpeg "$BG/"
sed "s|@BACKGROUNDDIR@|$HOME/.local/share/backgrounds|g" "$WORK/MacTahoe-gtk-theme/wallpaper/MacTahoe.xml" > "$PROPS/MacTahoe.xml"

echo "Applying settings..."
gsettings set org.gnome.desktop.interface gtk-theme 'MacTahoe-Dark-solid'
gsettings set org.gnome.desktop.interface icon-theme 'MacTahoe-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface font-name 'Inter Variable 11'
gsettings set org.gnome.desktop.interface document-font-name 'Inter Variable 11'
gsettings set org.gnome.desktop.interface font-antialiasing 'grayscale'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Variable Semi-Bold 11'
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'

# Shell theme needs the user-themes extension. No switching away and back to force a reload:
# on GNOME 50 every live theme reload fails ("Argument file may not be null") and leaves the
# shell half-themed, so the new shell CSS only applies at the next login
gsettings set org.gnome.shell.extensions.user-theme name 'MacTahoe-Dark'

# Extensions from extensions.gnome.org. GNOME shows a confirmation dialog, then downloads
# a version matching this GNOME release and enables it without a re-login
install_ext() {  # uuid, name, page
    if gnome-extensions info "$1" > /dev/null 2>&1; then
        gnome-extensions enable "$1"
        return
    fi
    echo "Confirm the $2 install in the dialog that opens..."
    result=$(gdbus call --session --timeout 300 --dest org.gnome.Shell.Extensions --object-path /org/gnome/Shell/Extensions \
        --method org.gnome.Shell.Extensions.InstallRemoteExtension "$1" 2>&1 || true)
    case "$result" in
        *successful*) echo "$2 installed." ;;
        *) echo "$2 was not installed ($result). Get it at $3" ;;
    esac
}
install_ext blur-my-shell@aunetx "Blur my Shell" https://extensions.gnome.org/extension/3193/blur-my-shell/
# Our Dynamic Island extension
install_ext dynamic-island@bjagetic "Dynamic Island" https://extensions.gnome.org/extension/11268/dynamic-island/

BMS="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas"
if [ -d "$BMS" ]; then
    bms() { gsettings --schemadir "$BMS" set "org.gnome.shell.extensions.blur-my-shell${1:+.$1}" "$2" "$3"; }
    # Blur strength and brightness now live in named "pipelines"; add ours next to the user's own
    pipe() { echo "'pipeline_tahoe_$1': {'name': <'Tahoe $1'>, 'effects': <[<{'type': <'dual_kawase_blur'>, 'id': <'effect_tahoe_$1'>, 'params': <{'unscaled_radius': <$2>, 'brightness': <$3>}>}>]>}"; }
    pipelines=$(gsettings --schemadir "$BMS" get org.gnome.shell.extensions.blur-my-shell pipelines | sed -E "s/, 'pipeline_tahoe_[a-z]+': \{'name': <'Tahoe [a-z]+'>, 'effects': <\[<\{[^]]*\]>\}//g")
    bms "" pipelines "${pipelines%\}}, $(pipe dock 30 0.9), $(pipe lockscreen 4 0.85), $(pipe apps 30 0.7)}"
    bms dash-to-dock pipeline pipeline_tahoe_dock
    # Tahoe's lock screen shows the wallpaper almost sharp, just dimmed enough for the clock
    bms lockscreen pipeline pipeline_tahoe_lockscreen
    # Blur behind translucent parts (sidebars) of these apps only; opacity 255 keeps the rest of the window solid
    bms applications whitelist "['org.gnome.Nautilus', 'org.gnome.Settings', 'org.gnome.TextEditor', 'org.gnome.Extensions', 'org.gnome.Calculator', 'org.gnome.Software']"
    bms applications pipeline pipeline_tahoe_apps
    bms applications opacity 255
    bms applications dynamic-opacity false
    bms applications enable-all false
    bms applications blur true
else
    echo "blur-my-shell not found, skipping blur settings"
fi

# Not "fc-list | grep -q": with pipefail, grep quitting early makes fc-list fail and the check lie
if [ -z "$(fc-list 'Inter Variable' family)" ]; then
    echo "Note: the 'Inter Variable' font is not installed, get it from https://rsms.me/inter/"
fi

echo "Done. Log out and back in to apply everything."
