import assert from 'node:assert/strict';
import { test } from 'node:test';

import { readPastedRecipe } from './paste.js';

test('reads a recipe that uses section headings', () => {
  const pasted = readPastedRecipe(`Lemon pasta

Ingredients
- 400 g pasta
- 1 lemon

Instructions
1. Boil the water.
2. Add the pasta.`);

  assert.equal(pasted.name, 'Lemon pasta');
  assert.deepEqual(pasted.ingredients, ['- 400 g pasta', '- 1 lemon']);
  assert.deepEqual(pasted.instructions, ['Boil the water.', 'Add the pasta.']);
});

test('reads a recipe that has no headings', () => {
  const pasted = readPastedRecipe(`Lemon pasta
400 g pasta
1 lemon
Boil the water, then add the pasta and cook it for ten minutes.`);

  assert.equal(pasted.name, 'Lemon pasta');
  assert.deepEqual(pasted.ingredients, ['400 g pasta', '1 lemon']);
  assert.equal(pasted.instructions.length, 1);
});

test('accepts a markdown heading as the name', () => {
  assert.equal(readPastedRecipe('# Lemon pasta\n400 g pasta').name, 'Lemon pasta');
});

test('accepts a heading written with a colon', () => {
  const pasted = readPastedRecipe('Soup\nIngredients:\n2 onions\nMethod:\nFry the onions.');

  assert.deepEqual(pasted.ingredients, ['2 onions']);
  assert.deepEqual(pasted.instructions, ['Fry the onions.']);
});

test('keeps a long sentence out of the ingredients', () => {
  const pasted = readPastedRecipe('Soup\nFry a large onion in the pan until it turns golden brown.');

  assert.deepEqual(pasted.ingredients, []);
  assert.equal(pasted.instructions.length, 1);
});

test('puts a notes section in the notes', () => {
  const pasted = readPastedRecipe('Soup\nIngredients\n2 onions\nNotes\nDouble the garlic.');

  assert.deepEqual(pasted.notes, ['Double the garlic.']);
  assert.deepEqual(pasted.instructions, []);
});

test('returns empty fields for empty input', () => {
  assert.deepEqual(readPastedRecipe(''), { name: '', ingredients: [], instructions: [], notes: [] });
});
