#!/bin/bash
# USBGuard Manager CLI

show_menu() {
    clear
    echo "================ USBGuard Manager ================"
    echo "1) Install USBGuard"
    echo "2) Install usbutils"
    echo "3) Enable USBGuard service (does NOT start)"
    echo "4) Disable USBGuard service"
    echo "5) Start USBGuard service"
    echo "6) Stop USBGuard service"
    echo "7) Restart USBGuard service"
    echo "8) Service status"
    echo "9) List USB devices (lsusb)"
    echo "10) List USB devices (usb-devices)"
    echo "11) List blocked USB devices"
    echo "12) Temporarily allow USB device"
    echo "13) Permanently allow USB device"
    echo "0) Exit"
    echo "=================================================="
}

install_usbguard() {
    if command -v usbguard >/dev/null 2>&1; then
        echo "USBGuard is already installed."
    else
        echo "Installing USBGuard..."
        sudo apt update && sudo apt install -y usbguard && echo "USBGuard installed successfully." || echo "Failed to install USBGuard."
    fi
}

install_usbutils() {
    if command -v lsusb >/dev/null 2>&1; then
        echo "usbutils is already installed."
    else
        echo "Installing usbutils..."
        sudo apt update && sudo apt install -y usbutils && echo "usbutils installed successfully." || echo "Failed to install usbutils."
    fi
}

while true; do
    show_menu
    read -rp "Select an option: " opt
    case "$opt" in
        1) install_usbguard ;;
        2) install_usbutils ;;
        3) sudo systemctl enable usbguard.service && echo "usbguard service enabled (not started)." || echo "Failed to enable usbguard service." ;;
        4) sudo systemctl disable usbguard.service && echo "usbguard service disabled." || echo "Failed to disable usbguard service." ;;
        5) sudo systemctl start usbguard.service && echo "usbguard service started." || echo "Failed to start usbguard service." ;;
        6) sudo systemctl stop usbguard.service && echo "usbguard service stopped." || echo "Failed to stop usbguard service." ;;
        7) sudo systemctl restart usbguard.service && echo "usbguard service restarted." || echo "Failed to restart usbguard service." ;;
        8) sudo systemctl status usbguard.service ;;
        9) lsusb ;;
        10) usb-devices ;;
        11) sudo usbguard list-devices -b ;;
        12) read -rp "Enter device ID to allow temporarily: " dev_id; sudo usbguard allow-device "${dev_id}" ;;
        13) read -rp "Enter device ID to allow permanently: " dev_id; sudo usbguard allow-device "${dev_id}" -p ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option, please try again." ;;
    esac
    echo
    read -rp "Press Enter to continue..." _
done
