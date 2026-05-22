#!/bin/bash

SPA_IP="192.168.1.61"
USER="admin"
PASSWORD="YourSecurePassword"
FIRMWARE_FILE="/path/to/drive_firmware_file.fdf"

# Format: Bus_Enclosure_Disk (e.g., 0_0_1 for Bus 0, Enclosure 0, Disk 1)
TARGET_DISKS="0_0_1 0_0_2 0_0_3"

NAVI="naviseccli -h $SPA_IP -user $USER -password $PASSWORD -scope 0"

echo "=== Starting Automated Drive Firmware Injection ==="

for DISK in $TARGET_DISKS; do
    echo "Processing Disk: $DISK"
    
    # Check current revision
    CURRENT_REV=$($NAVI getdisk $DISK -rev | grep "Product Revision")
    echo "Current $CURRENT_REV"
    
    # Inject Firmware
    echo "Applying firmware matrix to $DISK..."
    $NAVI firmware -file "$FIRMWARE_FILE" -d $DISK
    
    if [ $? -eq 0 ]; then
        echo "✓ Firmware package successfully sent to $DISK."
    else
        echo "✗ Failed to update $DISK."
    fi
    echo "---------------------------------------"
done