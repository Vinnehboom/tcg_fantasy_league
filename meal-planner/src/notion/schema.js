export const RECIPES = 'recipes';
export const PANTRY = 'pantry';
export const WEEKS = 'weeks';

export const units = [
  'g', 'kg', 'ml', 'l', 'tbsp', 'tsp',
  'piece', 'clove', 'slice', 'can', 'jar', 'pack', 'bunch', 'pinch',
];

export const pantryCategories = [
  'Fresh produce', 'Meat and fish', 'Dairy', 'Dry goods',
  'Tins and jars', 'Frozen', 'Herbs and spices', 'Drinks', 'Other',
];

export const recipeRatings = ['Favourite', 'Good', 'Fine', 'Retire'];
export const weekStatuses = ['Planned', 'Shopped', 'Cooked', 'Skipped'];
export const parseStatuses = ['Read', 'Needs review'];

function select(options) {
  return { select: { options: options.map((name) => ({ name })) } };
}

function multiSelect(options = []) {
  return { multi_select: { options: options.map((name) => ({ name })) } };
}

function recipeProperties() {
  return {
    Name: { title: {} },
    Rating: select(recipeRatings),
    Tags: multiSelect(),
    Servings: { number: { format: 'number' } },
    'Prep minutes': { number: { format: 'number' } },
    Source: { url: {} },
    'Ingredients read by app': { rich_text: {} },
    'Ingredient status': select(parseStatuses),
    'Last cooked': { date: {} },
    'Times cooked': { number: { format: 'number' } },
  };
}

function pantryProperties() {
  return {
    Item: { title: {} },
    Quantity: { number: { format: 'number' } },
    Unit: select(units),
    Category: select(pantryCategories),
    'Best before': { date: {} },
    Notes: { rich_text: {} },
  };
}

function weekProperties(databaseIds) {
  return {
    Week: { title: {} },
    'Starts on': { date: {} },
    Status: select(weekStatuses),
    Recipes: { relation: { database_id: databaseIds[RECIPES], single_property: {} } },
    'Shopping notes': { rich_text: {} },
  };
}

export function databaseBlueprints() {
  return [
    {
      key: RECIPES,
      title: 'Recipes',
      description: 'One page per recipe. Write the ingredient list and the instructions in the page body.',
      properties: recipeProperties,
    },
    {
      key: PANTRY,
      title: 'Pantry',
      description: 'What is in the cupboards and the fridge right now.',
      properties: pantryProperties,
    },
    {
      key: WEEKS,
      title: 'Shopping weeks',
      description: 'One page per week. Holds the chosen recipes and the shopping list.',
      properties: weekProperties,
    },
  ];
}
