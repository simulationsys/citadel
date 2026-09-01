export const advisoryTypes = Object.freeze({ IRRIGATION: 'irrigation', DISEASE: 'disease', PEST: 'pest', HEAT: 'heat', FLOOD: 'flood' });

export function createSensorReading(input) {
  return { deviceId: input.deviceId, zoneId: input.zoneId ?? 'zone-a', capturedAt: input.capturedAt ?? new Date().toISOString(), soilMoisturePct: Number(input.soilMoisturePct), temperatureC: Number(input.temperatureC), humidityPct: Number(input.humidityPct), rainfallMm: Number(input.rainfallMm ?? 0), waterLevelPct: Number(input.waterLevelPct ?? 0) };
}
