#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPCU_PATH="/opt/dell/compellent/CompCU.jar"
DSM_IP="192.168.1.75"
USER="Admin"
PASSWORD="YourSecurePassword"
SC_ID="12345" # Numeric Storage Center Serial Number

RUN_CU="java -jar $COMPCU_PATH -host $DSM_IP -user $USER -password $PASSWORD -sc $SC_ID"

echo "=== Compellent Legacy CompCU Assessment ==="

# 1. Validate Controller Connectivity and Status
echo "[1/3] Evaluating Controller Status Matrix..."
$RUN_CU -c "controller show" | grep -E "Name|Status|State"

# 2. Check Disk Operational Status
# Compellent virtualizes everything; a single failed or rebuilding disk can halt an SCOS upgrade
echo "[2/3] Checking Disk Health State..."
FAILED_DISKS=$($RUN_CU -c "disk show" | grep -i "Down")

if [ ! -z "$FAILED_DISKS" ]; then
    echo "CRITICAL: The following disks are in a down/failed state:"
    echo "$FAILED_DISKS"
    exit 1
else
    echo "✓ All physical spin/flash media are online."
fi

# 3. Check Volume Mapping Status (Unbalanced I/O Path Check)
echo "[3/3] Scanning Volume Paths for redundant balance..."
$RUN_CU -c "volume show" | grep -E "Name|Status|Mapped"