# F{NN} — {Feature Name}

> One paragraph: what this feature is, the behaviour it delivers, and the foundation documents
> it depends on.

**Status:** NOT STARTED · **Milestone:** {N} · **Depends on:** {F-IDs}

---

## 1. Goal

What this lets a user do, and why. One tight paragraph.

## 2. MVP scope

The concrete capabilities this document ships.

## 3. Later scope

Explicitly deferred, so reviewers know it was considered rather than forgotten.

## 4. Roles and permissions

Who can do what. Reference the roles in `foundation/07-security.md` rather than redefining them.

## 5. Main flows

Sequence diagrams in plain text. The happy path plus the key failure transitions.

```text
user -> system: request
system: authenticate -> authorize -> do the work
system -> user: result
```

## 6. Interface surface

The endpoints, commands or public functions this feature adds, following
`foundation/04-interface-standards.md`.

```text
METHOD /path or command     summary                         (who may call it)
```

## 7. Domain model usage

Which entities and fields from `foundation/03-domain-model.md` this feature reads or writes.
**Names must match that document exactly.** If a needed field does not exist, raise it in
section 13 rather than inventing one.

## 8. Data changes

Tables, columns, files or schemas touched, and the migration that changes them.

## 9. Background work and events

Jobs, scheduled tasks, events emitted, audit records written: with retry and idempotency behaviour.

## 10. Degradation and failure

What this feature does when a dependency is down, data is stale, a value is missing, or a
permission is insufficient. **Every path must produce a stated outcome, never a silent zero.**

## 11. Validation assertions

> Written **before** implementation. They define correctness independently of whatever the code
> turns out to be. Format `F{NN}-A{NN}`; gate `[U]` unit, `[I]` integration, `[L]` live run.
> Never weakened to make a build pass; if one is genuinely wrong, amend it with a dated note.

```
F{NN}-A01  [U]  ...
F{NN}-A02  [I]  ...
F{NN}-A03  [L]  ...
```

At minimum this section covers:
- the happy path
- each failure path in section 10
- permission denial for each role that lacks access
- isolation of one user's or account's data from another's, where relevant
- "missing" versus "empty/zero" for every optional value consumed
- at least one `[L]` assertion against the running system

## 12. Edge cases

Boundary and failure conditions, each with its expected behaviour.

## 13. Open questions

Unresolved product or design decisions. Surface them; do not silently decide them.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: NOT STARTED

[ ] Gate 1  Interface documented
[ ] Gate 2  Unit
[ ] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 0/{N} PASS
Regression: —
```
