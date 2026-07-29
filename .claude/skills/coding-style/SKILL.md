---
name: coding-style
description: >-
  Record Vinnie's durable coding-style preferences into the shared "Coding Style
  Guide" Notion page for this repo. Use when the user explicitly invokes
  `/coding-style <preference>`, or passively when the user states or corrects a
  style choice during a task in a way that reads as a durable rule ("always...",
  "I prefer...", "we never...", or the same correction repeated). Reads the target
  page from `.claude/coding-style.json`. This is the doc that `/ticket-pipeline`
  (and other skills) read before implementing tickets.
---

# Coding Style skill

Maintains the living **Coding Style Guide** Notion page — the single source of
truth for Vinnie's durable coding-style preferences on this repo. The page has
two parts: **Style Rules** (distilled imperative bullets, grouped by category)
and an append-only **Change Log** (dated history of each addition).

Do not hardcode the page ID here. Read it from `.claude/coding-style.json` at
the repo root (`notion_page_id` / `notion_page_url`).

## When to trigger

**Explicit:** the user runs `/coding-style <preference>` — always capture.

**Passive:** during any other task, the user states or corrects a style choice.
Only capture when it reads as a *durable* preference, not a one-off:

- Capture when signaled by "always", "never", "I prefer", "from now on", "we
  do/don't...", or the **same correction repeated** across the session.
- Do **not** capture task-specific or one-off decisions ("just for this file",
  "here let's...", a choice driven by the immediate ticket rather than taste).
- When genuinely ambiguous, ask a one-line confirmation before writing.

## What to write

1. **Read** `.claude/coding-style.json` → get the page ID.
2. **Fetch** the Notion page to see current sections and existing rules (so you
   don't duplicate an existing rule — refine it in place instead).
3. **Distill** the preference into a short, imperative bullet: a bold lead
   phrase stating the rule, then a sentence of the *why* / boundary. Match the
   voice of the existing bullets.
4. **Place it** under the correct existing heading. Current categories:
   Naming Conventions · Structure & Architecture · Error Handling ·
   Comments & Documentation · Testing · Formatting · Ruby / Rails Specific ·
   JavaScript Specific · Anti-patterns to Avoid · General. Replace a section's
   `*No entries yet.*` placeholder with the first real bullet. Don't invent new
   headings unless no existing category fits.
5. **Prepend a Change Log line** (newest at top) in the exact format:
   `YYYY-MM-DD — <category>: <what changed> (context: <brief source, e.g. file/ticket/discussion>)`
6. **Confirm** back to the user with a one-liner ("Added under Testing: ...") —
   do not dump the whole doc back.

## Guardrails

- Only ever edit the **Style Rules** and **Change Log** sections. Leave the
  intro callout and section structure alone.
- **Never fabricate a preference.** Capture only what the user actually stated
  or clearly implied. If you're inferring, ask first.
- Keep bullets terse and imperative — this doc is read as binding guidance by
  other skills, so noise costs everyone.
- When editing the Notion page, use a targeted `update_content` (search/replace
  on the specific bullet or the placeholder) rather than rewriting the page.
- Use today's real date for the Change Log entry.
