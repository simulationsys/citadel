import http from 'node:http';

const port = Number(process.env.PORT || 3000);
const html = `<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Citadel Farm Dashboard</title>
<style>:root{color:#183d23;background:#f4f7f1;font-family:system-ui}body{margin:0}main{max-width:980px;margin:36px auto;padding:24px}.top{display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:14px}.card{background:#fff;border-radius:12px;padding:16px;box-shadow:0 2px 10px #18241818}.alert{border-left:5px solid #d88900;margin:8px 0;padding:10px;background:#fff}.critical{border-left-color:#bf3325}.muted{color:#5f6a60}button,select{font:inherit;padding:9px 12px;border-radius:8px;border:1px solid #b7c4b7;background:#fff}button{background:#1d6d35;color:#fff;border:0;cursor:pointer}ul{padding-left:20px}small{color:#5f6a60}.pill{display:inline-block;background:#e3f1e4;padding:4px 8px;border-radius:99px;font-size:.8rem}</style>
</head><body><main>
<div class="top"><div><h1>Citadel <small>Farm dashboard</small></h1><p id="status" class="muted">Connecting to field node...</p></div><label>Zone <select id="zone"></select></label></div>
<section id="metrics" class="grid"></section>
<section class="card"><h2>Recommended actions <span id="source" class="pill"></span></h2><div id="alerts"></div><button id="review">Request irrigation review</button><p id="requestStatus" class="muted"></p></section>
<section class="grid"><article class="card"><h2>Recent readings</h2><ul id="history"></ul></article><article class="card"><h2>Recent observations</h2><ul id="observations"></ul></article></section>
</main><script>
const api='http://localhost:3001/v1';
const byId=id=>document.getElementById(id);
const status=byId('status'), zone=byId('zone'), source=byId('source'), metrics=byId('metrics'), alerts=byId('alerts'), observations=byId('observations'), historyList=byId('history'), review=byId('review'), requestStatus=byId('requestStatus');
let selected='zone-a';
const el=(tag,text,cls='')=>{const node=document.createElement(tag);node.className=cls;node.textContent=text;return node};
async function json(url, options){const response=await fetch(url,options);if(!response.ok){const body=await response.json();throw new Error(body.error||'Request failed')}return response.json()}
function metric(label,value){const box=el('article','card');box.append(el('small',label),el('h2',value));return box}
async function loadZones(){const data=await json(api+'/zones');zone.replaceChildren(...data.zones.map(id=>{const option=document.createElement('option');option.value=id;option.textContent=id;option.selected=id===selected;return option}))}
async function load(){try{const data=await json(api+'/farm-state?zoneId='+encodeURIComponent(selected));status.textContent='Local edge data · '+new Date(data.reading.capturedAt).toLocaleTimeString();source.textContent=data.source==='pest-risk-service'?'risk service live':'local fallback';metrics.replaceChildren(metric('Soil moisture',data.reading.soilMoisturePct+'%'),metric('Temperature',data.reading.temperatureC+'°C'),metric('Humidity',data.reading.humidityPct+'%'),metric('Rainfall',data.reading.rainfallMm+' mm'));alerts.replaceChildren(...(data.advisories.length?data.advisories.map(item=>el('article',item.title+' — '+item.message,'alert '+(item.severity==='critical'?'critical':'')):[el('p','No urgent action required.','muted')]));observations.replaceChildren(...(data.observations.length?data.observations.map(item=>el('li',item.kind+': '+item.label+' ('+Math.round(item.confidence*100)+'%)')):[el('li','No recent AI observations.','muted')]));const history=await json(api+'/history?zoneId='+encodeURIComponent(selected)+'&limit=6');const items=history.readings.map(item=>el('li',new Date(item.capturedAt).toLocaleTimeString()+' — '+item.soilMoisturePct+'% soil, '+item.temperatureC+'°C'));historyList.replaceChildren(...(items.length?items:[el('li','No readings yet.','muted')]));}catch(error){status.textContent='Field node unavailable: '+error.message}}
zone.addEventListener('change',async event=>{selected=event.target.value;await load()});
review.addEventListener('click',async()=>{try{const data=await json(api+'/irrigation/requests',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({zoneId:selected,requestedBy:'dashboard-operator'})});requestStatus.textContent='Review '+data.request.id+' recorded. A hardware action still needs explicit approval.'}catch(error){requestStatus.textContent=error.message}});
Promise.all([loadZones(),load()]).catch(error=>status.textContent=error.message);setInterval(load,10000);
</script></body></html>`;

http.createServer((request, response) => {
  if (request.url === '/' || request.url === '/index.html') { response.setHeader('Content-Type', 'text/html; charset=utf-8'); response.end(html); return; }
  response.statusCode = 404;
  response.end('Not found');
}).listen(port, () => console.log(`Citadel dashboard listening on http://localhost:${port}`));
