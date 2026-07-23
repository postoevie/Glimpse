# Agent instructions — Glimpse

## Project

**Glimpse** is a public portfolio vocabulary app: capture words/phrases in 0–1 taps, organize by language (+ optional custom folder), search, study with flashcards, and on-demand AI aids (translation, examples, discover-similar).

Built for the owner’s personal use first. Tagline and product overview: `README.md` (when present).

### Product & design docs

Canonical product docs live in this repo:

| Stage | Doc |
|---|---|
| Product discovery | `docs/project-discovery.md` |
| PRD | `docs/prd.md` |
| User flows | `docs/user-flows.md` |
| Information architecture | `docs/information-architecture.md` |
| Domain modeling | `docs/domain-modeling.md` |
| Feature breakdown | `docs/feature-breakdown.md` |
| Technical design | `docs/technical-design.md` |
| Architecture | `docs/architecture.md` |
| Increment planning | `docs/increment-planning.md` |

Local planning slices (when present): `docs/planning/`.

**Task ↔ code (light):** On close, impl plan gets a `## Code` file list; feature roots may get a one-line `// Task: …` breadcrumb. See `docs/development-workflow.md` (§ Close) when that doc exists, and `.cursor/rules/task-code-traceability.mdc`.

**Live progress** (stage, increment, task, open questions): `docs/STATUS.md` when present — update there; do not put mutable status in `.cursor/rules/tech-lead.mdc`.

**Stage 10 delivery loop:** `docs/development-workflow.md` when present (plan → code → verify → test → review → close).

**Stage 11 testing & profiling:** `docs/testing-profiling.md` when present. **Package tests:** allowed separately; agents must ask whether to clean `.build`/`.swiftpm` afterward — see that doc § Package tests & `.cursor/rules/package-test-hygiene.mdc`.

### Packages & app

| Path | Role |
|---|---|
| `Packages/GlimpseCore` | Models, store, services, clients — **no TCA types** |
| `Packages/GlimpseAI` | On-demand generation |
| `Packages/GlimpseFeatures` | TCA screen features |
| `Glimpse/` + `Glimpse.xcodeproj` | Runnable blueprint app |

**Naming:** Types introduced in this repo start with the **`GLI`** prefix (e.g. `GLIWordPair`, `GLIAppGroup`).

Glimpse is an **independent** project. Do not assume or reference any sibling commercial app.

---

## Subagent routing (Swift implementation)

Route by **risk**, not by “any Swift.” The user does **not** need to name the subagent. Do **not** write specialist-owned Swift in the parent unless the user asks the parent to do it directly.

### Stay in the parent (small / safe)

Handle in the parent when the change is **local and low-risk**, for example:

- Copy, labels, typography, padding, colors, SF Symbol renames
- One-line or few-line fix in an **existing** view/helper (no new types, no new files)
- Docs, rules, AGENTS, planning markdown, non-Swift config
- Product / planning questions

If unsure whether it’s small: prefer parent for a tiny edit; escalate if the edit grows into structure.

### Launch specialists (structural / TCA / Core)

When the user asks to **implement, create, update, or fix** work that is structural, use the Task tool:

| When | Call |
|---|---|
| New or non-trivial SwiftUI screens; layout/a11y beyond tweaks; **services/clients**; **SwiftData** models/containers/adapters; App Group / Keychain helpers | `swift-developer` |
| New or changed TCA reducers, state, actions, Effects, feature `@Dependency` wiring | `tca-engineer` |
| TCA design unclear (state shape, navigation, dependency boundaries) before coding | `tca-architect` first, then `tca-engineer` |
| Task spans UI/services **and** reducers | `swift-developer` + `tca-engineer` (parallel when independent; otherwise services/UI first or as the request implies) |
| Implementation done — write tests | `swift-test-creator` |
| Implementation done — review before testing | `swift-code-reviewer` |

**Always specialist** for: new feature modules, new persistence/models, new clients, reducer/Effect graphs, navigation/presentation state, anything crossing Core ↔ Features boundaries.

---

## CRITICAL — do not auto-reconcile to prior instructions

The owner may edit any project content after the agent (source, docs, rules, agents, configs, entitlements, project files, etc.). That content may no longer match earlier descriptions, conventions, or chat instructions.

**Treat the tree as source of truth.** Do **not** silently revert, rewrite, or “fix” owner edits so they match previous prompts, AGENTS.md, cursor rules, docs, or naming conventions.

- Only change what the **current** request names.
- No drive-by conformance across unrelated files or content types.
- If current content conflicts with an older instruction or doc: **point it out and ask** — do not auto-resolve.
