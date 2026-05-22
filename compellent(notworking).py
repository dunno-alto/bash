import requests
import urllib3
import json

# Silence self-signed cert warnings common in local SAN fabrics
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ==============================================================================
# CONFIGURATION
# ==============================================================================
DSM_HOST = "192.168.1.75"  # Your DSM Data Collector IP
USER = "Admin"
PASSWORD = "YourSecurePassword"
SC_NAME = "SC9000-Prod-Cluster"

BASE_URL = f"https://{DSM_HOST}:3033/api/rest"

# Start Session
session = requests.Session()
session.auth = (USER, PASSWORD)
session.verify = False
session.headers.update({"Content-Type": "application/json", "Accept": "application/json"})

print(f"=== Initiating Compellent Automation Deployment Sequence for {SC_NAME} ===")

# 1. Locate the Target Storage Center Instance ID
sc_response = session.get(f"{BASE_URL}/StorageCenter/StorageCenter")
sc_id = None
for sc in sc_response.json():
    if sc['name'] == SC_NAME:
        sc_id = sc['instanceId']
        break

if not sc_id:
    print(f"CRITICAL: Could not find Storage Center named {SC_NAME}")
    exit(1)

print(f"✓ Found target Storage Center. Instance ID: {sc_id}")

# 2. Query System Alerts / Blockers
alert_response = session.get(f"{BASE_URL}/StorageCenter/StorageCenter/{sc_id}/AlertList")
active_alerts = [a for a in alert_response.json() if a['status'] == 'Active']

if active_alerts:
    print(f"⚠️ WARNING: {len(active_alerts)} Active Alerts found on the array!")
    for alert in active_alerts:
        print(f"  - [{alert['severity']}] {alert['message']}")
else:
    print("✓ Zero active health alerts detected. Array is clean.")

# 3. Verify Controller Handoff Path Balance
controller_response = session.get(f"{BASE_URL}/StorageCenter/StorageCenter/{sc_id}/ControllerList")
for ctrl in controller_response.json():
    print(f"Controller {ctrl['instanceName']}: Status is '{ctrl['status']}', Mode is '{ctrl['leaderState']}'")
    if ctrl['status'] != 'Up':
        print("CRITICAL: One or more Storage Controllers are degraded. Aborting upgrade paths.")
        exit(1)

# 4. Trigger Phone-Home / SupportAssist to Stage the SCOS Update
# Compellent arrays must validate their payload bundle with Dell SupportAssist before patching
print("\n[Action] Pushing SupportAssist Diagnostic Heartbeat to stage updates...")
payload = {"appendLogs": False, "description": "Pre-Upgrade Automation Check"}
sa_status = session.post(f"{BASE_URL}/StorageCenter/StorageCenter/{sc_id}/SendSupportAssist", data=json.dumps(payload))

if sa_status.status_code == 204:
    print("✓ SupportAssist payload successfully dispatched. Check DSM for staged SCOS packages.")
else:
    print("✗ Failed to signal SupportAssist gateway.")