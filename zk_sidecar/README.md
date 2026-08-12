# ZKTeco K50 Pro Sidecar (MECMS)

Local Python service that connects to the fingerprint device on your LAN and syncs punches into Firebase Firestore (`attendances`).

## Why a sidecar?

ZKTeco protocol (port **4370**) works best from a PC on the same network. The Flutter admin app calls this service at `http://127.0.0.1:8765`.

When the admin is hosted on HTTPS (Firebase), the browser only allows that call if:
1. This helper is running **on the same PC** viewing the admin, and
2. Chrome/Edge grants **Local network access**, and
3. The helper responds with `Access-Control-Allow-Private-Network: true` (built-in).

Daily attendance still syncs while the helper runs, even with the browser closed (`auto_start_sync_loop`).

## Setup

1. Connect the K50 Pro by Ethernet to the same router as your PC.
2. On the device: **Menu → Comm. → Ethernet** → set a fixed IP, e.g.:
   - IP `192.168.1.201`
   - Mask `255.255.255.0`
   - Gateway `192.168.1.1`
   - Comm Key `0` (default)
3. On the PC: `ping 192.168.1.201`
4. Install Python 3.10+, then:

```bash
cd zk_sidecar
copy config.example.json config.json
pip install -r requirements.txt
python server.py
```

5. In Admin panel → **Devices**:
   - Add device with that IP / port 4370
   - **Test connection**
   - **Load device users** and link each `user_id` to a student
   - **Sync now** or **Start auto-sync**

## API

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Sidecar status |
| POST | `/test-connection` | Ping device via pyzk |
| GET | `/device-users?device_id=` | List users on device |
| POST | `/sync` | Pull attendance → Firestore |
| POST | `/sync-loop/start` | Poll every N seconds |
| POST | `/sync-loop/stop` | Stop polling |

## Enroll fingerprints

Enroll on the **device itself** (User Mgt), then map that device user ID to a student in Admin → Devices. See the Arabic guide in the chat / `docs/ZKTECO_AR.md`.
