import http from 'node:http';
const port = Number(process.env.PORT || 3002);
http.createServer((_, response) => { response.writeHead(200, { 'Content-Type': 'application/json' }); response.end(JSON.stringify({ service: 'cloud-api', status: 'placeholder', next: 'persist farm readings and accept delayed edge sync batches' })); }).listen(port, () => console.log(`Citadel cloud API listening on http://localhost:${port}`));
