import http from 'node:http';
import { buildAdvisories } from './advisory.js';

const port = Number(process.env.PORT || 3001);
let latest = { deviceId: 'demo-node-01', zoneId: 'zone-a', soilMoisturePct: 24, temperatureC: 34, humidityPct: 55, rainfallMm: 0, waterLevelPct: 12, capturedAt: new Date().toISOString() };
const send = (response, status, body) => { response.writeHead(status, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }); response.end(JSON.stringify(body)); };

http.createServer((request, response) => {
  if (request.method === 'OPTIONS') return send(response, 204, {});
  if (request.method === 'GET' && request.url === '/health') return send(response, 200, { status: 'ok', service: 'edge-api', mode: 'offline-first' });
  if (request.method === 'GET' && request.url === '/v1/farm-state') return send(response, 200, { reading: latest, advisories: buildAdvisories(latest) });
  if (request.method === 'POST' && request.url === '/v1/readings') {
    let payload = '';
    request.on('data', (chunk) => { payload += chunk; });
    request.on('end', () => { try { latest = { ...latest, ...JSON.parse(payload), capturedAt: new Date().toISOString() }; send(response, 201, { reading: latest, advisories: buildAdvisories(latest) }); } catch { send(response, 400, { error: 'Body must be valid JSON.' }); } });
    return;
  }
  return send(response, 404, { error: 'Not found' });
}).listen(port, () => console.log(`Citadel edge API listening on http://localhost:${port}`));
