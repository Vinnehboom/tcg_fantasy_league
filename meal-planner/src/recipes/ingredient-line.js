const unitAliases = new Map([
  ['g', 'g'], ['gr', 'g'], ['gram', 'g'], ['grams', 'g'], ['gramme', 'g'], ['grammes', 'g'],
  ['kg', 'kg'], ['kilo', 'kg'], ['kilos', 'kg'], ['kilogram', 'kg'], ['kilograms', 'kg'],
  ['ml', 'ml'], ['milliliter', 'ml'], ['millilitre', 'ml'], ['milliliters', 'ml'], ['millilitres', 'ml'],
  ['l', 'l'], ['liter', 'l'], ['litre', 'l'], ['liters', 'l'], ['litres', 'l'],
  ['tbsp', 'tbsp'], ['tbs', 'tbsp'], ['tablespoon', 'tbsp'], ['tablespoons', 'tbsp'],
  ['tsp', 'tsp'], ['teaspoon', 'tsp'], ['teaspoons', 'tsp'],
  ['clove', 'clove'], ['cloves', 'clove'],
  ['slice', 'slice'], ['slices', 'slice'],
  ['can', 'can'], ['cans', 'can'], ['tin', 'can'], ['tins', 'can'],
  ['jar', 'jar'], ['jars', 'jar'],
  ['pack', 'pack'], ['packs', 'pack'], ['packet', 'pack'], ['packets', 'pack'],
  ['bunch', 'bunch'], ['bunches', 'bunch'],
  ['pinch', 'pinch'], ['pinches', 'pinch'],
  ['piece', 'piece'], ['pieces', 'piece'],
]);

const vulgarFractions = new Map([
  ['½', 0.5], ['¼', 0.25], ['¾', 0.75], ['⅓', 1 / 3], ['⅔', 2 / 3],
]);

const bulletPrefix = /^\s*(?:[-*•–—]|\d+[.)])\s+/;
const rangePattern = /^(\d+(?:[.,]\d+)?)\s*(?:-|–|to)\s*(\d+(?:[.,]\d+)?)(?=\s|$)/;
const mixedFractionPattern = /^(\d+)\s+(\d+)\/(\d+)(?=\s|$)/;
const simpleFractionPattern = /^(\d+)\/(\d+)(?=\s|$)/;
const vulgarPattern = /^(\d+(?:[.,]\d+)?)?\s*([½¼¾⅓⅔])(?=\s|$|[a-z])/;
const decimalPattern = /^(\d+(?:[.,]\d+)?)(?=\s|$|[a-z])/;
const articlePattern = /^(?:a|an)(?=\s)/i;
const parenthesisPattern = /\s*\(([^)]*)\)\s*/;

function toNumber(text) {
  return Number(text.replace(',', '.'));
}

function round(value) {
  return Math.round(value * 1000) / 1000;
}

function takeQuantity(text) {
  const range = text.match(rangePattern);
  if (range) {
    return {
      quantity: toNumber(range[2]),
      rest: text.slice(range[0].length),
      note: `${range[1]} to ${range[2]}`,
    };
  }

  const mixed = text.match(mixedFractionPattern);
  if (mixed) {
    return {
      quantity: round(Number(mixed[1]) + Number(mixed[2]) / Number(mixed[3])),
      rest: text.slice(mixed[0].length),
    };
  }

  const simple = text.match(simpleFractionPattern);
  if (simple) {
    return { quantity: round(Number(simple[1]) / Number(simple[2])), rest: text.slice(simple[0].length) };
  }

  const vulgar = text.match(vulgarPattern);
  if (vulgar) {
    const whole = vulgar[1] ? toNumber(vulgar[1]) : 0;
    return { quantity: round(whole + vulgarFractions.get(vulgar[2])), rest: text.slice(vulgar[0].length) };
  }

  const decimal = text.match(decimalPattern);
  if (decimal) {
    return { quantity: toNumber(decimal[1]), rest: text.slice(decimal[0].length) };
  }

  const article = text.match(articlePattern);
  if (article) {
    return { quantity: 1, rest: text.slice(article[0].length) };
  }

  return { quantity: null, rest: text };
}

function takeUnit(text) {
  const match = text.match(/^\s*([a-zA-Z]+)\.?(?=\s|$)/);
  if (!match) return { unit: null, rest: text };

  const unit = unitAliases.get(match[1].toLowerCase());
  if (!unit) return { unit: null, rest: text };

  return { unit, rest: text.slice(match[0].length) };
}

export function parseIngredientLine(rawLine) {
  const raw = rawLine.trim();
  const withoutBullet = raw.replace(bulletPrefix, '');

  const { quantity, rest: afterQuantity, note: rangeNote } = takeQuantity(withoutBullet);
  const { unit: namedUnit, rest: afterUnit } = takeUnit(afterQuantity);

  let remainder = afterUnit.trim().replace(/^of\s+/i, '');
  const notes = rangeNote ? [rangeNote] : [];

  const parenthesis = remainder.match(parenthesisPattern);
  if (parenthesis) {
    notes.push(parenthesis[1].trim());
    remainder = remainder.replace(parenthesisPattern, ' ').trim();
  }

  const commaAt = remainder.indexOf(',');
  if (commaAt > 0) {
    notes.push(remainder.slice(commaAt + 1).trim());
    remainder = remainder.slice(0, commaAt).trim();
  }

  const item = remainder.replace(/\s+/g, ' ').trim();
  const unit = namedUnit ?? (quantity === null ? null : 'piece');

  return {
    raw,
    quantity,
    unit,
    item,
    note: notes.filter(Boolean).join('; ') || null,
    understood: item.length > 0,
  };
}

export function formatIngredientLine({ quantity, unit, item, note }) {
  const amount = [
    quantity === null || quantity === undefined ? '' : String(round(quantity)),
    unit && unit !== 'piece' ? unit : '',
  ].filter(Boolean).join(' ');

  const head = [amount, item].filter(Boolean).join(' ');

  return note ? `${head}, ${note}` : head;
}

export { bulletPrefix, unitAliases };
