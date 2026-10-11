"""Phase 4 verification: cloud sync tests."""
import asyncio
import os
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
EDGE_API_DIR = REPO_ROOT / "services" / "edge-api"
CLOUD_API_DIR = REPO_ROOT / "services" / "cloud-api"

# Clean any existing 'app' from sys.modules
for k in list(sys.modules.keys()):
    if k == "app" or k.startswith("app."):
        del sys.modules[k]

# Import edge-api first as app
sys.path.insert(0, str(EDGE_API_DIR))
import app.db as edge_store
import app.sync as edge_sync

# Unload 'app' and alias edge components in sys.modules so they don't break
edge_app_modules = {}
for k in list(sys.modules.keys()):
    if k == "app" or k.startswith("app."):
        edge_app_modules[k] = sys.modules[k]
        del sys.modules[k]

# Import cloud-api as app
sys.path.insert(0, str(CLOUD_API_DIR))
import app.db as cloud_store
import app.main as cloud_main
import app.schemas as cloud_schemas

# Restore edge modules under custom names so edge_store/sync keep functioning
for k, v in edge_app_modules.items():
    alias = k.replace("app", "edge_app", 1)
    sys.modules[alias] = v

import httpx
from fastapi.testclient import TestClient


class CloudSyncTests(unittest.TestCase):
    def setUp(self):
        edge_handle, self.edge_db_file = tempfile.mkstemp(suffix="-edge.db")
        os.close(edge_handle)
        os.unlink(self.edge_db_file)
        os.environ["CITADEL_DB_PATH"] = self.edge_db_file

        cloud_handle, self.cloud_db_file = tempfile.mkstemp(suffix="-cloud.db")
        os.close(cloud_handle)
        os.unlink(self.cloud_db_file)
        os.environ["CITADEL_CLOUD_DB_PATH"] = self.cloud_db_file

        self.addCleanup(self._cleanup_dbs)

        edge_store.init_db()
        cloud_store.init_db()

        # Clear seed data for clean test assertions
        with edge_store.db() as conn:
            conn.execute("DELETE FROM readings")
            conn.execute("DELETE FROM observations")

        self.cloud_client = TestClient(cloud_main.app)

    def _cleanup_dbs(self):
        for f in (self.edge_db_file, self.cloud_db_file):
            for suffix in ("", "-wal", "-shm"):
                try:
                    p = Path(f + suffix)
                    if p.is_file():
                        p.unlink()
                except OSError:
                    pass

    def test_cloud_health(self):
        res = self.cloud_client.get("/health")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["status"], "ok")

    def test_sync_flow_end_to_end_and_idempotency(self):
        # 1. Insert 3 readings into edge
        for i in range(1, 4):
            edge_store.save_reading({
                "eventId": f"evt-read-{i}",
                "deviceId": "field-node-01",
                "zoneId": "zone-a",
                "soilMoisturePct": 20.0 + i,
                "temperatureC": 30.0 + i,
                "humidityPct": 50.0,
            })

        # Insert 1 observation into edge
        edge_store.save_observation({
            "eventId": "evt-obs-1",
            "kind": "crop_health",
            "zoneId": "zone-a",
            "label": "early_blight",
            "confidence": 0.88,
        })

        # Verify edge has 4 pending sync records
        self.assertEqual(edge_store.pending_sync_count(), 4)

        # 2. Push once to cloud using in-process ASGI Transport
        transport = httpx.ASGITransport(app=cloud_main.app)

        async def run_push():
            async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
                return await edge_sync.push_once(client, "http://testserver")

        stamped = asyncio.run(run_push())
        self.assertEqual(stamped, 4)

        # Verify edge pending sync count is now 0
        self.assertEqual(edge_store.pending_sync_count(), 0)

        # Check cloud DB row counts
        with cloud_store.db() as conn:
            readings_count = conn.execute("SELECT COUNT(*) FROM cloud_readings").fetchone()[0]
            obs_count = conn.execute("SELECT COUNT(*) FROM cloud_observations").fetchone()[0]
        self.assertEqual(readings_count, 3)
        self.assertEqual(obs_count, 1)

        # 3. Force a replay: unmark one record on edge and push again
        with edge_store.db() as conn:
            conn.execute("UPDATE readings SET synced_at = NULL WHERE event_id = 'evt-read-1'")
        self.assertEqual(edge_store.pending_sync_count(), 1)

        # Re-push
        stamped_again = asyncio.run(run_push())
        self.assertEqual(stamped_again, 1)
        self.assertEqual(edge_store.pending_sync_count(), 0)

        # Cloud must NOT duplicate the row (UNIQUE constraint)
        with cloud_store.db() as conn:
            final_readings_count = conn.execute("SELECT COUNT(*) FROM cloud_readings").fetchone()[0]
        self.assertEqual(final_readings_count, 3)


if __name__ == "__main__":
    unittest.main()

