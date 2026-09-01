import http from 'node:http';

const port = Number(process.env.PORT || 3000);
const html = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Citadel Farm Dashboard</title><style>body{font-family:system-ui;background:#f4f7f1;color:#1b2b1d;margin:0}main{max-width:900px;margin:48px auto;padding:24px}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.card{background:#fff;border-radius:12px;padding:18px;box-shadow:0 2px 10px #18241818}.alert{border-left:5px solid #d88900}small{color:#5f6a60}</style></head><body><main><h1>Citadel <small>Farm dashboard</small></h1><p id="status">Connecting to field node…</p><section id="metrics" class="grid"></section><h2>Recommended actions</h2><section id="alerts"></section></main><script>const api='http://localhost:3001/v1/farm-state';const el=(tag,text,cls='')=>{const n=document.createElement(tag);n.className=cls;n.textContent=text;return n};async function load(){try{const data=await fetch(api).then(r=>r.json());status.textContent='Live edge-node data · '+new Date(data.reading.capturedAt).toLocaleTimeString();metrics.replaceChildren(...[['Soil moisture',data.reading.soilMoisturePct+'%'],['Temperature',data.reading.temperatureC+'°C'],['Humidity',data.reading.humidityPct+'%']].map(([a,b])=>{const n=el('article','', 'card');n.append(el('small',a),el('h2',b));return n}));alerts.replaceChildren(...(data.advisories.length?data.advisories.map(x=>el('article',x.title+' — '+x.message,'card alert')):[el('article','No urgent action required.','card')]));}catch(e){status.textContent='Field node unavailable. Start the edge API on port 3001.'}}load();setInterval(load,10000)</script></body></html>`;

http.createServer((request, response) => {
  if (request.url === '/' || request.url === '/index.html') {
    response.setHeader('Content-Type', 'text/html; charset=utf-8');
    response.end(html);
    return;
  }
  response.statusCode = 404;
  response.end('Not found');
}).listen(port, () => console.log(`Citadel webapp listening on http://localhost:${port}`));
