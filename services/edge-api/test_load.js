import fs from 'node:fs/promises';
import path from 'node:path';
import { performance } from 'node:perf_hooks';

const API_URL = 'http://localhost:3001/v1';

async function postImage(filepath) {
  const body = await fs.readFile(filepath);
  const start = performance.now();
  const res = await fetch(`${API_URL}/crop-health`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/octet-stream' },
    body
  });
  const json = await res.json();
  const end = performance.now();
  return { status: res.status, json, latency: end - start };
}

async function runLoadTest() {
  const mlDir = path.resolve(process.cwd(), '../../ml/vision');
  const healthySample = path.join(mlDir, 'datasets/crop_health/test/healthy/06040967-7b02-43b5-a3fc-4490a9a7ded6___RS_HL 0508.JPG');

  console.log('--- Phase 8 Load Test ---');
  console.log('Sending 20 concurrent requests...');
  
  const promises = [];
  for (let i = 0; i < 20; i++) {
    promises.push(postImage(healthySample));
  }

  const results = await Promise.all(promises);
  
  const latencies = results.map(r => r.latency).sort((a, b) => a - b);
  const median = latencies[Math.floor(latencies.length / 2)];
  const max = latencies[latencies.length - 1];
  const min = latencies[0];

  console.log(`Successfully completed ${results.length} requests.`);
  console.log(`Median Latency: ${median.toFixed(2)} ms`);
  console.log(`Min Latency: ${min.toFixed(2)} ms`);
  console.log(`Max Latency: ${max.toFixed(2)} ms`);

  const failed = results.filter(r => r.status !== 200);
  if (failed.length > 0) {
    console.error(`ERROR: ${failed.length} requests failed!`);
    console.error(failed[0]);
    process.exit(1);
  } else {
    console.log('All requests returned 200 OK.');
  }

  // Check tmp dir for orphans
  const os = await import('node:os');
  const tmpFiles = await fs.readdir(os.tmpdir());
  const orphans = tmpFiles.filter(f => f.startsWith('crop-health-'));
  console.log(`Orphaned tmp files found: ${orphans.length}`);
  if (orphans.length > 0) {
    process.exit(1);
  }
}

runLoadTest().catch(console.error);
