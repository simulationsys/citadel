import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { validateReading, validateObservation, buildFallbackAdvisories } from './advisory.js';

// ── validateReading ─────────────────────────────────────────────────────────

describe('validateReading', () => {
  const validReading = {
    deviceId: 'node-1',
    zoneId: 'zone-a',
    soilMoisturePct: 45,
    temperatureC: 28,
    humidityPct: 60,
    rainfallMm: 5,
    waterLevelPct: 20,
  };

  it('accepts a valid reading and returns normalised fields', () => {
    const result = validateReading(validReading);
    assert.equal(result.deviceId, 'node-1');
    assert.equal(result.zoneId, 'zone-a');
    assert.equal(result.soilMoisturePct, 45);
    assert.equal(result.temperatureC, 28);
    assert.equal(result.humidityPct, 60);
    assert.equal(result.rainfallMm, 5);
    assert.equal(result.waterLevelPct, 20);
  });

  it('defaults zoneId to zone-a when missing', () => {
    const { zoneId, ...rest } = validReading;
    const result = validateReading(rest);
    assert.equal(result.zoneId, 'zone-a');
  });

  it('throws when deviceId is missing', () => {
    assert.throws(() => validateReading({ ...validReading, deviceId: '' }), /deviceId/);
  });

  it('throws when soilMoisturePct exceeds 100', () => {
    assert.throws(() => validateReading({ ...validReading, soilMoisturePct: 101 }), /soilMoisturePct/);
  });

  it('throws when humidityPct is negative', () => {
    assert.throws(() => validateReading({ ...validReading, humidityPct: -1 }), /humidityPct/);
  });

  it('throws when temperatureC is not a number', () => {
    assert.throws(() => validateReading({ ...validReading, temperatureC: 'hot' }), /temperatureC/);
  });

  it('throws when rainfallMm is negative', () => {
    assert.throws(() => validateReading({ ...validReading, rainfallMm: -5 }), /rainfallMm/);
  });
});

// ── validateObservation ─────────────────────────────────────────────────────

describe('validateObservation', () => {
  const validObservation = {
    kind: 'pest',
    label: 'whitefly',
    confidence: 0.85,
    count: 3,
    zoneId: 'zone-a',
  };

  it('accepts a valid observation', () => {
    const result = validateObservation(validObservation);
    assert.equal(result.kind, 'pest');
    assert.equal(result.label, 'whitefly');
    assert.equal(result.confidence, 0.85);
    assert.equal(result.count, 3);
  });

  it('throws for an unsupported kind', () => {
    assert.throws(() => validateObservation({ ...validObservation, kind: 'weather' }), /kind/);
  });

  it('throws when label is empty', () => {
    assert.throws(() => validateObservation({ ...validObservation, label: '' }), /label/);
  });

  it('throws when confidence is above 1', () => {
    assert.throws(() => validateObservation({ ...validObservation, confidence: 1.5 }), /confidence/);
  });

  it('throws when confidence is below 0', () => {
    assert.throws(() => validateObservation({ ...validObservation, confidence: -0.1 }), /confidence/);
  });

  it('throws when count is negative', () => {
    assert.throws(() => validateObservation({ ...validObservation, count: -1 }), /count/);
  });
});

// ── buildFallbackAdvisories ─────────────────────────────────────────────────

describe('buildFallbackAdvisories', () => {
  const baseReading = {
    soilMoisturePct: 50,
    temperatureC: 25,
    humidityPct: 50,
    rainfallMm: 0,
    waterLevelPct: 10,
  };

  it('returns no advisories for normal conditions', () => {
    const advisories = buildFallbackAdvisories(baseReading);
    assert.equal(advisories.length, 0);
  });

  it('returns a flood advisory when waterLevelPct >= 75', () => {
    const advisories = buildFallbackAdvisories({ ...baseReading, waterLevelPct: 80 });
    const types = advisories.map((a) => a.type);
    assert.ok(types.includes('flood'));
    assert.ok(!types.includes('irrigation'));
  });

  it('returns a flood advisory when rainfallMm >= 30', () => {
    const advisories = buildFallbackAdvisories({ ...baseReading, rainfallMm: 35 });
    assert.ok(advisories.some((a) => a.type === 'flood'));
  });

  it('returns an irrigation advisory when soilMoisturePct < 30 and no flood', () => {
    const advisories = buildFallbackAdvisories({ ...baseReading, soilMoisturePct: 20 });
    assert.ok(advisories.some((a) => a.type === 'irrigation'));
  });

  it('returns a heat advisory when temperatureC >= 38 and soilMoisturePct < 40', () => {
    const advisories = buildFallbackAdvisories({ ...baseReading, temperatureC: 40, soilMoisturePct: 30 });
    assert.ok(advisories.some((a) => a.type === 'heat'));
  });

  it('returns a disease_risk advisory when humidityPct >= 85 and temperatureC >= 20', () => {
    const advisories = buildFallbackAdvisories({ ...baseReading, humidityPct: 90, temperatureC: 25 });
    assert.ok(advisories.some((a) => a.type === 'disease_risk'));
  });

  it('returns a pest advisory for high-confidence pest observation', () => {
    const observations = [{ kind: 'pest', label: 'whitefly', confidence: 0.8, count: 4 }];
    const advisories = buildFallbackAdvisories(baseReading, observations);
    const pest = advisories.find((a) => a.type === 'pest');
    assert.ok(pest);
    assert.equal(pest.severity, 'warning'); // count >= 3
  });

  it('does not return a pest advisory for low-confidence observation', () => {
    const observations = [{ kind: 'pest', label: 'whitefly', confidence: 0.3, count: 1 }];
    const advisories = buildFallbackAdvisories(baseReading, observations);
    assert.ok(!advisories.some((a) => a.type === 'pest'));
  });

  it('returns a crop_health warning for disease observation', () => {
    const observations = [{ kind: 'crop_health', label: 'early_blight', confidence: 0.75, count: 1 }];
    const advisories = buildFallbackAdvisories(baseReading, observations);
    const ch = advisories.find((a) => a.type === 'crop_health');
    assert.ok(ch);
    assert.equal(ch.severity, 'warning');
  });

  it('returns a recapture advisory for inconclusive crop health', () => {
    const observations = [{ kind: 'crop_health', label: 'inconclusive', confidence: 0.4, count: 1 }];
    const advisories = buildFallbackAdvisories(baseReading, observations);
    const ch = advisories.find((a) => a.type === 'crop_health');
    assert.ok(ch);
    assert.equal(ch.severity, 'info');
    assert.ok(ch.message.includes('clearer'));
  });
});
