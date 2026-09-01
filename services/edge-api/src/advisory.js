export function buildAdvisories(readings) {
  const advisories = [];
  if (readings.soilMoisturePct < 30 && readings.rainfallMm < 2) advisories.push({ type: 'irrigation', severity: 'warning', title: 'Irrigate now', message: 'Low soil moisture detected. Irrigate this zone for 15 minutes.', action: 'START_IRRIGATION' });
  if (readings.temperatureC >= 38 && readings.soilMoisturePct < 40) advisories.push({ type: 'heat', severity: 'warning', title: 'Heat-stress risk', message: 'High temperature and dry soil. Irrigate during cooler hours.', action: 'SCHEDULE_EVENING_IRRIGATION' });
  if (readings.waterLevelPct >= 75 || readings.rainfallMm >= 30) advisories.push({ type: 'flood', severity: 'critical', title: 'Flood-risk alert', message: 'High water level or intense rainfall detected. Check drainage immediately.', action: 'CHECK_DRAINAGE' });
  return advisories;
}
