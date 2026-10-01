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

## What works now

The status page. It shows whether the token is set, whether the three databases exist,
whether Notion answers, and how old the cache is.

## Project layout

```
server.js              HTTP server and routes
bin/setup-notion.js    Creates the three Notion databases
src/config.js          Reads .env and data/config.json
src/notion/client.js   Notion REST client, with rate limits and retries
src/notion/schema.js   The property definitions of the three databases
src/store/cache.js     The local copy of the Notion records
src/store/json.js      Atomic JSON file reads and writes
src/web/               Router, page layout, and pages
data/                  config.json, cache.json, usage log (not in git)
```

## Still to build

- Recipes: list, add, edit, and an easy paste-a-recipe form
- Pantry: stock levels and one name for each ingredient
- Weekly plan: chosen recipes, and a shopping list that subtracts the pantry stock
- Averages: how much of each ingredient you use each week
- Suggestions: a proposed week that uses up the pantry and keeps the food varied
