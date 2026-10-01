import { buildRecipeBlocks, chunked, readRecipeBody } from '../recipes/body.js';
import { formatIngredientLine } from '../recipes/ingredient-line.js';

const summaryLimit = 1900;

function plainText(richText = []) {
  return richText.map((part) => part.plain_text ?? part.text?.content ?? '').join('').trim();
}

function readProperties(page) {
  const properties = page.properties ?? {};

  return {
    id: page.id,
    url: page.url,
    lastEditedTime: page.last_edited_time,
    name: plainText(properties.Name?.title) || 'Untitled',
    rating: properties.Rating?.select?.name ?? null,
    tags: (properties.Tags?.multi_select ?? []).map((tag) => tag.name),
    servings: properties.Servings?.number ?? null,
    prepMinutes: properties['Prep minutes']?.number ?? null,
    source: properties.Source?.url ?? null,
    lastCooked: properties['Last cooked']?.date?.start ?? null,
    timesCooked: properties['Times cooked']?.number ?? 0,
    ingredientSummary: plainText(properties['Ingredients read by app']?.rich_text),
    ingredientStatus: properties['Ingredient status']?.select?.name ?? null,
  };
}

function richText(content) {
  return [{ type: 'text', text: { content } }];
}

export function ingredientSummaryOf(ingredients) {
  return ingredients.map(formatIngredientLine).join('; ').slice(0, summaryLimit);
}

function writeProperties(recipe) {
  const properties = {};

  if (recipe.name !== undefined) {
    properties.Name = { title: richText(recipe.name) };
  }

  if (recipe.rating !== undefined) {
    properties.Rating = recipe.rating ? { select: { name: recipe.rating } } : { select: null };
  }

  if (recipe.tags !== undefined) {
    properties.Tags = { multi_select: (recipe.tags ?? []).map((name) => ({ name })) };
  }

  if (recipe.servings !== undefined) {
    properties.Servings = { number: recipe.servings };
  }

  if (recipe.prepMinutes !== undefined) {
    properties['Prep minutes'] = { number: recipe.prepMinutes };
  }

  if (recipe.source !== undefined) {
    properties.Source = { url: recipe.source || null };
  }

  return properties;
}

export class RecipeRepository {
  #client;
  #databaseId;

  constructor({ client, databaseId }) {
    this.#client = client;
    this.#databaseId = databaseId;
  }

  async list({ previous = [] } = {}) {
    const pages = await this.#client.queryDatabase(this.#databaseId, {
      sorts: [{ property: 'Name', direction: 'ascending' }],
    });

    const known = new Map(previous.map((recipe) => [recipe.id, recipe]));
    const recipes = [];

    for (const page of pages) {
      const details = readProperties(page);
      const cached = known.get(details.id);

      if (cached && cached.lastEditedTime === details.lastEditedTime) {
        recipes.push({ ...cached, ...details });
        continue;
      }

      const blocks = await this.#client.blockChildren(page.id);

      recipes.push({ ...details, ...readRecipeBody(blocks) });
    }

    return recipes;
  }

  async create(recipe) {
    const groups = chunked(buildRecipeBlocks(recipe));
    const ingredients = recipe.ingredients ?? [];

    const page = await this.#client.createPage({
      parent: { database_id: this.#databaseId },
      properties: {
        ...writeProperties(recipe),
        'Ingredients read by app': { rich_text: richText(ingredientSummaryOf(ingredients)) },
        'Ingredient status': { select: { name: recipe.needsReview ? 'Needs review' : 'Read' } },
      },
      children: groups[0] ?? [],
    });

    for (const group of groups.slice(1)) {
      await this.#client.appendBlocks(page.id, group);
    }

    return readProperties(page);
  }

  updateDetails(recipeId, recipe) {
    return this.#client.updatePage(recipeId, { properties: writeProperties(recipe) });
  }

  refreshIngredientSummary(recipeId, { summary, status }) {
    return this.#client.updatePage(recipeId, {
      properties: {
        'Ingredients read by app': { rich_text: richText(summary) },
        'Ingredient status': { select: { name: status } },
      },
    });
  }
}
