import http from 'node:http';

const port = Number(process.env.PORT || 3001);

const server = http.createServer((request, response) => {
  response.setHeader('Content-Type', 'application/json');
  if (request.url === '/health') {
    response.end(JSON.stringify({ status: 'ok', service: 'citadel-app' }));
    return;
  }
  response.statusCode = 404;
  response.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(port, () => console.log(`Citadel app listening on http://localhost:${port}`));
