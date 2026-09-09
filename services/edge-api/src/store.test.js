import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { FarmStore } from './store.js';

function makeSeed(overrides = {}) {
  return {
    deviceId: 'demo-node-01',
    zoneId: 'zone-a',
    soilMoisturePct: 24,
    temperatureC: 34,
    humidityPct: 55,
    rainfallMm: 0,
    waterLevelPct: 12,
    capturedAt: new Date().toISOString(),
    ...overrides,
  };
}

// ── Readings ────────────────────────────────────────────────────────────────

describe('FarmStore — readings', () => {
  it('seeds with one initial reading', () => {
    const store = new FarmStore(makeSeed());
    assert.equal(store.latestReading('zone-a').deviceId, 'demo-node-01');
  });

  it('returns null for an unknown zone', () => {
    const store = new FarmStore(makeSeed());
    assert.equal(store.latestReading('zone-x'), null);
  });

  it('addReading stores a new reading with capturedAt', () => {
    const store = new FarmStore(makeSeed());
    const added = store.addReading({ deviceId: 'node-2', zoneId: 'zone-b', soilMoisturePct: 50, temperatureC: 30, humidityPct: 60, rainfallMm: 0, waterLevelPct: 10 });
    assert.ok(added.capturedAt);
    assert.equal(store.latestReading('zone-b').deviceId, 'node-2');
  });

  it('latestReading returns the most recent for a zone', () => {
    const store = new FarmStore(makeSeed());
    store.addReading({ deviceId: 'node-2', zoneId: 'zone-a', soilMoisturePct: 80, temperatureC: 22, humidityPct: 40, rainfallMm: 0, waterLevelPct: 5 });
    assert.equal(store.latestReading('zone-a').deviceId, 'node-2');
  });

  it('history respects the limit parameter', () => {
    const store = new FarmStore(makeSeed());
    for (let i = 0; i < 10; i++) {
      store.addReading({ deviceId: `n-${i}`, zoneId: 'zone-a', soilMoisturePct: i, temperatureC: 20, humidityPct: 50, rainfallMm: 0, waterLevelPct: 0 });
    }
    assert.equal(store.history('zone-a', 3).length, 3);
  });
});

// ── Observations ────────────────────────────────────────────────────────────

describe('FarmStore — observations', () => {
  it('addObservation stores with an id and capturedAt', () => {
    const store = new FarmStore(makeSeed());
    const obs = store.addObservation({ kind: 'pest', label: 'whitefly', confidence: 0.9, count: 2, zoneId: 'zone-a' });
    assert.ok(obs.id.startsWith('obs-'));
    assert.ok(obs.capturedAt);
  });

  it('zoneObservations returns only the requested zone', () => {
    const store = new FarmStore(makeSeed());
    store.addObservation({ kind: 'pest', label: 'whitefly', confidence: 0.9, count: 2, zoneId: 'zone-a' });
    store.addObservation({ kind: 'pest', label: 'aphid', confidence: 0.7, count: 1, zoneId: 'zone-b' });
    assert.equal(store.zoneObservations('zone-a').length, 1);
    assert.equal(store.zoneObservations('zone-b').length, 1);
  });

  it('zoneObservations respects the limit', () => {
    const store = new FarmStore(makeSeed());
    for (let i = 0; i < 20; i++) {
      store.addObservation({ kind: 'pest', label: `bug-${i}`, confidence: 0.8, count: 1, zoneId: 'zone-a' });
    }
    assert.equal(store.zoneObservations('zone-a', 5).length, 5);
  });
});

// ── Zones ───────────────────────────────────────────────────────────────────

describe('FarmStore — zones', () => {
  it('returns distinct zone ids from readings', () => {
    const store = new FarmStore(makeSeed());
    store.addReading({ deviceId: 'n2', zoneId: 'zone-b', soilMoisturePct: 50, temperatureC: 30, humidityPct: 60, rainfallMm: 0, waterLevelPct: 10 });
    const zones = store.zones();
    assert.ok(zones.includes('zone-a'));
    assert.ok(zones.includes('zone-b'));
    assert.equal(zones.length, 2);
  });
});

// ── Irrigation ──────────────────────────────────────────────────────────────

describe('FarmStore — irrigation', () => {
  it('createIrrigationRequest creates a pending request', () => {
    const store = new FarmStore(makeSeed());
    const req = store.createIrrigationRequest('zone-a', 'farmer');
    assert.ok(req.id.startsWith('irrigation-'));
    assert.equal(req.status, 'pending');
    assert.equal(req.zoneId, 'zone-a');
    assert.equal(req.approvedAt, null);
  });

  it('approveIrrigationRequest transitions to approved', () => {
    const store = new FarmStore(makeSeed());
    const req = store.createIrrigationRequest('zone-a', 'farmer');
    const approved = store.approveIrrigationRequest(req.id, 'supervisor');
    assert.equal(approved.status, 'approved');
    assert.equal(approved.approvedBy, 'supervisor');
    assert.ok(approved.approvedAt);
  });

  it('approveIrrigationRequest returns null for unknown id', () => {
    const store = new FarmStore(makeSeed());
    assert.equal(store.approveIrrigationRequest('does-not-exist'), null);
  });

  it('cannot approve an already-approved request', () => {
    const store = new FarmStore(makeSeed());
    const req = store.createIrrigationRequest('zone-a', 'farmer');
    store.approveIrrigationRequest(req.id, 'supervisor');
    const again = store.approveIrrigationRequest(req.id, 'other');
    // Returns the request but doesn't re-approve (status stays approved, approvedBy unchanged)
    assert.equal(again.status, 'approved');
    assert.equal(again.approvedBy, 'supervisor');
  });
});
