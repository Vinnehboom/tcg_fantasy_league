# Coding Style Guide

Source: https://app.notion.com/p/3ac4af79fc018179b160c9bd5ebf1d4a
Cached: 2026-08-05

> Living record of Vinnie's coding style preferences for the `tcg_fantasy_league` repo. Built up over time as preferences are stated or confirmed during coding sessions.
>
> - Written to by the `/coding-style` skill, on explicit invocation or when it notices a style correction during a task.
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
- **Single-use-case services follow `initialize` + `#call`, with a `self.call(...)` class-method shortcut.** A service object whose whole job is one action (`SomeService.call(args)` → `SomeService.new(args).call`) takes its inputs in `initialize`, does the work in `#call`, and exposes a class-level `call` so callers don't have to `.new` it themselves. This is now the standard for `app/services`, not just a convention one class happens to follow.
- **Read constructor state through private `attr_reader`s, not bare `@ivar`s, in service objects.** `initialize` sets the ivars; the rest of the class reads them through a reader method (`status` not `@status`). Cheap now, and it means adding logic later (memoization, a derived value) doesn't require touching every call site that referenced the ivar directly. Applies to all service objects, not just one.
- **Constructors take only what's knowable before the work starts.** Don't accept params that are actually produced *during* the work itself just to have them available later.
- **Don't declare a type just to document a shape.** A block/method's return contract can stay implicit (duck-typed) — read the methods you need off whatever comes back, no `is_a?` check — until the shape actually carries behavior worth attaching.

### Error Handling
*No entries yet.*

### Comments & Documentation
- **Code should be self-documenting — comments are for the essential and non-obvious only.** Good naming and structure should carry the WHY on their own; reserve comments for a genuinely non-obvious pattern, a hidden constraint, or a decision a reader couldn't otherwise reconstruct. Don't write a comment that just restates what the next line already says.

### Testing
- **Example names describe outcomes, not technical details.** Name examples for the behavior/outcome the code produces ("rejects an expired draft"), not the mechanism used to produce it ("calls validate!").
- **No tautological specs.** Don't write an example that just re-asserts what the code trivially does by construction (e.g. testing a bare `attr_accessor` returns what was assigned).
- **Limit assertions per example.** One logical assertion in isolated unit specs; multiple expectations are acceptable in request/integration specs where repeating expensive setup per assertion isn't worth it.
- **Use `describe`/`context` to express structure** — `describe` for methods/behavior, `context` for conditions/state — instead of flattening everything into one block.
- **No `let!` — use `let` (lazy) plus an explicit `before` block** when eager creation is required, so setup order is visible instead of implicit.
- **Structure each example in four phases: Given (setup), When (exercise), Then (verify), separated by blank lines.** The fourth phase, teardown, is implicit — handled by the test framework, never written by hand.
- **Duck-typed spec fixtures: use a local `Struct`, not `double`/`OpenStruct`.** `rubocop-rspec`'s `VerifiedDoubles` cop rejects a bare `double(...)`, and `Style/OpenStructUse` rejects `OpenStruct.new`. Define a small `Struct.new(:attr, ...).new(...)` scoped to the spec file when a fixture just needs to respond to a couple of methods.
- **Factories: deterministic base, randomized traits.** Keep the plain `create(:factory)` call deterministic — a randomized default can make a failing example non-reproducible. Add named traits (e.g. `:success`/`:failure`) that carry realistic randomized supporting data for specs that want varied-but-stable fixtures.

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
- **Use fixup commits for review-feedback fix rounds.** When a fix corrects something an earlier commit on the same branch introduced, commit it as `git commit --fixup=<sha-of-that-commit>` rather than a new plain standalone commit — keeps the branch squash-ready via `git rebase --autosquash` instead of piling up permanent one-line fix commits. `--fixup` itself is non-interactive and always fine to run; if the environment can't run interactive rebase to actually squash, leave the fixup-marked commits in place for a later cleanup rather than forcing it.

## Change Log

(Newest first — see live Notion page for full history; recent entries relevant to A-1's shape:)
- 2026-08-04 — Structure & Architecture: added constructor-minimality rule
- 2026-08-04 — Structure & Architecture: added duck-typed-return-contracts rule
- 2026-08-04 — Testing: added rule for duck-typed spec fixtures via a local `Struct`
- 2026-08-04 — Testing: added factory convention, deterministic base + randomized traits
- 2026-08-03 — Structure & Architecture: added attr_reader-over-bare-ivar rule for service objects
- 2026-08-03 — Structure & Architecture: added initialize+#call service-object standard with `self.call` shortcut
- 2026-08-03 — Comments & Documentation: added self-documenting-code rule
- 2026-08-03 — General: added fixup-commits-for-review-feedback rule
