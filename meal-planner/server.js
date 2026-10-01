import { createServer } from 'node:http';

import { loadEnvFile, settings } from './src/config.js';
import { page } from './src/web/layout.js';
import { Router } from './src/web/router.js';
import { statusPage } from './src/web/pages/status.js';

loadEnvFile();

const router = new Router().get(/^\/$/, statusPage);

function send(response, status, html) {
  response.writeHead(status, { 'Content-Type': 'text/html; charset=utf-8' });
  response.end(html);
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url, 'http://localhost');
  const match = router.match(request.method, url.pathname);

  if (!match) {
    send(response, 404, page({ title: 'Not found', body: '<h2>Not found</h2>' }));
    return;
  }

  try {
    send(response, 200, await match.handler({ request, url, params: match.params }));
  } catch (error) {
    console.error(error);
    send(response, 500, page({
      title: 'Error',
      body: `<h2>Something went wrong</h2><pre>${error.message}</pre>`,
    }));
  }
});

const { port } = settings();

server.listen(port, '127.0.0.1', () => {
  console.log(`Meal planner is running on http://localhost:${port}`);
});
