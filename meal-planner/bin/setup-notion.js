import { loadEnvFile, readConfig, settings, writeConfig } from '../src/config.js';
import { NotionClient, NotionError } from '../src/notion/client.js';
import { databaseBlueprints } from '../src/notion/schema.js';

function parentPage(pageId) {
  return { type: 'page_id', page_id: pageId };
}

function titleOf(text) {
  return [{ type: 'text', text: { content: text } }];
}

async function run() {
  loadEnvFile();

  const { token, parentPageId } = settings();

  if (!parentPageId) {
    throw new Error('NOTION_PARENT_PAGE_ID is not set. Add the id of the Notion page that will hold the databases.');
  }

  const client = new NotionClient({ token });
  const config = readConfig();
  const databaseIds = { ...config.databases };

  for (const blueprint of databaseBlueprints()) {
    if (databaseIds[blueprint.key]) {
      console.log(`${blueprint.title}: already set up (${databaseIds[blueprint.key]})`);
      continue;
    }

    const database = await client.createDatabase({
      parent: parentPage(parentPageId),
      title: titleOf(blueprint.title),
      description: titleOf(blueprint.description),
      is_inline: false,
      properties: blueprint.properties(databaseIds),
    });

    databaseIds[blueprint.key] = database.id;
    console.log(`${blueprint.title}: created (${database.id})`);
  }

  writeConfig({ ...config, databases: databaseIds, parentPageId });

  console.log('\nSaved the database ids to data/config.json. Run `npm start` next.');
}

run().catch((error) => {
  if (error instanceof NotionError && error.status === 404) {
    console.error('Notion returned "not found". Share the parent page with your integration, then run this again.');
  } else {
    console.error(error.message);
  }

  process.exitCode = 1;
});
