import { createServer } from 'node:http';

import { loadEnvFile, settings } from './src/config.js';
import { page } from './src/web/layout.js';
import { Router } from './src/web/router.js';
import { statusPage } from './src/web/pages/status.js';
import {
  createRecipe,
  newRecipePage,
  parsePastedRecipe,
  recipePage,
  recipesPage,
  runSync,
  updateRecipe,
} from './src/web/pages/recipes.js';

loadEnvFile();

const recipeId = /^\/recipes\/(?<id>[0-9a-fA-F-]{32,36})$/;

const router = new Router()
  .get(/^\/$/, statusPage)
  .get(/^\/recipes$/, recipesPage)
  .get(/^\/recipes\/new$/, newRecipePage)
  .post(/^\/recipes\/new$/, parsePastedRecipe)
  .post(/^\/recipes$/, createRecipe)
  .get(recipeId, recipePage)
  .post(recipeId, updateRecipe)
  .post(/^\/sync$/, runSync);

function sendHtml(response, status, html) {
  response.writeHead(status, { 'Content-Type': 'text/html; charset=utf-8' });
  response.end(html);
}

function respond(response, result) {
  if (result && typeof result === 'object' && result.redirect) {
    response.writeHead(303, { Location: result.redirect });
    response.end();
    return;
  }

  sendHtml(response, result?.status ?? 200, result?.html ?? result);
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url, 'http://localhost');
  const match = router.match(request.method, url.pathname);

  if (!match) {
    sendHtml(response, 404, page({
      title: 'Not found',
      body: '<h2>Not found</h2><p><a href="/recipes">Go to the recipes</a></p>',
    }));
    return;
  }

  try {
    respond(response, await match.handler({ request, url, params: match.params }));
  } catch (error) {
    console.error(error);
    sendHtml(response, 500, page({
      title: 'Error',
      body: `<h2>Something went wrong</h2><p>${error.message}</p>
        <p><a href="/recipes">Go to the recipes</a></p>`,
    }));
  }
});

const { port } = settings();

server.listen(port, '127.0.0.1', () => {
  console.log(`Meal planner is running on http://localhost:${port}`);
});
