import { readConfig, settings } from '../../config.js';
import { NotionClient } from '../../notion/client.js';
import { databaseBlueprints } from '../../notion/schema.js';
import { cacheAgeMinutes, readCache } from '../../store/cache.js';
import { escapeHtml, page } from '../layout.js';

function mark(isGood, goodText, badText) {
  const className = isGood ? 'ok' : 'bad';
  const symbol = isGood ? '&check;' : '&times;';

  return `<span class="${className}">${symbol} ${escapeHtml(isGood ? goodText : badText)}</span>`;
}

async function databaseRows(token, databaseIds) {
  const blueprints = databaseBlueprints();
  const client = databaseIds.recipes ? new NotionClient({ token }) : null;

  const rows = await Promise.all(blueprints.map(async (blueprint) => {
    const id = databaseIds[blueprint.key];

    if (!id) return { title: blueprint.title, id: null, reachable: false, detail: 'not created yet' };
    if (!client) return { title: blueprint.title, id, reachable: false, detail: 'not checked' };

    try {
      const database = await client.retrieveDatabase(id);
      const propertyCount = Object.keys(database.properties).length;

      return { title: blueprint.title, id, reachable: true, detail: `${propertyCount} properties` };
    } catch (error) {
      return { title: blueprint.title, id, reachable: false, detail: error.message };
    }
  }));

  return rows
    .map((row) => `<tr>
      <td>${escapeHtml(row.title)}</td>
      <td>${mark(row.reachable, 'reachable', row.detail)}</td>
      <td><code>${escapeHtml(row.id ?? '—')}</code></td>
    </tr>`)
    .join('');
}

function setupSteps() {
  return `<h2>Set it up</h2>
  <ol class="steps">
    <li>Create an internal integration at <code>notion.so/my-integrations</code> and copy its token.</li>
    <li>Copy <code>.env.example</code> to <code>.env</code>. Put the token in <code>NOTION_TOKEN</code>.</li>
    <li>Make a Notion page to hold the databases. Open its <em>&hellip;</em> menu, then
        <em>Connections</em>, then add your integration.</li>
    <li>Copy that page id from its URL into <code>NOTION_PARENT_PAGE_ID</code>.</li>
    <li>Run <code>npm run setup:notion</code>. It creates the three databases.</li>
    <li>Run <code>npm start</code> and open this page again.</li>
  </ol>`;
}

export async function statusPage() {
  const { token, parentPageId } = settings();
  const config = readConfig();
  const databaseIds = config.databases ?? {};
  const cache = readCache();
  const ageMinutes = cacheAgeMinutes(cache);
  const isConfigured = databaseBlueprints().every((blueprint) => databaseIds[blueprint.key]);

  const body = `<h2>Connection</h2>
  <table>
    <tbody>
      <tr><td>Integration token</td><td>${mark(Boolean(token), 'set', 'missing from .env')}</td></tr>
      <tr><td>Parent page</td><td>${mark(Boolean(parentPageId), 'set', 'missing from .env')}</td></tr>
      <tr><td>Databases</td><td>${mark(isConfigured, 'created', 'run npm run setup:notion')}</td></tr>
    </tbody>
  </table>

  <h2>Databases in Notion</h2>
  <table>
    <thead><tr><th>Database</th><th>State</th><th>Id</th></tr></thead>
    <tbody>${token ? await databaseRows(token, databaseIds) : '<tr><td colspan="3" class="note">Add a token first.</td></tr>'}</tbody>
  </table>

  <h2>Local cache</h2>
  <p>${cache.syncedAt
    ? `Last read from Notion ${escapeHtml(String(ageMinutes))} minutes ago. Holds
       ${cache.recipes.length} recipes, ${cache.pantry.length} pantry items,
       ${cache.weeks.length} weeks.`
    : 'Nothing read from Notion yet.'}</p>

  ${isConfigured ? '' : setupSteps()}`;

  return page({ title: 'Status', body, current: '/' });
}
