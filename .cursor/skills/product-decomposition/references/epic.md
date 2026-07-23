# Create an epic

## Workflow A — Create an epic

Trigger examples: “create epic for I1”, “write capture→folder→card epic”.

1. Identify increment (I0, I1, …) from user or `increment-planning.md`.
2. Read relevant Glimpse docs (flows, IA, PRD, features, domain).
3. Write one epic file using **Epic template** below.
4. Epic outcome = end-to-end user-visible result for that slice.
5. Build order = product sequence of capabilities (not engineering layers).
6. Task list may be titles only until tasks are authored; link files as they exist.

---

## Epic template

```markdown
# I<n> — <Short product title>

**Type:** Product epic  
**Parent:** `docs/increment-planning.md` → I<n>  
**Product refs:** Glimpse `<docs used>`

---

## Epic outcome

<One paragraph: user-visible end-to-end result>

---

## User problem

<Why this slice exists>

---

## User story

**As a** …  
**I want** …  
**so that** …

---

## User journey (end state)

1. …
2. …

---

## Build order (product sequence)

1. …
2. …

---

## In scope

- …

## Out of scope

- …

---

## Product requirements

- …

---

## Feature mapping

| Product capability | Source feature IDs |
|---|---|
| … | F… / X… |

---

## Tasks

1. <title> — `I<n>-T<m>-<slug>/I<n>-T<m>-<slug>.md` (when file exists)
2. …

---

## Epic acceptance criteria

- [ ] …

---

## Epic Definition of Done

- [ ] All product tasks accepted
- [ ] Happy path matches Glimpse user flows for this slice
- [ ] No out-of-scope capability included
- [ ] Owner verifies epic outcome
```

---

