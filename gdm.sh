#!/usr/bin/env bash
# Themes the GDM login screen with MacTahoe (Ubuntu only). Needs sudo.
#   ./gdm.sh          install
#   ./gdm.sh revert   restore Ubuntu's original login screen
set -euo pipefail

WORK=${TMPDIR:-/tmp}/mactahoe-setup
TARGET=/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource
export TERM=${TERM:-xterm}  # the installer's progress animation fails without it

if [ ! -f "$TARGET" ]; then
    echo "Ubuntu's login theme ($TARGET) was not found; this script only supports Ubuntu."
    exit 1
fi

revert() {
    # Reinstalling the package restores the original for the installed Yaru version;
    # the installer's own .bak can be stale after a Yaru update
    sudo apt-get install --reinstall -y yaru-theme-gnome-shell
    sudo rm -f "$TARGET.bak"
    # A failed root run can leave this behind, which would block later user installs
    sudo rm -rf /tmp/MacTahoe.lock
    echo "Ubuntu's original login screen is restored."
}

if [ "${1:-}" = revert ]; then
    revert
    exit 0
fi

if [ -d "$WORK/MacTahoe-gtk-theme" ]; then
    git -C "$WORK/MacTahoe-gtk-theme" pull -q --ff-only
else
    mkdir -p "$WORK"
    git clone -q --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORK/MacTahoe-gtk-theme"
fi
cd "$WORK/MacTahoe-gtk-theme"

# GDM sub-options must directly follow -g (the upstream parser misreads them after other flags).
# No -c: with a single color the GDM build picks an empty variant; the default already builds Dark.
if ! sudo ./tweaks.sh -g -i apple < /dev/null; then
    echo "The login theme installer failed, restoring the original to be safe."
    revert
    exit 1
fi
sudo rm -rf /tmp/MacTahoe.lock

# Ubuntu's login screen loads one of these stylesheets; a theme without them would leave it unstyled
for css in gdm3.css gdm.css Yaru/gnome-shell.css gnome-shell.css; do
    if ! gresource list "$TARGET" | grep -qx "/org/gnome/shell/theme/$css"; then
        echo "The new login theme is missing $css, restoring the original to be safe."
        revert
        exit 1
    fi
done

echo "Done. Log out to see the new login screen. Undo with: $0 revert"
