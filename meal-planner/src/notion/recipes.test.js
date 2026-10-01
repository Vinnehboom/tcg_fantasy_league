import assert from 'node:assert/strict';
import { test } from 'node:test';

import { RecipeRepository, ingredientSummaryOf } from './recipes.js';

class FakeClient {
  calls = [];
  pages = [];
  blocks = {};

  async queryDatabase(databaseId, body) {
    this.calls.push({ name: 'queryDatabase', databaseId, body });

    return this.pages;
  }

  async blockChildren(blockId) {
    this.calls.push({ name: 'blockChildren', blockId });

    return this.blocks[blockId] ?? [];
  }

  async createPage(body) {
    this.calls.push({ name: 'createPage', body });

    return { id: 'created-id', url: 'https://notion.so/created', last_edited_time: 'now', properties: body.properties };
  }

  async updatePage(pageId, body) {
    this.calls.push({ name: 'updatePage', pageId, body });

    return {};
  }

  async appendBlocks(blockId, children) {
    this.calls.push({ name: 'appendBlocks', blockId, children });

    return {};
  }
}

function repositoryWith(client) {
  return new RecipeRepository({ client, databaseId: 'db-1' });
}

function titlePage(id, { name, lastEditedTime }) {
  return {
    id,
    url: `https://notion.so/${id}`,
    last_edited_time: lastEditedTime,
    properties: { Name: { title: [{ plain_text: name }] } },
  };
}

function bulletBlock(content) {
  return { type: 'bulleted_list_item', bulleted_list_item: { rich_text: [{ plain_text: content }] } };
}

test('joins the ingredients into one summary line', () => {
  const summary = ingredientSummaryOf([
    { quantity: 400, unit: 'g', item: 'pasta', note: null },
    { quantity: null, unit: null, item: 'salt', note: null },
  ]);

  assert.equal(summary, '400 g pasta; salt');
});

test('create sends the name, the summary and the status', async () => {
  const client = new FakeClient();

  await repositoryWith(client).create({
    name: 'Lemon pasta',
    ingredients: [{ quantity: 400, unit: 'g', item: 'pasta', note: null }],
    instructions: ['Boil the water.'],
    needsReview: false,
  });

  const { body } = client.calls.find((call) => call.name === 'createPage');

  assert.equal(body.properties.Name.title[0].text.content, 'Lemon pasta');
  assert.equal(body.properties['Ingredients read by app'].rich_text[0].text.content, '400 g pasta');
  assert.equal(body.properties['Ingredient status'].select.name, 'Read');
  assert.equal(body.parent.database_id, 'db-1');
});

test('create marks a recipe that needs review', async () => {
  const client = new FakeClient();

  await repositoryWith(client).create({ name: 'Mystery', ingredients: [], needsReview: true });

  const { body } = client.calls.find((call) => call.name === 'createPage');

  assert.equal(body.properties['Ingredient status'].select.name, 'Needs review');
});

test('create appends the blocks that do not fit in the first group', async () => {
  const client = new FakeClient();
  const ingredients = Array.from({ length: 150 }, (value, index) => ({
    quantity: index + 1, unit: 'g', item: `item ${index}`, note: null,
  }));

  await repositoryWith(client).create({ name: 'Long list', ingredients, needsReview: false });

  const created = client.calls.find((call) => call.name === 'createPage');
  const appended = client.calls.filter((call) => call.name === 'appendBlocks');

  assert.equal(created.body.children.length, 100);
  assert.equal(appended.length, 1);
  assert.equal(appended[0].children.length, 51);
});

test('updateDetails clears a rating that the form left empty', async () => {
  const client = new FakeClient();

  await repositoryWith(client).updateDetails('page-1', { rating: null, servings: null, source: null, tags: [] });

  const { body } = client.calls.find((call) => call.name === 'updatePage');

  assert.deepEqual(body.properties.Rating, { select: null });
  assert.deepEqual(body.properties.Servings, { number: null });
  assert.deepEqual(body.properties.Source, { url: null });
  assert.deepEqual(body.properties.Tags, { multi_select: [] });
});

test('updateDetails leaves out a field the caller did not name', async () => {
  const client = new FakeClient();

  await repositoryWith(client).updateDetails('page-1', { rating: 'Good' });

  const { body } = client.calls.find((call) => call.name === 'updatePage');

  assert.deepEqual(Object.keys(body.properties), ['Rating']);
});

test('list reads the page body of a recipe it has not seen', async () => {
  const client = new FakeClient();

  client.pages = [titlePage('r1', { name: 'Soup', lastEditedTime: 'edit-1' })];
  client.blocks.r1 = [bulletBlock('2 onions')];

  const recipes = await repositoryWith(client).list();

  assert.equal(recipes.length, 1);
  assert.deepEqual(recipes[0].ingredients.map((line) => line.item), ['onions']);
});

test('list keeps the cached body when the page did not change', async () => {
  const client = new FakeClient();

  client.pages = [titlePage('r1', { name: 'Soup', lastEditedTime: 'edit-1' })];

  const previous = [{
    id: 'r1',
    lastEditedTime: 'edit-1',
    ingredients: [{ item: 'onions', understood: true }],
    instructions: ['Fry them.'],
    notes: [],
    needsReview: false,
  }];

  const recipes = await repositoryWith(client).list({ previous });

  assert.equal(client.calls.some((call) => call.name === 'blockChildren'), false);
  assert.deepEqual(recipes[0].instructions, ['Fry them.']);
});

test('list reads the body again when the page changed', async () => {
  const client = new FakeClient();

  client.pages = [titlePage('r1', { name: 'Soup', lastEditedTime: 'edit-2' })];
  client.blocks.r1 = [bulletBlock('3 onions')];

  const previous = [{ id: 'r1', lastEditedTime: 'edit-1', ingredients: [], instructions: [], notes: [] }];
  const recipes = await repositoryWith(client).list({ previous });

  assert.equal(client.calls.some((call) => call.name === 'blockChildren'), true);
  assert.deepEqual(recipes[0].ingredients.map((line) => line.quantity), [3]);
});
