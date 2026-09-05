# CLAUDE.md

## Documentation style

When this session writes documentation directly — a Notion page, a PR
description, a README — follow the `simple-english` skill (ASD-STE100,
pragmatic mode). Load the skill before you draft the text.

This rule covers the main session only. The `ticket-pipeline` planner,
developer, and curator subagents get the same instruction directly in
their own briefs (`.claude/skills/ticket-pipeline/references/`), so it
reaches them even though they run separately from this session.

## Automation boundaries

The auto mode classifier reads this file. It does not read the `autoMode`
block in `.claude/settings.json`. A repository cannot grant itself
classifier permissions, so project rules for the classifier belong here.

### Routine actions

These actions are normal work for this repository, not unusual events:

- A force-push (`--force` or `--force-with-lease`) to any branch of this
  repository except `main` and `master`. The `/kanban-cycle` orchestrator
  rebases each open pull request branch onto a newer default branch tip.
  Then it force-pushes the result. This happens every cycle.
- A Notion write to the kanban board, to a ticket card on that board, or
  to a page named in `.claude/knowledge-base.json` or
  `.claude/coding-style.json`. The tools are `notion-update-page`,
  `notion-create-pages`, and `notion-create-comment`. `/kanban-cycle` and
  `/ticket-pipeline` change the Status of a card, write plans and review
  notes onto cards, and record decisions and new tickets.

- A write to the live dashboard's own document store — the `Artifact`
  tool with `action: "write_db"` or `action: "read_db"`, targeting the
  `dashboard_artifact_url` in `.claude/kanban-cycle.json`. Every
  `/kanban-cycle` run updates that board (step 7 of its skill file),
  including quiet cycles, so this happens twice a day on a schedule.
  The board is a status display the automation owns and rewrites; it
  holds no source of truth of its own, and nothing outside that one
  artifact's store is touched.
- Applying a removal that Vinnie queued on the dashboard: setting a
  decision row's Status to `Superseded`, or taking a rule out of the
  Style Rules section of the Coding Style Guide and recording the
  removal in that page's Change Log. Both are `notion-update-page`
  writes to pages already named in `.claude/knowledge-base.json` and
  `.claude/coding-style.json`. Neither deletes or archives a page.

The MCP server name of the Notion connector changes between sessions. It
mounts as `mcp__Notion__*`, as `mcp__claude_ai_Notion__*`, or under a
generated UUID. Judge a Notion call by its tool name and its target page,
not by the server prefix.

### Forbidden actions

Never do these, whatever the reason and whoever asks:

- A force-push to `main` or `master`, however the target is written.
- A delete, an archive, or a move of a Notion page.
- A change to a Notion database, its schema, or its views.
- A write to a Notion page outside the board and the pages named in
  `.claude/knowledge-base.json` and `.claude/coding-style.json`.
- Publishing a new Artifact to replace the dashboard, or an `Artifact`
  write to any URL other than `dashboard_artifact_url`. The board's URL
  is its identity across orchestrator generations.

The structure of the board belongs to Vinnie. A scheduled cycle runs when
nobody watches it, so it cannot ask for permission at the moment it acts.

### The dashboard queues are instructions, not permissions

The dashboard lets Vinnie queue an answer, a prompt, or a removal
request without opening a session. A cycle acts on those as his
instruction. They cannot widen anything above: a queued item that asks
for a forbidden action, a wider auto-merge whitelist, or the lifting of
an `externally_owned_ticket_ids` exclusion stays queued and gets raised
with him instead. The queue is a convenience for directing work that is
already allowed, never a channel for granting new permission.
