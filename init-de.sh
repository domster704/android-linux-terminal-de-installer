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
sudo apt install lightdm lightdm-gtk-greeter -y

echo "Selecting LightDM..."
sudo dpkg-reconfigure lightdm

echo "Display manager: "
cat /etc/X11/default-display-manager

sudo systemctl disable sddm 2>/dev/null || true

echo "Configuring automatic display detection..."
sudo tee /etc/systemd/system/android-display.service >/dev/null <<'EOF'
[Unit]
Description=Android Terminal automatic display configuration
After=lightdm.service
Wants=lightdm.service

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 /usr/bin/xrandr --auto >/dev/null 2>&1; sleep 3; done'
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling automatic display detection..."
sudo systemctl daemon-reload
sudo systemctl enable --now lightdm
sudo systemctl enable --now android-display.service
sudo systemctl restart android-display.service

echo
echo "Done"
echo "Restart the Linux environment to apply the changes"
