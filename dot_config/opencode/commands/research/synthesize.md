---
description: Produce a cited decision report from verified research artifacts.
agent: research/lead
---

Synthesize the research artifacts in:

$ARGUMENTS

Use `research_workflow_check`, advance the saved run to `synthesizing` if valid,
and launch a fresh `research/synthesizer` child session. Then advance to
`auditing`, launch `research/auditor`, and complete only on `PASS`. Do not
synthesize in this session or treat uncertain or rejected claims as facts.
