# Run with command: uemcli -d <Unity_IP> -u admin -p <Password> ~/scripts/storage/unityupgrade show
#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
UNITY_IP="192.168.1.50"         # Change to your Unity Management IP
USER="admin"                    # Unisphere Admin username
PASSWORD="YourSecurePassword"   # Unisphere Admin password
IMAGE_PATH="/cores/service/user/Unity-5.5.0.0.5.259.tgz.bin.gpg" # Path to firmware file

# Base uemcli command string
UEMCLI="uemcli -d $UNITY_IP -u $USER -p $PASSWORD -noHeader"

echo "=== Starting Dell Unity Automated Upgrade Process ==="

# ==============================================================================
# STEP 1: PRE-UPGRADE HEALTH CHECK
# ==============================================================================
echo "[1/4] Running Pre-Upgrade Health Check (PUHC)..."
HEALTH_CHECK_CMD=$($UEMCLI /sys/soft/ver evaluate)

if [[ $? -ne 0 ]]; then
    echo "CRITICAL: Health check evaluation failed to launch or found blockages!"
    echo "$HEALTH_CHECK_CMD"
    exit 1
fi
echo "System health check initiated successfully."

# ==============================================================================
# STEP 2: UPLOAD & STAGE THE FIRMWARE CANDIDATE
# ==============================================================================
echo "[2/4] Uploading and staging firmware image..."
# Note: If running this script directly from the Unity SSH session, change "-upload" to use the local path arguments
UPLOAD_RES=$($UEMCLI -upload -f "$IMAGE_PATH" upgrade)

if [[ $? -ne 0 ]]; then
    echo "ERROR: Image upload or staging failed."
    echo "$UPLOAD_RES"
    exit 1
fi
echo "Firmware image successfully uploaded and staged."

# ==============================================================================
# STEP 3: VERIFY UPGRADE SOFTWARE CANDIDATE ID
# ==============================================================================
echo "[3/4] Locating Software Candidate ID..."
CANDIDATE_ID=$($UEMCLI /sys/soft/ver show -detail | grep -B 1 "Candidate" | grep "ID =" | awk -F'= ' '{print $2}')

if [ -z "$CANDIDATE_ID" ]; then
    echo "ERROR: Could not find a valid upgrade candidate version on the system."
    exit 1
fi
echo "Found valid upgrade candidate ID: $CANDIDATE_ID"

# ==============================================================================
# STEP 4: PREPARE AND KICK OFF THE UPGRADE
# ==============================================================================
echo "[4/4] Launching software preparation..."
$UEMCLI /sys/soft/ver -id "$CANDIDATE_ID" prepare

# WARNING: The next step executes the upgrade. 
# It reboots the storage processors sequentially. While designed to be non-disruptive,
# it should ideally be run during a low-production window.
echo "----------------------------------------------------------------------"
echo "READY FOR EXECUTION"
echo "To trigger the final upgrade session, run the following command manually"
echo "or uncomment the final line of this script:"
echo "--> $UEMCLI /sys/soft/upgrade create -candidateId $CANDIDATE_ID -rebootSP"
echo "----------------------------------------------------------------------"

# To fully automate without manual intervention, uncomment the line below:
# $UEMCLI /sys/soft/upgrade create -candidateId "$CANDIDATE_ID" -rebootSP
