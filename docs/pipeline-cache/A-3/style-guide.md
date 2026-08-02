# Coding Style Guide (cached 2026-08-02, source: https://app.notion.com/p/3ac4af79fc018179b160c9bd5ebf1d4a)

> Living record of Vinnie's coding style preferences for the `tcg_fantasy_league` repo. Built up over time as preferences are stated or confirmed during coding sessions.
>
> - Written to by the `/coding-style` skill (`.claude/skills/coding-style/`), on explicit invocation or when it notices a style correction during a task.
> - Read by the `/ticket-pipeline` skill before implementing tickets, as binding style guidance alongside the repo's own conventions. `/ticket-pipeline` should treat this page as read-only.
> - **Style Rules** below is the distilled, current guidance — short imperative bullets. **Change Log** at the bottom is the append-only history of when/why each rule was added, for auditability.

## Style Rules

### Naming Conventions
*No entries yet.*

### Structure & Architecture
- **Don't abstract prematurely (WET).** Duplication is fine through the first two occurrences of a pattern. On the third, reassess whether a module or inheritance pattern now fits. Exception: if epic/feature planning already shows a pattern is needed (e.g. multiple variants are known upfront), introduce the abstraction proactively instead of waiting for a third duplicate.
- **Depend on behavior, not concrete classes.** When a class needs a collaborator whose implementation might vary (an adapter, a calculator, a pricing rule), accept it as an injected constructor/method argument instead of instantiating a specific class inside the method — a dependency should be limited to a message name, its arguments, and their order, never a hardcoded class name.
- **Default to composition over inheritance.** Reach for inheritance when there's a known family of classes varying along one dimension with a lot of shared behavior — signaled by branching on a type/category attribute, or known upfront from planning. Keep any hierarchy shallow (one level, two at most — deeper means composition was probably the better fit somewhere along the way).
- **Write elegant inheritance and modules with hooks, not `super`.** A base class or module should define the shared algorithm (Template Method) and call hook methods that subclasses/includers override, instead of requiring them to override a method and call `super`. This applies to modules too — `include` puts a module in the ancestor chain, so it carries the same coupling risk as class inheritance and deserves the same care.

### Error Handling
*No entries yet.*

### Comments & Documentation
*No entries yet.*

### Testing
- **Example names describe outcomes, not technical details.** Name examples for the behavior/outcome the code produces ("rejects an expired draft"), not the mechanism used to produce it ("calls validate!").
- **No tautological specs.** Don't write an example that just re-asserts what the code trivially does by construction (e.g. testing a bare `attr_accessor` returns what was assigned).
- **Limit assertions per example.** One logical assertion in isolated unit specs; multiple expectations are acceptable in request/integration specs where repeating expensive setup per assertion isn't worth it.
- **Use `describe`/`context` to express structure** — `describe` for methods/behavior, `context` for conditions/state — instead of flattening everything into one block.
- **No `let!` — use `let` (lazy) plus an explicit `before` block** when eager creation is required, so setup order is visible instead of implicit.
- **Structure each example in four phases: Given (setup), When (exercise), Then (verify), separated by blank lines.** The fourth phase, teardown, is implicit — handled by the test framework, never written by hand.

### Formatting
*No entries yet.*

### Ruby / Rails Specific
- **Keyword arguments over positional.** Methods with more than one argument use keyword arguments, not positional — reserve positional args for true single-argument methods or well-known Ruby idioms (`each`, comparison operators). Already the norm in `app/services`.
- **All user-facing strings go through `I18n.t`, scoped under the relevant controller/view/model** — never a bare top-level key (use a `common` parent if there's no natural scope). No hardcoded English strings in views, flash messages, or validation messages.

### JavaScript Specific
*No entries yet.*

### Anti-patterns to Avoid
- **Branching on an object's class or a type/category attribute** (`case obj.class`, `if x.is_a?(Y)`, `case @game.id`) **to pick behavior.** Fix with duck typing (shared interface) for loosely related variants, or a real inheritance hierarchy for a well-defined family (see Structure & Architecture).
- **Scattering `nil`/missing-case checks across call sites.** Conditionals compound and force shotgun surgery when they need to change. Isolate the special case at one boundary using a Null Object (an object responding to the same interface as the real one) instead of checking for nil everywhere it might appear.

### General
- **No unexplained literals (numbers, strings, arrays, regexes) in logic — name them.** Prefer a method over a bare `CONSTANT` when the value is computed, environment-dependent, or likely to need logic later; reserve constants for values that are truly fixed and context-free.
- **Fix opportunistically, not via dedicated migrations.** When a new style rule is added, don't write a sweep/migration plan for existing violations — correct them incidentally when a file is already being touched for another reason.

## Change Log
*Newest entries go at the top.*
(see live page for full change log — omitted here, not needed by downstream phases)
