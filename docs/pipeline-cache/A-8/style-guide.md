# Coding Style Guide (cached at A-8 pipeline start)

Source: https://app.notion.com/p/3ac4af79fc018179b160c9bd5ebf1d4a

> Living record of Vinnie's coding style preferences for the `tcg_fantasy_league` repo.

## ADDITIONAL BINDING DIRECTIVE FOR THIS TICKET (from Vinnie, relayed by the orchestrator — durable, not a one-off)

"Too many comments; don't mention tickets or context in code — self documentation is the goal."

Concretely, for ALL new code on A-8:
- Do NOT reference ticket IDs, PR numbers, "review feedback", or any other meta/process
  context in code comments or commit-adjacent explanatory comments.
- Only add a comment when the WHY is genuinely non-obvious (a hidden constraint, a subtle
  invariant) — keep it to the minimum needed.
- Prefer well-named code and clear spec descriptions over comments.
- This sharpens (not contradicts) the existing "Comments & Documentation" rule below — apply
  the sharper version.

## Style Rules

### Naming Conventions
*No entries yet.*

### Structure & Architecture
- Don't abstract prematurely (WET). Duplication is fine through the first two occurrences of a
  pattern. On the third, reassess whether a module or inheritance pattern now fits. Exception:
  if epic/feature planning already shows a pattern is needed, introduce the abstraction
  proactively instead of waiting for a third duplicate.
- Depend on behavior, not concrete classes. Inject collaborators whose implementation might
  vary instead of instantiating a specific class inside the method.
- Default to composition over inheritance. Reach for inheritance when there's a known family
  of classes varying along one dimension with a lot of shared behavior. Keep any hierarchy
  shallow (one level, two at most).
- Write elegant inheritance and modules with hooks, not `super`. A base class or module should
  define the shared algorithm (Template Method) and call hook methods that
  subclasses/includers override.
- Single-use-case services follow `initialize` + `#call`, with a `self.call(...)` class-method
  shortcut. The standard covers single-action services only — a PORO held/queried across
  multiple calls (an API client, a policy, a calculator, a pricing rule) stays a plain PORO
  with intention-revealing method names.
- Read constructor state through private `attr_reader`s, not bare `@ivar`s, in service objects.
- Constructors take only what's knowable before the work starts. Don't accept params that are
  actually produced during the work itself just to have them available later.
- Don't declare a type just to document a shape. A block/method's return contract can stay
  implicit (duck-typed) until the shape actually carries behavior worth attaching.
- Tell, don't ask — no conditionals on what an object is. A caller inspecting a type/id/category
  to pick behavior (an `if`/`case` on a static string, a registry keyed by it, `constantize`)
  is a warning sign. When the right collaborator is knowable at write time from where code is
  called, give each case its own entry point instead of a runtime lookup.

### Error Handling
- Coerce data crossing an external boundary, don't type-test it. `Integer(value, exception:
  false)` / `Float(...)`, treat nil as absent/unusable, then clamp to a sane range.

### Comments & Documentation
- Code should be self-documenting — comments are for the essential and non-obvious only. Don't
  write a comment that just restates what the next line already says. (See sharpened directive
  above, binding for this ticket: never reference tickets/PRs/process in code comments.)

### Testing
- Example names describe outcomes, not technical details ("rejects an expired draft", not
  "calls validate!").
- No tautological specs (don't test a bare `attr_accessor` returns what was assigned).
- Limit assertions per example. One logical assertion in isolated unit specs; multiple
  expectations acceptable in request/integration specs where repeating expensive setup per
  assertion isn't worth it.
- Use `describe`/`context` to express structure — `describe` for methods/behavior, `context`
  for conditions/state.
- No `let!` — use `let` (lazy) plus an explicit `before` block when eager creation is required.
- Structure each example in four phases: Given (setup), When (exercise), Then (verify),
  separated by blank lines. Teardown is implicit.
- Duck-typed spec fixtures: use a local `Struct`, not `double`/`OpenStruct` (rubocop-rspec's
  `VerifiedDoubles`/`Style/OpenStructUse` cops reject those).
- Factories: deterministic base, randomized traits. Keep the plain `create(:factory)` call
  deterministic; add named traits for varied-but-stable fixtures.
- Stub external data in its real wire shape, verified against the gem or API — not the shape
  that's convenient to write. (Not directly relevant to A-8 — no external HTTP involved.)

### Formatting
*No entries yet.*

### Ruby / Rails Specific
- Keyword arguments over positional. Methods with more than one argument use keyword
  arguments — reserve positional args for true single-argument methods or well-known Ruby
  idioms.
- All user-facing strings go through `I18n.t`, scoped under the relevant
  controller/view/model — never a bare top-level key.

### JavaScript Specific
*No entries yet.*

### Anti-patterns to Avoid
- Branching on an object's class or a type/category attribute to pick behavior. Fix with duck
  typing or a real inheritance hierarchy.
- Scattering nil/missing-case checks across call sites. Isolate the special case at one
  boundary using a Null Object instead of checking for nil everywhere.

### General
- No unexplained literals (numbers, strings, arrays, regexes) in logic — name them. Prefer a
  method over a bare `CONSTANT` when the value is computed, environment-dependent, or likely
  to need logic later.
- Fix opportunistically, not via dedicated migrations. When a new style rule is added, don't
  write a sweep/migration plan for existing violations — correct them incidentally when a file
  is already being touched for another reason.
- NEVER leave a `fixup!` commit in pushed or merged history — always squash it away before the
  branch is done. `git commit --fixup=<sha>` is fine as a scratch step; before pushing for
  (re-)review, and always before merge, run `GIT_SEQUENCE_EDITOR=true git rebase -i
  --autosquash <base>` to fold every fixup into its target commit (fully non-interactive).
  Verify with `git log --oneline` that no `fixup!` subject lines remain before pushing.

## Change Log (most recent entries; see live Notion page for full history)
- 2026-08-08 — Structure & Architecture: tell-don't-ask rule, split entry point per static case.
- 2026-08-08 — Anti-patterns: Null Object implements exactly the contract, no more.
- 2026-08-05 — Testing: stub external data in its real wire shape.
- 2026-08-05 — Error Handling: coerce-at-the-boundary rule.
- 2026-08-05 — Structure & Architecture: PORO carve-out for held-and-queried collaborators.
- 2026-08-05 — General: fixup-commit rule corrected — always squash via autosquash, no TTY
  needed (context: 3 unsquashed fixups merged into `main` on PR #31).
- 2026-08-04 through 2026-07-29 — various (constructor-minimality, duck-typed-return-contracts,
  spec Struct-fixtures, factory traits, attr_reader-over-ivar, initialize+#call standard,
  self-documenting-code rule, describe/context, let!, four-phase specs, I18n scoping,
  keyword-arguments-over-positional, no-magic-values, fix-opportunistically, Null Object,
  type-branching → duck typing, WET, hooks-over-super, composition-over-inheritance,
  dependency-injection). See live Notion page for full text if needed.
