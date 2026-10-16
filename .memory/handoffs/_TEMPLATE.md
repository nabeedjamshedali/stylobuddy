# Handoff — F{NN} {Feature name}

> Copy to `.memory/handoffs/F{NN}.md` when you finish a feature. The `handoff_guard` hook
> blocks the session from ending without one, and checks the four required sections below.

## Completed
- What was built, concretely: modules, endpoints, commands
- Tests added: how many unit, how many integration

## Not completed
- What you did NOT finish, honestly, and why
- Paths that exist in code but were never exercised

## Commands run
| Command | Exit |
|---------|------|
| `<test command>` | 0 |
| `<live-run check>` | 0 |

## Issues discovered
- Problems found along the way, including ones outside this feature's scope
- Decisions you made that the document did not cover (also record them in `.memory/decisions/`)

## Assertions
n/n PASS

## Procedures followed
- [ ] Assertions existed before implementation
- [ ] Every assertion has a test naming its ID
- [ ] Failure paths implemented and tested
- [ ] No architectural boundary crossed
- [ ] Migration created and applied (if the schema changed)
- [ ] Full regression suite green
