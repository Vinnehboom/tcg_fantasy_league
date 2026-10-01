import assert from 'node:assert/strict';
import { test } from 'node:test';

import { formatIngredientLine, parseIngredientLine } from './ingredient-line.js';

function parsed(line) {
  const { quantity, unit, item, note } = parseIngredientLine(line);

  return { quantity, unit, item, note };
}

test('reads a metric weight', () => {
  assert.deepEqual(parsed('400 g pasta'), { quantity: 400, unit: 'g', item: 'pasta', note: null });
});

test('reads a weight written without a space', () => {
  assert.deepEqual(parsed('400g pasta'), { quantity: 400, unit: 'g', item: 'pasta', note: null });
});

test('normalises a spelled-out unit', () => {
  assert.deepEqual(parsed('2 tablespoons olive oil'), { quantity: 2, unit: 'tbsp', item: 'olive oil', note: null });
});

test('strips a markdown bullet', () => {
  assert.deepEqual(parsed('- 2 cloves garlic'), { quantity: 2, unit: 'clove', item: 'garlic', note: null });
});

test('strips a numbered prefix', () => {
  assert.deepEqual(parsed('1. 500 ml stock'), { quantity: 500, unit: 'ml', item: 'stock', note: null });
});

test('counts a bare item as pieces', () => {
  assert.deepEqual(parsed('2 onions'), { quantity: 2, unit: 'piece', item: 'onions', note: null });
});

test('reads an article as one', () => {
  assert.deepEqual(parsed('a pinch of salt'), { quantity: 1, unit: 'pinch', item: 'salt', note: null });
});

test('reads a simple fraction', () => {
  assert.deepEqual(parsed('1/2 lemon'), { quantity: 0.5, unit: 'piece', item: 'lemon', note: null });
});

test('reads a mixed fraction', () => {
  assert.deepEqual(parsed('1 1/2 kg potatoes'), { quantity: 1.5, unit: 'kg', item: 'potatoes', note: null });
});

test('reads a vulgar fraction', () => {
  assert.deepEqual(parsed('½ tsp chilli flakes'), { quantity: 0.5, unit: 'tsp', item: 'chilli flakes', note: null });
});

test('reads a decimal written with a comma', () => {
  assert.deepEqual(parsed('1,5 l water'), { quantity: 1.5, unit: 'l', item: 'water', note: null });
});

test('takes the upper bound of a range and keeps the range as a note', () => {
  assert.deepEqual(parsed('2-3 carrots'), { quantity: 3, unit: 'piece', item: 'carrots', note: '2 to 3' });
});

test('moves a trailing comma clause into the note', () => {
  assert.deepEqual(parsed('1 onion, finely chopped'), { quantity: 1, unit: 'piece', item: 'onion', note: 'finely chopped' });
});

test('moves a parenthesis into the note', () => {
  assert.deepEqual(parsed('100 g feta (optional)'), { quantity: 100, unit: 'g', item: 'feta', note: 'optional' });
});

test('treats a tin as a can', () => {
  assert.deepEqual(parsed('1 tin chopped tomatoes'), { quantity: 1, unit: 'can', item: 'chopped tomatoes', note: null });
});

test('keeps an unmeasured item without a quantity', () => {
  assert.deepEqual(parsed('salt and pepper'), { quantity: null, unit: null, item: 'salt and pepper', note: null });
});

test('keeps an unknown describing word as part of the item', () => {
  assert.deepEqual(parsed('2 large aubergines'), { quantity: 2, unit: 'piece', item: 'large aubergines', note: null });
});

test('marks a line with no item as not understood', () => {
  assert.equal(parseIngredientLine('400 g').understood, false);
  assert.equal(parseIngredientLine('400 g pasta').understood, true);
});

test('formats a line back to text', () => {
  assert.equal(formatIngredientLine({ quantity: 400, unit: 'g', item: 'pasta', note: null }), '400 g pasta');
  assert.equal(formatIngredientLine({ quantity: 2, unit: 'piece', item: 'onions', note: null }), '2 onions');
  assert.equal(formatIngredientLine({ quantity: null, unit: null, item: 'salt', note: null }), 'salt');
  assert.equal(formatIngredientLine({ quantity: 1, unit: 'piece', item: 'onion', note: 'chopped' }), '1 onion, chopped');
});
