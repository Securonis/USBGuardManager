#!/bin/bash
# USBGuard Manager CLI - Advanced

USBGUARD_POLICY_FILE="/etc/usbguard/rules.conf"
USBGUARD_POLICY_BACKUP="/etc/usbguard/rules.conf.bak"

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
    echo "14) Generate USBGuard policy from current devices (default deny)"
    echo "15) Show current USBGuard policy"
    echo "16) Backup current USBGuard policy"
    echo "17) Restore USBGuard policy from backup"
    echo "18) Toggle default policy (allow all / deny all)"
    echo "19) Edit USBGuard rules.conf"
    echo "20) USBGuard Rules Guide"
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

generate_policy() {
    echo "WARNING: This will overwrite $USBGUARD_POLICY_FILE with default deny policy!"
    read -rp "Are you sure? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo usbguard generate-policy -X -t block > /tmp/usbguard.rules.tmp
        if [[ $? -eq 0 ]]; then
            sudo cp "$USBGUARD_POLICY_FILE" "${USBGUARD_POLICY_BACKUP}_$(date +%Y%m%d_%H%M%S)" 2>/dev/null
            sudo mv /tmp/usbguard.rules.tmp "$USBGUARD_POLICY_FILE"
            echo "Policy generated with default deny and saved to $USBGUARD_POLICY_FILE"
            sudo systemctl restart usbguard.service
        else
            echo "Failed to generate policy."
        fi
    else
        echo "Aborted."
    fi
}

show_policy() {
    if [[ -f "$USBGUARD_POLICY_FILE" ]]; then
        echo "Current USBGuard policy ($USBGUARD_POLICY_FILE):"
        echo "--------------------------------------------------"
        sudo cat "$USBGUARD_POLICY_FILE"
    else
        echo "Policy file not found: $USBGUARD_POLICY_FILE"
    fi
}

backup_policy() {
    if [[ -f "$USBGUARD_POLICY_FILE" ]]; then
        local backup_file="${USBGUARD_POLICY_BACKUP}_$(date +%Y%m%d_%H%M%S)"
        sudo cp "$USBGUARD_POLICY_FILE" "$backup_file"
        echo "Policy backed up to $backup_file"
    else
        echo "Policy file not found: $USBGUARD_POLICY_FILE"
    fi
}

restore_policy() {
    echo "Available backups:"
    ls -1 ${USBGUARD_POLICY_BACKUP}_* 2>/dev/null
    read -rp "Enter full path of backup file to restore: " backup_file
    if [[ -f "$backup_file" ]]; then
        sudo cp "$backup_file" "$USBGUARD_POLICY_FILE"
        echo "Policy restored from $backup_file"
        sudo systemctl restart usbguard.service
    else
        echo "Backup file not found or invalid."
    fi
}

toggle_default_policy() {
    if [[ ! -f "$USBGUARD_POLICY_FILE" ]]; then
        echo "Policy file not found: $USBGUARD_POLICY_FILE"
        return
    fi
    if sudo grep -q "^allow" "$USBGUARD_POLICY_FILE"; then
        echo "Switching default policy to DENY ALL..."
        sudo sed -i 's/^allow/block/' "$USBGUARD_POLICY_FILE"
        echo "Default policy set to DENY all devices."
    else
        echo "Switching default policy to ALLOW ALL..."
        sudo sed -i 's/^block/allow/' "$USBGUARD_POLICY_FILE"
        echo "Default policy set to ALLOW all devices."
    fi
    echo "Restarting usbguard service..."
    sudo systemctl restart usbguard.service
}

edit_rules() {
    if [[ -f "$USBGUARD_POLICY_FILE" ]]; then
        sudo nano "$USBGUARD_POLICY_FILE"
        echo "Restarting usbguard service to apply changes..."
        sudo systemctl restart usbguard.service
    else
        echo "Policy file not found: $USBGUARD_POLICY_FILE"
    fi
}

rules_guide() {
    clear
    cat <<-'EOF'

USBGuard daemon configuration file options

Option                      Description
--------------------------------------------------------------
RuleFile=path               Specifies the file from which USBGuard daemon
                            loads the policy rules and writes new rules
                            received via IPC interface.

ImplicitPolicyTarget=target Defines how USB devices that do not match
                            any rule in the policy are handled. Target
                            can be allow, block, or reject (logically
                            removing the device node from the system).

PresentDevicePolicy=policy  Defines how already connected USB devices
                            are handled when the daemon starts. Policy
                            can be allow, block, reject, keep (preserve
                            current device state), or apply-policy
                            (evaluate rules for each device).

PresentControllerPolicy=policy
                            Defines how already connected USB controller
                            devices are handled when the daemon starts.
                            Can be allow, block, reject, keep, or
                            apply-policy.

InsertedDevicePolicy=policy Defines how devices connected after the daemon
                            has started are handled. Can be block, reject,
                            or apply-policy.

RestoreControllerDeviceState=boolean
                            Determines if USBGuard daemon restores
                            controller device attributes to their state
                            before shutdown during startup.

DeviceManagerBackend=backend
                            Specifies which device manager backend is used.
                            Can be uevent (default) or umockdev.

IPCAllowedUsers=username [username ...]
                            List of user names allowed to connect via IPC.

IPCAllowedGroups=groupname [groupname ...]
                            List of groups allowed to connect via IPC.

IPCAccessControlFiles=path  Location of files defining IPC access control.

DeviceRulesWithPort=boolean
                            Enables creating device-specific rules
                            including “via-port” attribute.

AuditBackend=backend        Specifies audit backend for USBGuard events.
                            Can be FileAudit or LinuxAudit.

AuditFilePath=filepath      Path to the audit log file (required if
                            AuditBackend is FileAudit).

EOF
    read -rp "Press Enter to return to menu..." _
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
        14) generate_policy ;;
        15) show_policy ;;
        16) backup_policy ;;
        17) restore_policy ;;
        18) toggle_default_policy ;;
        19) edit_rules ;;
        20) rules_guide ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option, please try again." ;;
    esac
    echo
    read -rp "Press Enter to continue..." _
done
