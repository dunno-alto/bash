#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
SPA_IP="192.168.1.61"
SPB_IP="192.168.1.62"
USER="admin"
PASSWORD="YourSecurePassword"
SCOPE="0" # 0 = Global/Local, 2 = LDAP

NAVI="naviseccli -user $USER -password $PASSWORD -scope $SCOPE"

echo "=== VNX Pre-Upgrade Health Check ==="

# 1. Check SP Connectivity & Agent Status
echo "[1/4] Checking SP Agent Status..."
$NAVI -h $SPA_IP getagent | grep -E "Model|Revision"
$NAVI -h $SPB_IP getagent | grep -E "Model|Revision"

# 2. Check for Faulted Hardware
echo "[2/4] Checking for Array Faults..."
FAULTS=$($NAVI -h $SPA_IP faults -list)
if [[ ! -z "$FAULTS" && "$FAULTS" != "No faults found"* ]]; then
    echo "WARNING: Active hardware faults found!"
    echo "$FAULTS"
else
    echo "✓ No hardware faults detected."
fi

# 3. Check SP Cabling / Trespassed LUNs
# If too many LUNs are trespassed, an NDU can overload a single SP during reboot.
echo "[3/4] Checking for Trespassed LUNs..."
TRESPASSED=$($NAVI -h $SPA_IP getlun -trespassed | grep "LUN")
if [ ! -z "$TRESPASSED" ]; then
    echo "WARNING: The following LUNs are currently trespassed. Fail them back before upgrading:"
    echo "$TRESPASSED"
else
    echo "✓ All LUNs are on their default allocation paths."
fi

# 4. Check NDU Status
echo "[4/4] Checking current NDU software database status..."
$NAVI -h $SPA_IP ndu -status