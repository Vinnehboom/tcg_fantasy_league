# The dashboard page

`board.html` is the source of the live status board. The board is a
published Artifact. Its URL is `dashboard_artifact_url` in
`.claude/kanban-cycle.json`.

This file is a copy, kept for repair. The live page is the published
artifact, not this file.

## What the page does

The page holds no state. It reads three collections from the artifact's
own document store and shows them:

- `state/snapshot` — the current picture. One document, replaced by
  every cycle.
- `cycles/<id>` — one short document per cycle. The page shows the most
  recent 40, newest first.
- `answers/<id>` — a reply that Vinnie typed on the page. The page
  writes these. A cycle reads them at step 0 and then removes them.

Step 7 of `../SKILL.md` gives the field-by-field shape of each document.
That step is the contract. If you change a field name here, change it
there in the same commit.

The page also carries a fallback copy of the snapshot, in the `FALLBACK`
constant. The page shows the fallback for the first moment after load,
and whenever the document store does not answer. A banner marks it, with
the date it was captured.

## To repair or change the page

1. Edit `board.html`.
2. Publish it with the `Artifact` tool. Pass `url` set to
   `dashboard_artifact_url`, and the same file path.
3. Do not pass `capabilities`. An omitted `capabilities` keeps the `db`
   declaration that the page needs.

CAUTION: Do not publish this file without the `url` parameter. A publish
without it creates a second board at a new URL. Vinnie's bookmark and
every link in the cycle log then point at a board that no cycle updates.
