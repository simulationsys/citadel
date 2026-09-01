const MAX_HISTORY = 500;

export class FarmStore {
  constructor(seed) { this.readings = [seed]; this.observations = []; this.irrigationRequests = []; }
  addReading(reading) { const stored = { ...reading, capturedAt: new Date().toISOString() }; this.readings.push(stored); if (this.readings.length > MAX_HISTORY) this.readings.shift(); return stored; }
  addObservation(observation) { const stored = { ...observation, id: `obs-${Date.now()}-${this.observations.length}`, capturedAt: new Date().toISOString() }; this.observations.push(stored); if (this.observations.length > MAX_HISTORY) this.observations.shift(); return stored; }
  latestReading(zoneId = 'zone-a') { return [...this.readings].reverse().find((reading) => reading.zoneId === zoneId) ?? null; }
  zoneObservations(zoneId, limit = 10) { return this.observations.filter((item) => item.zoneId === zoneId).slice(-limit).reverse(); }
  history(zoneId, limit = 24) { return this.readings.filter((reading) => reading.zoneId === zoneId).slice(-limit); }
  zones() { return [...new Set(this.readings.map((reading) => reading.zoneId))]; }
  createIrrigationRequest(zoneId, requestedBy = 'farmer') { const request = { id: `irrigation-${Date.now()}-${this.irrigationRequests.length}`, zoneId, requestedBy, status: 'pending', createdAt: new Date().toISOString(), approvedAt: null }; this.irrigationRequests.push(request); return request; }
  approveIrrigationRequest(id, approvedBy = 'farmer') { const request = this.irrigationRequests.find((item) => item.id === id); if (!request || request.status !== 'pending') return request ?? null; request.status = 'approved'; request.approvedBy = approvedBy; request.approvedAt = new Date().toISOString(); return request; }
}
