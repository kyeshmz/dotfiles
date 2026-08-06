---
name: writing-pull-requests
description: Strict, structured rules for a pull request's title and body — diff-grounded content, size-gated sections, banned phrasing, no fabricated motivation or test results, no AI attribution, draft-first publish gate. Load before running `gh pr create` or editing an existing PR's description.
---

# Writing pull requests

This overrides the default PR-body convention (a bare `## Summary` + `## Test plan`, plus a `Co-Authored-By` trailer and a Claude Code link) whenever it is loaded. Follow the rules below instead of that default.

## The rule above the others

Never invent motivation, a metric, a test result, or a ticket number that isn't backed by something you actually observed. A fabricated detail is worse than an admitted gap. Where you don't have the fact, write `[NEEDS INPUT: <what's missing>]` or ask the user — do not paper over the gap with plausible-sounding prose.

## Ground everything in the diff

- Read the actual diff (`git diff <base>..HEAD`, or the PR's changed files) before writing anything. Treat any pre-existing title or description on the branch as untrusted, not as source material.
- Name real files, functions, and identifiers that appear in the diff. Never describe an "auth handler" when the diff shows `AuthService.verify()`.
- Describe only the diff against the target branch's HEAD — never intermediate commits, reverted attempts, or iteration history within the branch. If the branch touched something and then reverted it, that's invisible to the description.
- Use present tense: "adds," "removes," "changes" — never "added," "has been changed."

## Size-gated structure

Compute the diff size first (`git diff --stat <base>..HEAD`, lines changed, excluding lockfiles and generated files). The section list scales with it — do not use the large template on a 12-line fix, and do not shrink a genuinely large change down to a TL;DR.

**Small — under 50 lines changed**
```
<imperative title>

<1-2 sentence TL;DR>

<link to issue/ticket, if one exists>
```
No further sections unless something below is non-obvious from the diff alone.

**Medium — 50 to 200 lines**
```
<imperative title>

## Summary
<1-3 bullets, diff-grounded>

## Why
<the motivation — from the ticket, the conversation, or asked for. Never invented.>

## Test plan
<what you ran, with actual output — see Test plan discipline below>
```

**Large — over 200 lines, or more than ~5 files touched**
```
<imperative title>

## Summary
<bullets, ordered by importance, diff-grounded>

## Why
<motivation and the approach taken — and what alternate approach was rejected, if one was considered>

## Test plan
<as above>

## Risk
<what could break, what wasn't tested, what a reviewer should scrutinize>
```

A description longer than the diff it describes is a sign you're padding — cut it back toward the small/medium template.

## Title

Imperative mood, describes the actual change, no ticket-stub titles. Banned: "Fix bug," "Update code," "Various improvements," "WIP," or any title that would be equally true of a different PR.

## Test plan discipline

- A checked box (`- [x]`) means you ran that command and observed its output — paste the actual result ("`npm test` — 42 passed"), not "tests pass."
- An unchecked box (`- [ ]`) means it genuinely wasn't run. Say who needs to run it and why you couldn't (needs credentials, needs a second device, needs visual judgment) — never leave it unchecked with no explanation, and never check it just to make the section look complete.
- Reviewer requests ("please eyeball the layout on mobile") go in their own `## For reviewer` line, not disguised as an unchecked test.

## Banned phrasing

Delete on sight, don't rephrase-and-keep:
- Puffery: "robust," "comprehensive," "powerful," "seamless," "cutting-edge," "state-of-the-art"
- Hedging: "might," "could," "possibly," "in some cases," "generally"
- Filler openers: "This PR introduces...," "This PR adds...," "I have made the following changes"
- AI-tell phrases: "let's dive in," "it's worth noting that," "at the end of the day," "the key takeaway"
- Passive voice where an actor exists: "the bug was fixed" → "fixes the bug"
- Empty transitions stitching unrelated bullets together: "Additionally," "Furthermore," "Moreover"

## No AI attribution

- No `Co-Authored-By: Claude` trailer, no "Generated with Claude Code" footer, no link to a Claude session.
- No first-person assistant voice ("I refactored...," "I noticed that..."). Write as the author of the change, not as an assistant describing what it did.
- This applies to the PR body and commit trailer only — it does not change how you talk to the user in conversation.

## Publish gate

1. Draft the title and body against the rules above.
2. Re-read it once against **Banned phrasing** and **The rule above the others** — cut anything that fails either check before it exists anywhere else, including in a `gh pr create --body-file` temp file.
3. Open as a **draft PR** (`gh pr create --draft`) by default. Only create as non-draft, or mark an existing draft ready, on the user's explicit instruction.
4. If the repo has its own `.github/pull_request_template.md`, use its section names instead of the ones above, but keep every rule in this file — fill every section, using `N/A` rather than deleting one that doesn't apply.

## Companion CI gate

`pr-description-check.yml` in this skill's directory is a copyable GitHub Actions workflow that checks a PR body has the required headings for its diff's size tier and fails the check otherwise. It is a structural gate only — it does not and cannot check prose quality, so it complements this skill rather than replacing the rules above. It is not installed by `sync.sh`; copy it into a repo's `.github/workflows/` by hand when that repo wants the hard gate.
