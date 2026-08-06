# Coding Style Guide (cached 2026-08-06)

url: https://app.notion.com/p/3ac4af79fc018179b160c9bd5ebf1d4a

> Living record of Vinnie's coding style preferences for the `tcg_fantasy_league` repo.

## Style Rules

### Naming Conventions
No entries yet.

### Structure & Architecture
- **Don't abstract prematurely (WET).** Duplication is fine through the first two occurrences of a pattern. On the third, reassess whether a module or inheritance pattern now fits. Exception: if epic/feature planning already shows a pattern is needed, introduce the abstraction proactively instead of waiting for a third duplicate.
- **Depend on behavior, not concrete classes.** When a class needs a collaborator whose implementation might vary (an adapter, a calculator, a pricing rule), accept it as an injected constructor/method argument instead of instantiating a specific class inside the method — a dependency should be limited to a message name, its arguments, and their order, never a hardcoded class name.
- **Default to composition over inheritance.** Reach for inheritance when there's a known family of classes varying along one dimension with a lot of shared behavior — signaled by branching on a type/category attribute, or known upfront from planning. Keep any hierarchy shallow (one level, two at most).
- **Write elegant inheritance and modules with hooks, not `super`.** A base class or module should define the shared algorithm (Template Method) and call hook methods that subclasses/includers override, instead of requiring them to override a method and call `super`. Applies to modules too.
- **Single-use-case services follow `initialize` + `#call`, with a `self.call(...)` class-method shortcut.** This is now the standard for `app/services`. **The standard covers single-action services only.** An object that is held and queried across multiple calls — an API client, a policy, a calculator, a pricing rule — stays a plain PORO with intention-revealing method names, taking its long-lived collaborators in `initialize`.
- **Read constructor state through private `attr_reader`s, not bare `@ivar`s, in service objects.**
- **Constructors take only what's knowable before the work starts.** Don't accept params that are actually produced *during* the work itself just to have them available later.
- **Don't declare a type just to document a shape.** A block/method's return contract can stay implicit (duck-typed) — read the methods you need off whatever comes back, no `is_a?` check — until the shape actually carries behavior worth attaching.

### Error Handling
- **Coerce data crossing an external boundary, don't type-test it.** HTTP headers, params, JSON payload values, and ENV vars are untyped text by definition. Use `Integer(value, exception: false)` / `Float(...)` and treat a `nil` result as "absent or unusable," instead of guarding the raw value with `is_a?`. Then clamp the coerced result to a sane range.

### Comments & Documentation
- **Code should be self-documenting — comments are for the essential and non-obvious only.**

### Testing
- **Example names describe outcomes, not technical details.**
- **No tautological specs.**
- **Limit assertions per example.** One logical assertion in isolated unit specs; multiple expectations acceptable in request/integration specs.
- **Use `describe`/`context` to express structure.**
- **No `let!` — use `let` (lazy) plus an explicit `before` block** when eager creation is required.
- **Structure each example in four phases: Given (setup), When (exercise), Then (verify), separated by blank lines.** Teardown is implicit.
- **Duck-typed spec fixtures: use a local `Struct`, not `double`/`OpenStruct`.**
- **Factories: deterministic base, randomized traits.**
- **Stub external data in its real wire shape, verified against the gem or API — not the shape that's convenient to write.** No webmock/VCR in this repo, so hand-stub fidelity is the only defense HTTP specs have — see the Tech Debt page.

### Formatting
No entries yet.

### Ruby / Rails Specific
- **Keyword arguments over positional.** Methods with more than one argument use keyword arguments, not positional.
- **All user-facing strings go through `I18n.t`, scoped under the relevant controller/view/model.**

### JavaScript Specific
No entries yet.

### Anti-patterns to Avoid
- **Branching on an object's class or a type/category attribute** (`case obj.class`, `if x.is_a?(Y)`, `case @game.id`) **to pick behavior.** Fix with duck typing (shared interface) for loosely related variants, or a real inheritance hierarchy for a well-defined family. **← this is exactly A-2's `select_adapter` case.**
- **Scattering `nil`/missing-case checks across call sites.** Isolate the special case at one boundary using a Null Object instead of checking for nil everywhere.

### General
- **No unexplained literals (numbers, strings, arrays, regexes) in logic — name them.**
- **Fix opportunistically, not via dedicated migrations.**
- **NEVER leave a `fixup!` commit in pushed or merged history — always squash it away before the branch is done.** `git commit --fixup=<sha>` is fine as a scratch step; before pushing for (re-)review, and always before merge, run `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>` (fully non-interactive) to fold every fixup into its target commit. Verify with `git log --oneline` that no `fixup!` subject lines remain before pushing.

(Change Log omitted from cache — see live page if needed; not required for implementation.)
