# Decision: CLI / Env Policy

## Context

**What:** When `jekyll freeze-archives` runs, what enables CDX lookup, whether SavePageNow is available, and whether files are written by default (vs dry-run).

**Why it matters:** Build-time archive uses `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE` / `_SAVE`. The freeze command is deliberately *outside* that lifecycle; reusing those env vars blindly either surprises authors (“I ran the command but nothing happened”) or couples two different intents.

**Constraints:**
- Invocation itself is the opt-in
- Authors must be able to review before commit (dry-run must exist)
- Reuse `ArchiveHelper` for HTTP / eligibility
- Do not invent archive attributes on failed lookup
- Prefer consistency with existing SAVE semantics where possible

## Options Evaluated

- **A — Mirror build env**: Require `ARCHIVE=1` for CDX; `_SAVE=1` for SavePageNow; write by default
- **B — Invoke enables CDX; SAVE stays env-gated; write default + `--dry-run`**: Running the command performs CDX; SavePageNow only if `_SAVE=1` (optional `--save` alias setting the same); `--dry-run` reports without writing
- **C — Fully flag-driven**: `--write` / `--save` / no env; dry-run default until `--write`
- **D — CDX-only forever**: Never SavePageNow from freeze; always write; no dry-run

## Analysis

| Criterion | A Mirror env | B Invoke=CDX | C Flags-only | D CDX-only no dry-run |
|-----------|--------------|--------------|--------------|------------------------|
| Opt-in clarity | Low (env + cmd) | High | High | High |
| Consistency with ArchiveHelper | High | High (SAVE) | Needs wrapper | Partial |
| Safety before commit | OK if dry-run added | Good | Best (dry default) | Poor |
| Simplicity | Confusing dual gate | Good | Extra flags | Too sparse |

Key insights:
- Requiring `ARCHIVE=1` for a command whose sole job is archive lookup is a footgun — favors B or C.
- Dry-run-as-default (C) is safer but fights the user’s stated workflow (“run it, get source edits, commit”); `--dry-run` as opt-in safety valve is enough.
- SavePageNow mutating the remote archive is a stronger action than freezing an existing CDX hit — keep it behind the existing `_SAVE` gate (B).

## Decision

### Choice Pre-Mortem

- **Authors expect freeze to never hit the network without ARCHIVE=1**: unchecked as product preference — mitigated by docs stating that invoking the command performs CDX; still high confidence because “run the tool” is the opt-in they asked for
- **`--save` / `_SAVE` during freeze creates unwanted new snapshots**: checked — same gate as build; document clearly; default path is CDX-only
- **Write-by-default surprises**: checked — `--dry-run` required in docs/examples as first-run recommendation

**Selected**: Option B — Invocation enables CDX; SavePageNow remains `_SAVE=1` (optional `--save`); write by default with `--dry-run`  
**Rationale**: Matches “opt-in by running the tool,” keeps dangerous SAVE behavior on the existing lever, and still offers a no-write rehearsal.  
**Tradeoff**: Freeze and build env semantics differ for CDX (`ARCHIVE=1` not required for freeze); must document that difference.

## Implementation Notes

- Command name: `freeze-archives` (`jekyll freeze-archives`)
- Before lookup path used by freeze, ensure CDX runs without requiring `ARCHIVE=1` (e.g. call `archive_url_for` / `lookup_archive` from a freeze-specific path that does not go through `archive_enabled?` for the enable gate — eligibility still via `archiveable_url?`)
- `--dry-run`: print planned edits; no file writes
- `--save`: enable SavePageNow for this run (equivalent to `_SAVE=1` for the process)
- Report summary: frozen / skipped / lookup-miss counts
