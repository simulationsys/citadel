import fs from 'node:fs/promises';
import path from 'node:path';

const API_URL = 'http://localhost:3001/v1';

async function postImage(filepath) {
  let body;
  try {
    body = await fs.readFile(filepath);
  } catch {
    body = Buffer.alloc(0); // simulate missing or just pass empty
  }
  
  const res = await fetch(`${API_URL}/crop-health`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/octet-stream' },
    body
  });
  
  let json;
  try {
    json = await res.json();
  } catch {
    json = await res.text();
  }
  
  return { status: res.status, json };
}

async function getFarmState() {
  const res = await fetch(`${API_URL}/farm-state?zoneId=zone-a`);
  return { status: res.status, json: await res.json() };
}

async function runTests() {
  let passed = 0;
  let failed = 0;

  function assert(name, condition, details = '') {
    if (condition) {
      console.log(`[PASS] ${name}`);
      passed++;
    } else {
      console.log(`[FAIL] ${name} - ${details}`);
      failed++;
    }
  }

  const mlDir = path.resolve(process.cwd(), '../../ml/vision');
  const healthySample = path.join(mlDir, 'datasets/crop_health/test/healthy/06040967-7b02-43b5-a3fc-4490a9a7ded6___RS_HL 0508.JPG');
  
  // Wait for server to be up
  try { await fetch(`${API_URL}/health`); } catch {
    console.log("Server not running.");
    process.exit(1);
  }

  console.log('--- SCENARIO A: Healthy Leaf ---');
  let res = await postImage(healthySample);
  assert('Healthy response OK', res.status === 200, res.status);
  assert('Healthy label correct', res.json?.result?.label === 'healthy');
  assert('No latency leak', res.json?.result?._latency_ms === undefined);
  
  let stateRes = await getFarmState();
  let observations = stateRes.json.observations || [];
  let advisories = stateRes.json.advisories || [];
  // Healthy should NOT produce an observation or advisory
  let hasHealthyObs = observations.some(o => o.label === 'healthy');
  assert('Healthy produces NO observation', !hasHealthyObs);

  console.log('--- SCENARIO B: Disease Leaf ---');
  const diseaseSample = path.join(mlDir, 'datasets/crop_health/test/early_blight/0012b9d2-2130-4a06-a834-b1f3af34f57e___RS_Erly.B 8389.JPG');
  res = await postImage(diseaseSample);
  assert('Disease response OK', res.status === 200, res.status);
  assert('Disease label correct', res.json?.result?.label === 'early_blight');
  
  stateRes = await getFarmState();
  observations = stateRes.json.observations || [];
  advisories = stateRes.json.advisories || [];
  let hasDiseaseObs = observations.some(o => o.label === 'early_blight');
  assert('Disease produces observation', hasDiseaseObs);
  let hasDiseaseAdvisory = advisories.some(a => a.type === 'crop_health' && a.severity === 'warning');
  assert('Disease produces warning advisory', hasDiseaseAdvisory);

  console.log('--- SCENARIO D/E/F: Image Rejection (Empty) ---');
  res = await postImage('does_not_exist.jpg');
  assert('Missing image status 400', res.status === 400, res.status);
  assert('Missing image error format', res.json?.error === 'invalid_request', res.json?.error);

  console.log('--- SCENARIO G: Missing Model ---');
  const modelPath = path.join(mlDir, 'models/crop_health_mobilenetv2.tflite');
  const tempPath = path.join(mlDir, 'models/crop_health_mobilenetv2.tflite.bak');
  
  await fs.rename(modelPath, tempPath);
  try {
    res = await postImage(healthySample);
    assert('Missing model status 503', res.status === 503, res.status);
    assert('Missing model error format', res.json?.error === 'model_unavailable', res.json?.error);
  } finally {
    await fs.rename(tempPath, modelPath);
  }

  console.log(`\nResults: ${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(console.error);
