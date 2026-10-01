import { bulletPrefix, parseIngredientLine } from './ingredient-line.js';

const sectionHeaders = [
  [/^#{0,3}\s*ingredients\b/i, 'ingredients'],
  [/^#{0,3}\s*(instructions|method|steps|directions|preparation)\b/i, 'instructions'],
  [/^#{0,3}\s*(notes|tips)\b/i, 'notes'],
];

function headerSection(line) {
  const withoutTrailingColon = line.replace(/:\s*$/, '');

  if (withoutTrailingColon.split(/\s+/).length > 3) return null;

  for (const [pattern, section] of sectionHeaders) {
    if (pattern.test(withoutTrailingColon)) return section;
  }

  return null;
}

function looksLikeIngredient(line) {
  const withoutBullet = line.replace(bulletPrefix, '');
  const wordCount = withoutBullet.split(/\s+/).filter(Boolean).length;

  if (wordCount > 8) return false;
  if (parseIngredientLine(withoutBullet).quantity !== null) return true;

  return bulletPrefix.test(line) && wordCount <= 6;
}

export function readPastedRecipe(text) {
  const result = { name: '', ingredients: [], instructions: [], notes: [] };
  let section = null;

  for (const rawLine of String(text ?? '').split('\n')) {
    const line = rawLine.trim();

    if (!line) continue;

    const header = headerSection(line);
    if (header) {
      section = header;
      continue;
    }

    if (!result.name && !section && !looksLikeIngredient(line)) {
      result.name = line.replace(/^#+\s*/, '');
      continue;
    }

    const target = section ?? (looksLikeIngredient(line) ? 'ingredients' : 'instructions');

    if (target === 'ingredients') {
      result.ingredients.push(line);
    } else {
      result[target].push(line.replace(bulletPrefix, ''));
    }
  }

  return result;
}
