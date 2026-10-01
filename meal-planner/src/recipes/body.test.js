import assert from 'node:assert/strict';
import { test } from 'node:test';

import { buildRecipeBlocks, chunked, readRecipeBody } from './body.js';

function heading(content) {
  return { type: 'heading_2', heading_2: { rich_text: [{ plain_text: content }] } };
}

function listItem(type, content) {
  return { type, [type]: { rich_text: [{ plain_text: content }] } };
}

function paragraph(content) {
  return { type: 'paragraph', paragraph: { rich_text: [{ plain_text: content }] } };
}

test('reads ingredients and instructions under their headings', () => {
  const body = readRecipeBody([
    heading('Ingredients'),
    listItem('bulleted_list_item', '400 g pasta'),
    listItem('bulleted_list_item', '2 cloves garlic'),
    heading('Instructions'),
    listItem('numbered_list_item', 'Boil the water.'),
    listItem('numbered_list_item', 'Add the pasta.'),
  ]);

  assert.deepEqual(body.ingredients.map((line) => line.item), ['pasta', 'garlic']);
  assert.deepEqual(body.instructions, ['Boil the water.', 'Add the pasta.']);
  assert.equal(body.needsReview, false);
  assert.equal(body.readWithoutHeadings, false);
});

test('reads a page that has no headings', () => {
  const body = readRecipeBody([
    listItem('bulleted_list_item', '400 g pasta'),
    listItem('numbered_list_item', 'Boil the water.'),
  ]);

  assert.deepEqual(body.ingredients.map((line) => line.item), ['pasta']);
  assert.deepEqual(body.instructions, ['Boil the water.']);
  assert.equal(body.readWithoutHeadings, true);
});

test('accepts method as a name for the instructions', () => {
  const body = readRecipeBody([heading('Method'), paragraph('Roast everything.')]);

  assert.deepEqual(body.instructions, ['Roast everything.']);
});

test('keeps a notes section apart', () => {
  const body = readRecipeBody([
    heading('Ingredients'),
    listItem('bulleted_list_item', '1 lemon'),
    heading('Notes'),
    paragraph('Better with the zest of two lemons.'),
  ]);

  assert.deepEqual(body.notes, ['Better with the zest of two lemons.']);
  assert.deepEqual(body.instructions, []);
});

test('asks for review when a page has no ingredients', () => {
  assert.equal(readRecipeBody([]).needsReview, true);
});

test('asks for review when a line has no item', () => {
  const body = readRecipeBody([heading('Ingredients'), listItem('bulleted_list_item', '400 g')]);

  assert.equal(body.needsReview, true);
});

test('skips an empty block', () => {
  const body = readRecipeBody([
    heading('Ingredients'),
    listItem('bulleted_list_item', ''),
    listItem('bulleted_list_item', '1 lemon'),
  ]);

  assert.equal(body.ingredients.length, 1);
});

test('builds blocks that read back to the same recipe', () => {
  const blocks = buildRecipeBlocks({
    ingredients: [{ quantity: 400, unit: 'g', item: 'pasta', note: null }],
    instructions: ['Boil the water.'],
    notes: ['Keep the cooking water.'],
  });

  const readable = blocks.map((item) => ({
    type: item.type,
    [item.type]: { rich_text: [{ plain_text: item[item.type].rich_text[0].text.content }] },
  }));

  const body = readRecipeBody(readable);

  assert.deepEqual(body.ingredients.map((line) => line.raw), ['400 g pasta']);
  assert.deepEqual(body.instructions, ['Boil the water.']);
  assert.deepEqual(body.notes, ['Keep the cooking water.']);
});

test('leaves out a section that has no content', () => {
  const blocks = buildRecipeBlocks({ ingredients: ['1 lemon'] });

  assert.deepEqual(blocks.map((item) => item.type), ['heading_2', 'bulleted_list_item']);
});

test('splits a long block list into groups of one hundred', () => {
  const groups = chunked(Array.from({ length: 250 }, (value, index) => index));

  assert.deepEqual(groups.map((group) => group.length), [100, 100, 50]);
});
