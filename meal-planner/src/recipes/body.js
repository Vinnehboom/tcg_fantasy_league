import { formatIngredientLine, parseIngredientLine } from './ingredient-line.js';

const headingTypes = new Set(['heading_1', 'heading_2', 'heading_3']);
const textBearingTypes = new Set([
  'paragraph', 'bulleted_list_item', 'numbered_list_item', 'to_do', 'quote', 'callout', 'toggle',
]);

const sectionKeywords = [
  [/ingredient|shopping/i, 'ingredients'],
  [/instruction|method|step|direction|preparation|recipe/i, 'instructions'],
  [/note|tip|variation/i, 'notes'],
];

export function blockText(block) {
  const value = block[block.type];
  const richText = value?.rich_text ?? [];

  return richText.map((part) => part.plain_text ?? part.text?.content ?? '').join('').trim();
}

function sectionFor(headingText) {
  for (const [pattern, section] of sectionKeywords) {
    if (pattern.test(headingText)) return section;
  }

  return null;
}

export function readRecipeBody(blocks) {
  const collected = { ingredients: [], instructions: [], notes: [] };
  const loose = { bullets: [], numbered: [], paragraphs: [] };
  let section = null;

  for (const block of blocks) {
    const text = blockText(block);

    if (headingTypes.has(block.type)) {
      section = sectionFor(text);
      continue;
    }

    if (!text || !textBearingTypes.has(block.type)) continue;

    if (section) {
      collected[section].push(text);
      continue;
    }

    if (block.type === 'bulleted_list_item') loose.bullets.push(text);
    else if (block.type === 'numbered_list_item') loose.numbered.push(text);
    else loose.paragraphs.push(text);
  }

  let readWithoutHeadings = false;

  if (collected.ingredients.length === 0 && loose.bullets.length > 0) {
    collected.ingredients = loose.bullets;
    readWithoutHeadings = true;
  }

  if (collected.instructions.length === 0) {
    const fallback = [...loose.numbered, ...loose.paragraphs];

    if (fallback.length > 0) {
      collected.instructions = fallback;
      readWithoutHeadings = true;
    }
  }

  const ingredients = collected.ingredients.map(parseIngredientLine);

  return {
    ingredients,
    instructions: collected.instructions,
    notes: collected.notes,
    readWithoutHeadings,
    needsReview: ingredients.length === 0 || ingredients.some((line) => !line.understood),
  };
}

function richText(content) {
  return [{ type: 'text', text: { content } }];
}

function block(type, content) {
  return { object: 'block', type, [type]: { rich_text: richText(content) } };
}

export function buildRecipeBlocks({ ingredients = [], instructions = [], notes = [] }) {
  const blocks = [];

  if (ingredients.length > 0) {
    blocks.push(block('heading_2', 'Ingredients'));

    for (const line of ingredients) {
      const text = typeof line === 'string' ? line : formatIngredientLine(line);

      blocks.push(block('bulleted_list_item', text));
    }
  }

  if (instructions.length > 0) {
    blocks.push(block('heading_2', 'Instructions'));

    for (const step of instructions) {
      blocks.push(block('numbered_list_item', step));
    }
  }

  if (notes.length > 0) {
    blocks.push(block('heading_2', 'Notes'));

    for (const note of notes) {
      blocks.push(block('paragraph', note));
    }
  }

  return blocks;
}

export function chunked(items, size = 100) {
  const chunks = [];

  for (let start = 0; start < items.length; start += size) {
    chunks.push(items.slice(start, start + size));
  }

  return chunks;
}
