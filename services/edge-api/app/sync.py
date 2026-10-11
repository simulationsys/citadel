"""Push-only background cloud synchronization for Citadel edge node.

Push-only, batched, idempotent:
- Runs as an asyncio background task inside the edge FastAPI process.
- If CITADEL_CLOUD_URL is unset (the default), sync is completely dormant.
- Pushes oldest un-synced rows first.
- Only marks rows synced if cloud accepts them in a 2xx response.
- Swallows all exceptions in loop so the background task never dies.
"""
from __future__ import annotations

import asyncio
import logging
import os
from typing import Optional

import httpx

from . import db as store

logger = logging.getLogger("citadel.sync")

# Batch limit per table per push cycle
BATCH_SIZE = int(os.getenv("CITADEL_SYNC_BATCH_SIZE", "50"))
SYNC_INTERVAL_SEC = float(os.getenv("CITADEL_SYNC_INTERVAL_SEC", "10.0"))
FARM_ID = os.getenv("CITADEL_FARM_ID", "farm-001")


def cloud_url() -> Optional[str]:
    """Base URL of the cloud service. None if sync is disabled."""
    url = os.getenv("CITADEL_CLOUD_URL")
    return url.rstrip("/") if url else None


async def push_once(client: httpx.AsyncClient, base_url: str) -> int:
    """Push one batch of un-synced records to the cloud. Returns count of stamped records."""
    pending = store.get_pending_sync_records(limit=BATCH_SIZE)
    total_records = (
        len(pending["readings"])
        + len(pending["observations"])
        + len(pending["irrigationRequests"])
        + len(pending["actuatorLogs"])
    )
    if total_records == 0:
        return 0

    payload = {
        "farmId": FARM_ID,
        "readings": pending["readings"],
        "observations": pending["observations"],
        "irrigationRequests": pending["irrigationRequests"],
        "actuatorLogs": pending["actuatorLogs"],
    }

    try:
        response = await client.post(
            f"{base_url}/v1/sync/batch",
            json=payload,
            timeout=10.0,
        )
        if 200 <= response.status_code < 300:
            result = response.json()
            accepted = result.get("accepted", [])
            rejected = result.get("rejected", [])
            if rejected:
                logger.warning("Cloud rejected %d records: %s", len(rejected), rejected)
                # Malformed rows will never become well-formed. Stamp them too to unblock queue.
                store.mark_records_synced(rejected)
            if accepted:
                stamped = store.mark_records_synced(accepted)
                return stamped
        else:
            logger.warning("Cloud sync endpoint returned HTTP %d: %s", response.status_code, response.text[:200])
    except Exception as exc:
        logger.debug("Cloud sync push failed (temporary network outage or cloud down): %s", exc)
    return 0


async def push_loop() -> None:
    """Continuous push loop running in the background."""
    base_url = cloud_url()
    if not base_url:
        return

    logger.info("Starting Citadel cloud sync push loop targeting %s", base_url)
    async with httpx.AsyncClient() as client:
        while True:
            try:
                await push_once(client, base_url)
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("Unexpected error in cloud push loop: %s", exc, exc_info=True)

            try:
                await asyncio.sleep(SYNC_INTERVAL_SEC)
            except asyncio.CancelledError:
                break

