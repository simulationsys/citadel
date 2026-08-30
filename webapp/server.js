import http from 'node:http';

const port = Number(process.env.PORT || 3000);
const html = `<!doctype html><html><head><meta charset="utf-8"><title>Citadel</title></head><body><main><h1>Citadel</h1><p>Webapp is ready.</p></main></body></html>`;

http.createServer((request, response) => {
  if (request.url === '/' || request.url === '/index.html') {
    response.setHeader('Content-Type', 'text/html; charset=utf-8');
    response.end(html);
    return;
  }
  response.statusCode = 404;
  response.end('Not found');
}).listen(port, () => console.log(`Citadel webapp listening on http://localhost:${port}`));
