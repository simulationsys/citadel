import fs from 'node:fs/promises';
import path from 'node:path';

const API_URL = 'http://localhost:3001/v1';

async function testImage(label, filepath) {
  let body;
  try {
    body = await fs.readFile(filepath);
  } catch(e) {
    console.log(`[SKIP] ${label}: File not found ${filepath}`);
    return;
  }
  
  const res = await fetch(`${API_URL}/crop-health`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/octet-stream' },
    body
  });
  
  const json = await res.json();
  console.log(`--- Field Image: ${label} ---`);
  console.log(JSON.stringify(json, null, 2));
}

async function run() {
  const mlDir = path.resolve(process.cwd(), '../../ml/vision');
  
  const testImages = [
    { label: 'healthy_tomato', path: 'datasets/crop_health/test/healthy/06040967-7b02-43b5-a3fc-4490a9a7ded6___RS_HL 0508.JPG' },
    { label: 'early_blight', path: 'datasets/crop_health/test/early_blight/0012b9d2-2130-4a06-a834-b1f3af34f57e___RS_Erly.B 8389.JPG' },
    { label: 'late_blight', path: 'datasets/crop_health/test/late_blight/0003faa8-4b27-4c65-bf42-6d9e352ca1a5___RS_Late.B 4946.JPG' },
    { label: 'leaf_spot', path: 'datasets/crop_health/test/leaf_spot/002213fb-b620-4593-b9ac-6a6c119f150d___MI81.P.3 3972.JPG' },
    { label: 'yellow_leaf_curl', path: 'datasets/crop_health/test/yellow_leaf_curl_virus/0009210e-862d-4d76-bf10-5390ebde852a___YLCV_GCREC 2217.JPG' }
  ];

  for (const img of testImages) {
    await testImage(img.label, path.join(mlDir, img.path));
  }

  // Test the uploaded media artifacts (simulating user phone non-leaf/UI captures)
  const artifactsDir = 'C:\\Users\\bham0\\.gemini\\antigravity-ide\\brain\\0c5fbba6-8b7d-4112-8c77-ca7ad9083584\\.user_uploaded';
  const artifacts = [
    { label: 'user_uploaded_1', path: path.join(artifactsDir, 'media_1788288132069.png') },
    { label: 'user_uploaded_2', path: path.join(artifactsDir, 'media_1788288239681.png') },
    { label: 'user_uploaded_3', path: path.join(artifactsDir, 'media_1788288530238.png') }
  ];

  for (const img of artifacts) {
    await testImage(img.label, img.path);
  }
}

run().catch(console.error);
