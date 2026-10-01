import { readConfig, settings } from './config.js';
import { NotionClient } from './notion/client.js';
import { RecipeRepository, ingredientSummaryOf } from './notion/recipes.js';
import { RECIPES } from './notion/schema.js';
import { readCache, writeCache } from './store/cache.js';

export function notionContext() {
  const { token } = settings();
  const config = readConfig();
  const databaseIds = config.databases ?? {};

  if (!databaseIds[RECIPES]) {
    throw new Error('The Notion databases are not set up yet. Run `npm run setup:notion` first.');
  }

  const client = new NotionClient({ token });

  return {
    client,
    databaseIds,
    recipes: new RecipeRepository({ client, databaseId: databaseIds[RECIPES] }),
  };
}

async function writeBackSummaries(repository, recipes) {
  let corrected = 0;

  for (const recipe of recipes) {
    const summary = ingredientSummaryOf(recipe.ingredients ?? []);
    const status = recipe.needsReview ? 'Needs review' : 'Read';

    if (recipe.ingredientSummary === summary && recipe.ingredientStatus === status) continue;

    await repository.refreshIngredientSummary(recipe.id, { summary, status });

    recipe.ingredientSummary = summary;
    recipe.ingredientStatus = status;
    corrected += 1;
  }

  return corrected;
}

export async function syncRecipes() {
  const { recipes: repository } = notionContext();
  const cache = readCache();
  const recipes = await repository.list({ previous: cache.recipes });
  const corrected = await writeBackSummaries(repository, recipes);

  writeCache({ recipes });

  return { count: recipes.length, corrected };
}
