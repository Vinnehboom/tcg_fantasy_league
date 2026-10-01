import { recipeRatings } from '../../notion/schema.js';
import { formatIngredientLine, parseIngredientLine } from '../../recipes/ingredient-line.js';
import { readPastedRecipe } from '../../recipes/paste.js';
import { cacheAgeMinutes, readCache, writeCache } from '../../store/cache.js';
import { notionContext, syncRecipes } from '../../sync.js';
import { escapeHtml, page } from '../layout.js';
import { readFormBody } from '../router.js';

function lines(text) {
  return String(text ?? '').split('\n').map((line) => line.trim()).filter(Boolean);
}

function numberOrNull(value) {
  const asNumber = Number(value);

  return value === '' || value === null || Number.isNaN(asNumber) ? null : asNumber;
}

function tagsFrom(value) {
  return String(value ?? '').split(',').map((tag) => tag.trim()).filter(Boolean);
}

function banner(url) {
  const saved = url.searchParams.get('saved');
  const synced = url.searchParams.get('synced');
  const failed = url.searchParams.get('failed');

  if (failed) return `<p class="banner bad">${escapeHtml(failed)}</p>`;
  if (saved) return '<p class="banner">Saved to Notion.</p>';

  if (synced === null) return '';

  const corrected = url.searchParams.get('corrected');
  const extra = Number(corrected) > 0 ? ` Updated the read-back on ${escapeHtml(corrected)} of them.` : '';

  return `<p class="banner">Read ${escapeHtml(synced)} recipes from Notion.${extra}</p>`;
}

function pills(recipe) {
  const items = [];

  if (recipe.rating) items.push(recipe.rating);
  if (recipe.servings) items.push(`${recipe.servings} servings`);
  if (recipe.prepMinutes) items.push(`${recipe.prepMinutes} min`);

  items.push(...(recipe.tags ?? []));

  return items.map((text) => `<span class="pill">${escapeHtml(text)}</span>`).join('');
}

function syncButton(label = 'Read from Notion') {
  return `<form method="post" action="/sync"><button class="quiet">${escapeHtml(label)}</button></form>`;
}

export function recipesPage({ url }) {
  const cache = readCache();
  const recipes = cache.recipes ?? [];
  const ageMinutes = cacheAgeMinutes(cache);
  const flagged = recipes.filter((recipe) => recipe.needsReview).length;

  const rows = recipes.map((recipe) => `<tr>
    <td><a href="/recipes/${escapeHtml(recipe.id)}">${escapeHtml(recipe.name)}</a>
      ${recipe.needsReview ? '<span class="pill flag">check ingredients</span>' : ''}</td>
    <td>${escapeHtml(recipe.rating ?? '')}</td>
    <td>${(recipe.tags ?? []).map((tag) => escapeHtml(tag)).join(', ')}</td>
    <td class="amount">${(recipe.ingredients ?? []).length}</td>
    <td class="amount">${escapeHtml(recipe.timesCooked ?? 0)}</td>
    <td class="amount">${escapeHtml(recipe.lastCooked ?? '—')}</td>
  </tr>`).join('');

  const table = `<table>
    <thead><tr><th>Recipe</th><th>Rating</th><th>Tags</th><th>Items</th>
      <th>Cooked</th><th>Last cooked</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>`;

  const empty = `<div class="empty"><p>No recipes in the cache yet.</p>
    <p class="note">Read them from Notion, or add the first one.</p></div>`;

  const body = `${banner(url)}
  <div class="bar">
    <a href="/recipes/new"><button>Add a recipe</button></a>
    ${syncButton()}
    <span class="note">${ageMinutes === null
      ? 'Never read from Notion.'
      : `Read from Notion ${escapeHtml(String(ageMinutes))} minutes ago.`}</span>
  </div>
  ${flagged > 0
    ? `<p class="banner bad">${flagged === 1 ? 'One recipe has' : `${escapeHtml(String(flagged))} recipes have`} an ingredient line the app could not read.</p>`
    : ''}
  ${recipes.length > 0 ? table : empty}`;

  return page({ title: 'Recipes', body, current: '/recipes' });
}

function draftFields(draft) {
  const ratingOptions = ['', ...recipeRatings]
    .map((rating) => {
      const selected = rating === draft.rating ? ' selected' : '';

      return `<option value="${escapeHtml(rating)}"${selected}>${escapeHtml(rating || '—')}</option>`;
    })
    .join('');

  return `<div class="field">
    <label for="name">Name</label>
    <input id="name" name="name" value="${escapeHtml(draft.name)}" required>
  </div>
  <div class="row">
    <div class="field"><label for="servings">Servings</label>
      <input id="servings" name="servings" type="number" min="1" step="1" value="${escapeHtml(draft.servings ?? '')}"></div>
    <div class="field"><label for="prepMinutes">Minutes</label>
      <input id="prepMinutes" name="prepMinutes" type="number" min="1" step="1" value="${escapeHtml(draft.prepMinutes ?? '')}"></div>
    <div class="field"><label for="rating">Rating</label>
      <select id="rating" name="rating">${ratingOptions}</select></div>
  </div>
  <div class="row">
    <div class="field"><label for="tags">Tags, divided by commas</label>
      <input id="tags" name="tags" value="${escapeHtml(draft.tags)}"></div>
    <div class="field"><label for="source">Source link</label>
      <input id="source" name="source" type="url" value="${escapeHtml(draft.source)}"></div>
  </div>
  <div class="field">
    <label for="ingredients">Ingredients, one each line</label>
    <textarea id="ingredients" name="ingredients" rows="10">${escapeHtml(draft.ingredients)}</textarea>
  </div>
  <div class="field">
    <label for="instructions">Instructions, one step each line</label>
    <textarea id="instructions" name="instructions" rows="10">${escapeHtml(draft.instructions)}</textarea>
  </div>
  <div class="field">
    <label for="notes">Notes</label>
    <textarea id="notes" name="notes" rows="3">${escapeHtml(draft.notes)}</textarea>
  </div>`;
}

function readPreview(draft) {
  const parsed = lines(draft.ingredients).map(parseIngredientLine);

  if (parsed.length === 0) return '';

  const rows = parsed.map((line) => `<tr>
    <td class="amount">${line.quantity === null ? '<span class="note">—</span>' : escapeHtml(String(line.quantity))}</td>
    <td class="amount">${escapeHtml(line.unit ?? '')}</td>
    <td>${line.understood
      ? escapeHtml(line.item)
      : `<span class="bad">could not read &ldquo;${escapeHtml(line.raw)}&rdquo;</span>`}</td>
    <td class="note">${escapeHtml(line.note ?? '')}</td>
  </tr>`).join('');

  return `<h3>What the app reads</h3>
  <table><thead><tr><th>Amount</th><th>Unit</th><th>Item</th><th>Note</th></tr></thead>
  <tbody>${rows}</tbody></table>
  <p class="note">Correct any line in the box above. The page in Notion keeps your own wording.</p>`;
}

const emptyDraft = {
  name: '', servings: '', prepMinutes: '', rating: '', tags: '', source: '',
  ingredients: '', instructions: '', notes: '',
};

export function newRecipePage({ url, draft = emptyDraft, pasted = '' }) {
  const body = `${banner(url)}
  <h2>Paste a recipe</h2>
  <form method="post" action="/recipes/new">
    <div class="field">
      <label for="pasted">Paste the whole recipe, then read it into the form</label>
      <textarea id="pasted" name="pasted" rows="8"
        placeholder="Lemon pasta&#10;&#10;Ingredients&#10;400 g pasta&#10;1 lemon&#10;&#10;Instructions&#10;Boil the water.">${escapeHtml(pasted)}</textarea>
    </div>
    <button class="quiet">Read it into the form</button>
  </form>

  <h2>Check it, then save</h2>
  <form method="post" action="/recipes">
    ${draftFields(draft)}
    ${readPreview(draft)}
    <div class="bar" style="margin-top:1.5rem"><button>Save to Notion</button>
      <a href="/recipes" class="note">Cancel</a></div>
  </form>`;

  return page({ title: 'Add a recipe', body, current: '/recipes' });
}

export async function parsePastedRecipe({ request, url }) {
  const form = await readFormBody(request);
  const pasted = form.get('pasted') ?? '';
  const read = readPastedRecipe(pasted);

  const draft = {
    ...emptyDraft,
    name: read.name,
    ingredients: read.ingredients.map((line) => formatIngredientLine(parseIngredientLine(line))).join('\n'),
    instructions: read.instructions.join('\n'),
    notes: read.notes.join('\n'),
  };

  return newRecipePage({ url, draft, pasted });
}

function recipeFromForm(form) {
  const ingredients = lines(form.get('ingredients')).map(parseIngredientLine);

  return {
    name: (form.get('name') ?? '').trim() || 'Untitled',
    servings: numberOrNull(form.get('servings')),
    prepMinutes: numberOrNull(form.get('prepMinutes')),
    rating: form.get('rating') || null,
    tags: tagsFrom(form.get('tags')),
    source: (form.get('source') ?? '').trim() || null,
    ingredients,
    instructions: lines(form.get('instructions')),
    notes: lines(form.get('notes')),
    needsReview: ingredients.length === 0 || ingredients.some((line) => !line.understood),
  };
}

export async function createRecipe({ request }) {
  const form = await readFormBody(request);
  const recipe = recipeFromForm(form);
  const { recipes: repository } = notionContext();
  const created = await repository.create(recipe);

  const cache = readCache();
  const stored = { ...created, ...recipe, readWithoutHeadings: false };

  writeCache({
    recipes: [...cache.recipes.filter((item) => item.id !== stored.id), stored]
      .sort((left, right) => left.name.localeCompare(right.name)),
  });

  return { redirect: `/recipes/${created.id}?saved=1` };
}

export function recipePage({ url, params }) {
  const cache = readCache();
  const recipe = (cache.recipes ?? []).find((item) => item.id === params.id);

  if (!recipe) {
    return page({
      title: 'Recipe not found',
      body: `<h2>Not in the cache</h2>
        <p>This recipe is not in the local cache. Read the recipes from Notion again.</p>
        <div class="bar">${syncButton()}<a href="/recipes" class="note">Back to the recipes</a></div>`,
      current: '/recipes',
    });
  }

  const ingredientRows = (recipe.ingredients ?? []).map((line) => `<tr>
    <td class="amount">${line.quantity === null ? '<span class="note">to taste</span>' : escapeHtml(String(line.quantity))}</td>
    <td class="amount">${escapeHtml(line.unit && line.unit !== 'piece' ? line.unit : '')}</td>
    <td>${line.understood
      ? escapeHtml(line.item)
      : `<span class="bad">could not read &ldquo;${escapeHtml(line.raw)}&rdquo;</span>`}</td>
    <td class="note">${escapeHtml(line.note ?? '')}</td>
  </tr>`).join('');

  const ratingOptions = ['', ...recipeRatings]
    .map((rating) => {
      const selected = rating === (recipe.rating ?? '') ? ' selected' : '';

      return `<option value="${escapeHtml(rating)}"${selected}>${escapeHtml(rating || '—')}</option>`;
    })
    .join('');

  const body = `${banner(url)}
  <h2>${escapeHtml(recipe.name)}</h2>
  <p>${pills(recipe)}</p>
  <div class="bar">
    <a href="${escapeHtml(recipe.url ?? '#')}" target="_blank" rel="noreferrer">
      <button class="quiet">Open in Notion</button></a>
    ${recipe.source ? `<a href="${escapeHtml(recipe.source)}" target="_blank" rel="noreferrer" class="note">Original source</a>` : ''}
    <a href="/recipes" class="note">Back to the recipes</a>
  </div>

  ${recipe.needsReview
    ? '<p class="banner bad">The app could not read every ingredient line. Correct the list in Notion, then read the recipes again.</p>'
    : ''}
  ${recipe.readWithoutHeadings
    ? '<p class="banner">This page has no Ingredients heading. Add one in Notion to keep the reading reliable.</p>'
    : ''}

  <h3>Ingredients</h3>
  ${ingredientRows
    ? `<table><thead><tr><th>Amount</th><th>Unit</th><th>Item</th><th>Note</th></tr></thead>
       <tbody>${ingredientRows}</tbody></table>`
    : '<p class="note">No ingredients on the page.</p>'}

  <h3>Instructions</h3>
  ${(recipe.instructions ?? []).length > 0
    ? `<ol class="recipe">${recipe.instructions.map((step) => `<li>${escapeHtml(step)}</li>`).join('')}</ol>`
    : '<p class="note">No instructions on the page. Write them in Notion.</p>'}

  ${(recipe.notes ?? []).length > 0
    ? `<h3>Notes</h3>${recipe.notes.map((note) => `<p>${escapeHtml(note)}</p>`).join('')}`
    : ''}

  <h3>Quick details</h3>
  <form method="post" action="/recipes/${escapeHtml(recipe.id)}">
    <div class="row">
      <div class="field"><label for="rating">Rating</label>
        <select id="rating" name="rating">${ratingOptions}</select></div>
      <div class="field"><label for="servings">Servings</label>
        <input id="servings" name="servings" type="number" min="1" step="1" value="${escapeHtml(recipe.servings ?? '')}"></div>
      <div class="field"><label for="prepMinutes">Minutes</label>
        <input id="prepMinutes" name="prepMinutes" type="number" min="1" step="1" value="${escapeHtml(recipe.prepMinutes ?? '')}"></div>
    </div>
    <div class="row">
      <div class="field"><label for="tags">Tags, divided by commas</label>
        <input id="tags" name="tags" value="${escapeHtml((recipe.tags ?? []).join(', '))}"></div>
      <div class="field"><label for="source">Source link</label>
        <input id="source" name="source" type="url" value="${escapeHtml(recipe.source ?? '')}"></div>
    </div>
    <button>Save the details</button>
  </form>
  <p class="note" style="margin-top:1rem">Change the ingredients and the instructions in Notion.
    Then read the recipes again.</p>`;

  return page({ title: recipe.name, body, current: '/recipes' });
}

export async function updateRecipe({ request, params }) {
  const form = await readFormBody(request);
  const details = {
    name: (form.get('name') ?? '').trim() || undefined,
    rating: form.get('rating') || null,
    tags: tagsFrom(form.get('tags')),
    servings: numberOrNull(form.get('servings')),
    prepMinutes: numberOrNull(form.get('prepMinutes')),
    source: (form.get('source') ?? '').trim() || null,
  };

  const cache = readCache();
  const recipe = (cache.recipes ?? []).find((item) => item.id === params.id);

  if (!recipe) return { redirect: '/recipes?failed=That+recipe+is+not+in+the+cache.' };

  const { recipes: repository } = notionContext();

  await repository.updateDetails(params.id, { ...recipe, ...details, name: details.name ?? recipe.name });

  writeCache({
    recipes: cache.recipes.map((item) => (item.id === params.id
      ? { ...item, ...details, name: details.name ?? item.name }
      : item)),
  });

  return { redirect: `/recipes/${params.id}?saved=1` };
}

export async function runSync() {
  try {
    const { count, corrected } = await syncRecipes();

    return { redirect: `/recipes?synced=${count}&corrected=${corrected}` };
  } catch (error) {
    return { redirect: `/recipes?failed=${encodeURIComponent(error.message)}` };
  }
}
