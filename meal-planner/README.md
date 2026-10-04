# Meal planner

A small web app for weekly meal planning. It keeps your recipes, your pantry stock and
your weekly plans in Notion. It runs on your own computer. It has no dependencies.

The app needs no supermarket account. It produces a shopping list that you read and
then buy from yourself.

## What goes where

Notion holds every record that a person reads or edits. A local cache holds a copy of
those records.

| Data | Where it lives | Why |
| --- | --- | --- |
| Recipes, with ingredients and instructions | Notion | Both of you add and edit recipes there |
| Pantry stock | Notion | Quick to correct from a phone |
| Weekly plans and shopping lists | Notion | The list is read where the plan is |
| Usage log, one row per cooked ingredient | Local file | Machine data, thousands of rows, nobody edits it |
| Copy of the Notion records | Local cache file | Speed, and the app still works when Notion is down |

The Notion API accepts about three requests each second. A read of every recipe needs
many requests. The app reads its cache for each page instead, so the pages open fast.

## Before you start

You need Node.js 18.17 or later. You also need a Notion account.

## Set it up

1. Create an internal integration at `notion.so/my-integrations`. Copy its token.
2. Copy `.env.example` to `.env`.
3. Put the token in `NOTION_TOKEN`.
4. Create a Notion page that will hold the three databases.
5. Open the `...` menu of that page. Select **Connections**. Add your integration.
6. Copy the id of that page into `NOTION_PARENT_PAGE_ID`.
7. Run `npm run setup:notion`. The command creates the three databases.
8. Run `npm start`.
9. Open `http://localhost:3000`.

The page id is the 32-character string at the end of the page URL.

If step 7 reports "not found", the integration has no access to the page. Do step 5
again, then run the command again.

You can run `npm run setup:notion` more than once. It skips each database that
`data/config.json` already names.

CAUTION: Keep `data/config.json`. It holds the ids of your three Notion databases. If
you erase this file, the next setup creates three more databases.

## Create the databases by hand

You can build the three databases in Notion yourself. Then you do not need the setup
command.

Each property name must match the tables below exactly. The app finds a property by its
name.

### Recipes

| Property | Type | Options to add |
| --- | --- | --- |
| `Name` | Title | — |
| `Rating` | Select | Favourite, Good, Fine, Retire |
| `Tags` | Multi-select | your own, add them as you go |
| `Servings` | Number | — |
| `Prep minutes` | Number | — |
| `Source` | URL | — |
| `Ingredients read by app` | Text | — |
| `Ingredient status` | Select | Read, Needs review |
| `Last cooked` | Date | — |
| `Times cooked` | Number | — |

### Pantry

| Property | Type | Options to add |
| --- | --- | --- |
| `Item` | Title | — |
| `Quantity` | Number | — |
| `Unit` | Select | g, kg, ml, l, tbsp, tsp, piece, clove, slice, can, jar, pack, bunch, pinch |
| `Category` | Select | Fresh produce, Meat and fish, Dairy, Dry goods, Tins and jars, Frozen, Herbs and spices, Drinks, Other |
| `Best before` | Date | — |
| `Notes` | Text | — |

### Shopping weeks

| Property | Type | Options to add |
| --- | --- | --- |
| `Week` | Title | — |
| `Starts on` | Date | — |
| `Status` | Select | Planned, Shopped, Cooked, Skipped |
| `Recipes` | Relation to the Recipes database | — |
| `Shopping notes` | Text | — |

### Write the ids into the configuration

Write `data/config.json` yourself:

```json
{
  "databases": {
    "recipes": "the 32-character id",
    "pantry": "the 32-character id",
    "weeks": "the 32-character id"
  }
}
```

The app needs the id of `recipes` to run. It reads the pantry and the weeks in a later
version.

`.env` still needs `NOTION_TOKEN`. Leave `NOTION_PARENT_PAGE_ID` empty, because only the
setup command reads it.

### Four points to watch

1. Keep the title column of Recipes named `Name`. The app sorts the query by `Name`.
   Notion rejects the request when that property is absent.
2. Rename the title column of Pantry to `Item`. Rename the title column of Shopping
   weeks to `Week`. Notion names it `Name` in each new database.
3. Add your integration to each database. Use the `...` menu, then **Connections**. A
   database inside a connected page inherits that connection.
4. Copy the id of the database, not the id of the view. The URL of a full-page database
   holds two ids. Take the one before `?v=`.

## What works now

Recipes. You can add a recipe, read your recipes back from Notion, and see what the app
understood.

The status page shows whether the token is set, whether the three databases exist,
whether Notion answers, and how old the cache is.

### Add a recipe

1. Open `http://localhost:3000/recipes`.
2. Select **Add a recipe**.
3. Paste the whole recipe into the first box.
4. Select **Read it into the form**.
5. Correct the name, the ingredients and the instructions.
6. Select **Save to Notion**.

The app writes the ingredients and the instructions into the page body in Notion. Each
one gets its own heading.

### Read your changes back from Notion

You can write a recipe in Notion instead. Then select **Read from Notion** on the
recipes page. The app reads the body of a page only when that page changed.

If the app cannot read an ingredient line, the recipe gets a flag. The Notion row also
holds what the app understood, in the **Ingredients read by app** property. Correct the
line in Notion, then read the recipes again.

### How the app reads an ingredient line

The app reads an amount, a unit and an item from each line:

| You write | The app reads |
| --- | --- |
| `400 g pasta` | 400 g of pasta |
| `400g pasta` | 400 g of pasta |
| `2 tablespoons olive oil` | 2 tbsp of olive oil |
| `1 tin chopped tomatoes` | 1 can of chopped tomatoes |
| `2 cloves garlic` | 2 cloves of garlic |
| `1 1/2 kg potatoes` | 1.5 kg of potatoes |
| `2-3 carrots` | 3 carrots, with "2 to 3" as a note |
| `a pinch of salt` | 1 pinch of salt |
| `1 onion, finely chopped` | 1 onion, with "finely chopped" as a note |
| `100 g feta (optional)` | 100 g of feta, with "optional" as a note |
| `salt and pepper` | salt and pepper, with no amount |

An item with no amount is correct. You add salt to taste, not by weight.

Headings make the reading reliable. The app looks for a heading that names the
ingredients, and one that names the instructions. **Method**, **Steps** and
**Directions** all count as the instructions. If a page has no headings, the app reads
the bullet list as the ingredients and the numbered list as the instructions.

## Tests

Run `npm test`. The command uses the test runner of Node, so it needs no install.

## Project layout

```
server.js                       HTTP server and routes
bin/setup-notion.js             Creates the three Notion databases
src/config.js                   Reads .env and data/config.json
src/sync.js                     Reads the Notion records into the cache
src/notion/client.js            Notion REST client, with rate limits and retries
src/notion/schema.js            The property definitions of the three databases
src/notion/recipes.js           Reads and writes recipe pages
src/recipes/ingredient-line.js  Reads one ingredient line into amount, unit and item
src/recipes/body.js             Reads and writes the body of a recipe page
src/recipes/paste.js            Reads a pasted recipe into name, ingredients and steps
src/store/cache.js              The local copy of the Notion records
src/store/json.js               Atomic JSON file reads and writes
src/web/                        Router, page layout, and pages
data/                           config.json and cache.json (not in git)
```

## Still to build

- Pantry: stock levels, and one name for each ingredient
- Weekly plan: chosen recipes, and a shopping list that subtracts the pantry stock
- Averages: how much of each ingredient you use each week
- Suggestions: a proposed week that uses up the pantry and keeps the food varied
