#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
FLUIDFS_VIP="192.168.1.80"  # FluidFS Management Virtual IP
USER="admin"
# Note: Using SSH Keys is heavily recommended here to allow passwordless execution
SSH_CMD="ssh -o StrictHostKeyChecking=no $USER@$FLUIDFS_VIP"

echo "=== FluidFS Bare-Metal SMB Diagnostics ==="

# 1. Audit Global Protocol Operational State
echo "[1/3] Checking SMB Protocol Engine Status..."
$SSH_CMD "client-access authentication protocols SMB-settings view" | grep -E "Enabled|Required"

# 2. Extract Active Active-Directory Authentication Health
# If communication to the Domain Controller fails, SMB shares immediately go dark for clients.
echo "[2/3] Checking Active Directory Domain Joining Status..."
$SSH_CMD "client-access authentication active-directory monitoring-status"

# 3. Check for Locked Files or Hung Sessions blocking access
echo "[3/3] Scanning for high-volume active workloads..."
$SSH_CMD "client-access active-sessions view" | head -n 15