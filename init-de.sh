#!/bin/bash

set -e

DE="$1"

if [ -z "$DE" ]; then
    echo "Usage: $0 <mate|xfce|lxqt|kde|etc.>"
    exit 1
fi

echo "Set password for droid: "
sudo passwd droid

echo "Updating system..."
sudo apt update

if ! apt-cache show "task-${DE}-desktop" >/dev/null 2>&1; then
    echo "Unknown desktop environment: $DE"
    exit 1
fi

sudo apt full-upgrade -y

echo "Installing $DE..."
sudo apt install -y "task-${DE}-desktop"

echo "Disabling Weston autostart..."
sudo sed -i '/systemctl --user start weston/s/^/# /' /usr/local/bin/enable_display || true
sudo sed -i '/systemctl --user start weston/s/^/# /' /usr/local/bin/enable_gfxstream || true

echo "Installing LightDM..."
sudo apt install lightdm lightdm-gtk-greeter

echo "Selecting LightDM..."
sudo dpkg-reconfigure lightdm

echo "Display manager: "
cat /etc/X11/default-display-manager

sudo systemctl disable sddm 2>/dev/null || true
sudo systemctl enable lightdm

echo
echo "Done"
echo "Restart the Linux environment to apply the changes"
