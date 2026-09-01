import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { execFile } from 'node:child_process';
import util from 'node:util';
import { buildFallbackAdvisories, validateObservation, validateReading } from './advisory.js';
import { FarmStore } from './store.js';

const execFileAsync = util.promisify(execFile);
const port = Number(process.env.PORT || 3001);
const riskServiceUrl = process.env.RISK_SERVICE_URL;
const store = new FarmStore({ deviceId: 'demo-node-01', zoneId: 'zone-a', soilMoisturePct: 24, temperatureC: 34, humidityPct: 55, rainfallMm: 0, waterLevelPct: 12, capturedAt: new Date().toISOString() });

function send(response, status, body) {
  response.writeHead(status, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' });
  response.end(status === 204 ? undefined : JSON.stringify(body));
}

function readJson(request) {
  return new Promise((resolve, reject) => {
    let body = '';
    request.on('data', (chunk) => { body += chunk; if (body.length > 100_000) request.destroy(); });
    request.on('end', () => { try { resolve(body ? JSON.parse(body) : {}); } catch { reject(new Error('Body must be valid JSON.')); } });
    request.on('error', reject);
  });
}

function readBuffer(request, limit = 5_000_000) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let length = 0;
    request.on('data', (chunk) => {
      chunks.push(chunk);
      length += chunk.length;
      if (length > limit) request.destroy(new Error('Payload too large. Max 5MB allowed.'));
    });
    request.on('end', () => resolve(Buffer.concat(chunks)));
    request.on('error', reject);
  });
}

async function advisoriesFor(reading, observations) {
  const fallback = buildFallbackAdvisories(reading, observations);
  if (!riskServiceUrl) return { advisories: fallback, source: 'edge-fallback' };
  const pests = observations.filter((item) => item.kind === 'pest').map(({ label, confidence, count }) => ({ label, confidence, count }));
  try {
    const result = await fetch(`${riskServiceUrl.replace(/\/$/, '')}/v1/risk/evaluate`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, signal: AbortSignal.timeout(1200), body: JSON.stringify({ reading, pests }) });
    if (!result.ok) throw new Error(`Risk service returned ${result.status}`);
    const data = await result.json();
    const cropAdvisories = fallback.filter((item) => item.type === 'crop_health');
    return { advisories: [...data.advisories, ...cropAdvisories], source: 'pest-risk-service' };
  } catch {
    return { advisories: fallback, source: 'edge-fallback' };
  }
}

async function farmState(zoneId) {
  const reading = store.latestReading(zoneId);
  if (!reading) return null;
  const observations = store.zoneObservations(zoneId);
  const result = await advisoriesFor(reading, observations);
  return { zoneId, reading, observations, ...result, irrigationRequests: store.irrigationRequests.filter((item) => item.zoneId === zoneId).slice(-10).reverse() };
}

http.createServer(async (request, response) => {
  if (request.method === 'OPTIONS') return send(response, 204, {});
  const url = new URL(request.url, `http://${request.headers.host}`);
  const zoneId = url.searchParams.get('zoneId') ?? 'zone-a';
  try {
    if (request.method === 'GET' && url.pathname === '/health') return send(response, 200, { status: 'ok', service: 'edge-api', mode: 'offline-first', riskService: riskServiceUrl ? 'configured' : 'fallback' });
    if (request.method === 'GET' && url.pathname === '/v1/zones') return send(response, 200, { zones: store.zones() });
    if (request.method === 'GET' && url.pathname === '/v1/farm-state') { const state = await farmState(zoneId); return state ? send(response, 200, state) : send(response, 404, { error: 'Unknown zone.' }); }
    if (request.method === 'GET' && url.pathname === '/v1/history') return send(response, 200, { zoneId, readings: store.history(zoneId, Math.min(Number(url.searchParams.get('limit') ?? 24), 100)) });
    if (request.method === 'POST' && url.pathname === '/v1/readings') { const reading = store.addReading(validateReading(await readJson(request))); const state = await farmState(reading.zoneId); return send(response, 201, state); }
    if (request.method === 'POST' && url.pathname === '/v1/observations') { const observation = store.addObservation(validateObservation(await readJson(request))); const state = await farmState(observation.zoneId); return send(response, 201, { observation, ...state }); }
    if (request.method === 'POST' && url.pathname === '/v1/irrigation/requests') { const body = await readJson(request); const requestRecord = store.createIrrigationRequest(String(body.zoneId ?? zoneId), String(body.requestedBy ?? 'farmer')); return send(response, 201, { request: requestRecord, note: 'Approval is recorded only. Firmware must acknowledge any physical pump action separately.' }); }
    const approval = url.pathname.match(/^\/v1\/irrigation\/requests\/([^/]+)\/approve$/);
    if (request.method === 'POST' && approval) { const body = await readJson(request); const requestRecord = store.approveIrrigationRequest(approval[1], String(body.approvedBy ?? 'farmer')); return requestRecord ? send(response, 200, { request: requestRecord, note: 'Approved request is not a direct pump command.' }) : send(response, 404, { error: 'Irrigation request not found.' }); }
    if (request.method === 'POST' && url.pathname === '/v1/crop-health') {
      const buf = await readBuffer(request);
      if (buf.length === 0) return send(response, 400, { error: 'No image provided.' });
      const tmpPath = path.join(os.tmpdir(), `crop-health-${crypto.randomUUID()}.jpg`);
      await fs.writeFile(tmpPath, buf);
      try {
        const mlDir = path.resolve(process.cwd(), '../../ml/vision');
        const pythonExecutable = os.platform() === 'win32' ? '.venv\\Scripts\\python.exe' : '.venv/bin/python';
        const { stdout } = await execFileAsync(pythonExecutable, ['-m', 'src.inference', tmpPath], { cwd: mlDir });
        const lines = stdout.trim().split('\n');
        const result = JSON.parse(lines[lines.length - 1]);
        if (result.confidence >= 0.5 && result.label !== 'invalid_image' && result.label !== 'healthy') {
          const observation = store.addObservation({ kind: 'crop_health', label: result.label, confidence: result.confidence, zoneId });
          const state = await farmState(observation.zoneId);
          return send(response, 200, { result, state });
        }
        return send(response, 200, { result });
      } catch (err) {
        return send(response, 500, { error: 'Inference failed', details: err.message });
      } finally {
        await fs.unlink(tmpPath).catch(() => {});
      }
    }
    return send(response, 404, { error: 'Not found.' });
  } catch (error) {
    return send(response, 400, { error: error.message ?? 'Invalid request.' });
  }
}).listen(port, () => console.log(`Citadel edge API listening on http://localhost:${port}`));
