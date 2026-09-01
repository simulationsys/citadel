const supportedObservationKinds = new Set(['pest', 'crop_health']);

export function validateReading(input) {
  const reading = { deviceId: String(input.deviceId ?? ''), zoneId: String(input.zoneId ?? 'zone-a'), soilMoisturePct: Number(input.soilMoisturePct), temperatureC: Number(input.temperatureC), humidityPct: Number(input.humidityPct), rainfallMm: Number(input.rainfallMm ?? 0), waterLevelPct: Number(input.waterLevelPct ?? 0) };
  if (!reading.deviceId) throw new Error('deviceId is required.');
  for (const key of ['soilMoisturePct', 'humidityPct', 'waterLevelPct']) if (!Number.isFinite(reading[key]) || reading[key] < 0 || reading[key] > 100) throw new Error(`${key} must be a number between 0 and 100.`);
  if (!Number.isFinite(reading.temperatureC)) throw new Error('temperatureC must be a number.');
  if (!Number.isFinite(reading.rainfallMm) || reading.rainfallMm < 0) throw new Error('rainfallMm must be zero or greater.');
  return reading;
}

export function validateObservation(input) {
  const observation = { kind: String(input.kind ?? ''), label: String(input.label ?? ''), confidence: Number(input.confidence), count: Number(input.count ?? 1), zoneId: String(input.zoneId ?? 'zone-a') };
  if (!supportedObservationKinds.has(observation.kind)) throw new Error('kind must be pest or crop_health.');
  if (!observation.label) throw new Error('label is required.');
  if (!Number.isFinite(observation.confidence) || observation.confidence < 0 || observation.confidence > 1) throw new Error('confidence must be between 0 and 1.');
  if (!Number.isInteger(observation.count) || observation.count < 0) throw new Error('count must be a non-negative integer.');
  return observation;
}

export function buildFallbackAdvisories(readings, observations = []) {
  const advisories = [];
  if (readings.waterLevelPct >= 75 || readings.rainfallMm >= 30) advisories.push({ type: 'flood', severity: 'critical', title: 'Flood-risk alert', message: 'High water level or intense rainfall detected. Check drainage and avoid irrigation.', action: 'CHECK_DRAINAGE' });
  else if (readings.soilMoisturePct < 30) advisories.push({ type: 'irrigation', severity: 'warning', title: 'Irrigate now', message: 'Low soil moisture detected. Inspect the zone and irrigate if conditions remain dry.', action: 'REVIEW_IRRIGATION' });
  if (readings.temperatureC >= 38 && readings.soilMoisturePct < 40) advisories.push({ type: 'heat', severity: 'warning', title: 'Heat-stress risk', message: 'High temperature and dry soil can stress the crop. Prefer irrigation during cooler hours.', action: 'SCHEDULE_EVENING_IRRIGATION' });
  if (readings.humidityPct >= 85 && readings.temperatureC >= 20) advisories.push({ type: 'disease_risk', severity: 'info', title: 'Humidity risk increasing', message: 'Warm, humid conditions can favour crop disease. Inspect leaves before treatment.', action: 'INSPECT_LEAVES' });
  for (const observation of observations) {
    if (observation.kind === 'pest' && observation.confidence >= 0.65) advisories.push({ type: 'pest', severity: observation.count >= 3 ? 'warning' : 'info', title: 'Pest activity detected', message: `Possible ${observation.label} activity was detected. Inspect affected plants and use targeted intervention only if confirmed.`, action: 'INSPECT_AFFECTED_PLANTS' });
    if (observation.kind === 'crop_health' && observation.label !== 'healthy' && observation.confidence >= 0.65) advisories.push({ type: 'crop_health', severity: 'warning', title: 'Possible crop-health issue', message: `Possible ${observation.label.replaceAll('_', ' ')} detected. Inspect nearby plants before treatment.`, action: 'INSPECT_LEAVES' });
  }
  return advisories;
}
