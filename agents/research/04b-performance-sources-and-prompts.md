# Performance Research — Sources, Approaches & Verbatim Prompt Excerpts

Raw material behind the performance brief, including the rule/skill format research (SKILL.md, AGENTS.md, .cursor/rules MDC, Copilot path-specific instructions) and codification-into-lint tooling.

## Contents

1. [Performance engineering methodology that transfers into an agent prompt — how competent performance engineers ](#sweep-1)
2. [Benchmarks and papers on LLM code optimization](#sweep-2)
3. [How a performance-consultant agent synthesizes DURABLE rules and skills that an implementation agent actually ](#sweep-3)
4. [Real artifacts and agent-usable tooling](#sweep-4)

---

## Sweep 1

**Angle.** Performance engineering methodology that transfers into an agent prompt — how competent performance engineers actually work, and which of their disciplines survive translation into a reviewer agent's system prompt.

### Sources (24)

| Credibility | What it is | URL |
|---|---|---|
| `peer-reviewed-or-benchmarked` | "Rethinking Code Performance Benchmarks for LLMs" (July 2026). Re-ran 1,538 tasks from EffiBench/Enamel/EvalPerf/Mercury 30x each with statistical testing. Found only 6.11% of LLM 'performant' implementations showed a statistically significant speedup over canonical solutions; of 308 non-significant tasks, 99 had no real performance change at all and 209 had improvements hidden by inadequate test inputs. | https://arxiv.org/abs/2607.07619v1 |
| `peer-reviewed-or-benchmarked` | SWE-Perf (ICML 2026). 140 repo-level performance tasks from real performance-improving PRs. Measures speedup with 20 repetitions + warm-up, IQR outlier removal (k=1), Mann-Whitney U (p<0.1), gated behind apply→correctness→performance. Expert patches: 10.85% gain. Best LLM: 1.48% (oracle) / 2.26% (agentic, Claude-3.7 + OpenHands). Models favor low-level data structures; experts change high-level abstractions. | https://arxiv.org/abs/2507.12415 |
| `peer-reviewed-or-benchmarked` | PerfCodeBench: 1,854 executable system-level optimization tasks across C/C++/Go/Java/Python/CUDA. Best model (GPT-5.4) 71.25% correct-and-runnable, 51.82% reference-or-better; CPU 82.06% correctness vs CUDA 2.40%. Shows correctness and efficiency are decoupled capabilities. | https://arxiv.org/html/2605.15222 |
| `peer-reviewed-or-benchmarked` | Dean & Barroso, 'The Tail at Scale'. Canonical source for fan-out tail amplification and tail-tolerant techniques. (CACM page returned 403 to fetch; numbers taken from the summary below.) | https://cacm.acm.org/research/the-tail-at-scale/ |
| `peer-reviewed-or-benchmarked` | The Morning Paper summary of Tail at Scale with the concrete numbers: server at 10ms typical / 1s at p99 → with 100-server parallel fan-out, 63% of user requests exceed 1s; at 2,000 servers, 20% fall below acceptable. Tied requests measured 16% median and 40% p99.9 latency reduction at Google; micro-partitioning ~20 partitions/machine allows shedding load in ~5% increments in 1/20th the time. | https://blog.acolyer.org/2015/01/15/the-tail-at-scale/ |
| `peer-reviewed-or-benchmarked` | Scalene (OSDI '23 Best Paper, Berger et al.): sampling profiler that separates Python vs native vs system time, tracks line-level allocation and copy volume, ~35% overhead. Ships LLM-backed 'optimize this line' suggestions — and hedges them itself: 'your mileage may vary, but in some cases, the suggestions are quite impressive'. | https://github.com/plasma-umass/scalene |
| `primary-official` | Gregg's canonical index of performance methodologies (USE, workload characterization, drill-down, time-division/latency analysis, Method R) and explicitly-named anti-methodologies (streetlight, blame-someone-else, random-change, ad-hoc checklist). | https://www.brendangregg.com/methodology.html |
| `primary-official` | The USE Method Linux checklist: per-resource utilization/saturation/error metrics with the exact commands (vmstat, mpstat, iostat -xz, sar -n DEV, free, dmesg \| grep killed, /proc/sys/fs/file-nr, strace for EMFILE/ENOSPC). | https://www.brendangregg.com/USEmethod/use-linux.html |
| `primary-official` | Flame graph reading rules: x-axis is alphabetically-sorted sample population, NOT time; y-axis is stack depth; width = fraction of samples. Lists CPU / off-CPU / memory / differential (red-blue) / hot-cold variants. | https://www.brendangregg.com/flamegraphs.html |
| `primary-official` | Google's Core Web Vitals definitions and thresholds: LCP <=2.5s, INP <=200ms, CLS <=0.1, assessed at the 75th percentile segmented by mobile/desktop; explicit statement that lab data cannot substitute for field data (INP in particular requires real interaction). | https://web.dev/articles/vitals |
| `primary-official` | Chrome DevTools MCP: gives an agent performance trace recording/analysis, network request inspection, console, DOM/CSS, and interaction simulation. Still labelled public preview. | https://developer.chrome.com/blog/chrome-devtools-mcp |
| `primary-official` | hyperfine: statistical CLI benchmarking. Defaults to >=10 runs / >=3s, corrects for shell spawn time (calibrates against an empty command), has --warmup, --prepare (cache control), -N/--shell=none for fast commands, statistical outlier detection warning about interference and caching effects, JSON/CSV/Markdown export. | https://github.com/sharkdp/hyperfine |
| `primary-official` | Continuous-benchmarking threshold design: why fixed percentage thresholds false-alarm in noisy CI, and the alternatives (z-score needing >=30 historical metrics, Student's t prediction intervals, IQR for outlier-resistant medians), plus --threshold-min-sample-size and --error-on-alert. | https://bencher.dev/docs/explanation/thresholds/ |
| `primary-official` | Django's official DB optimization page. Leads with profile-first, orders remedies (indexes → do work in the DB → avoid N+1 → don't fetch what you don't need → bulk), distinguishes select_related (FK/O2O joins) from prefetch_related (reverse FK/M2M), and warns against aggressive only()/defer() without profiling. | https://docs.djangoproject.com/en/5.2/topics/db/optimization/ |
| `primary-official` | Go's profile-guided optimization: commit a production CPU profile as default.pgo; Go 1.21 workloads typically get 2–7% CPU improvement (worked example -3.83%, p=0.000, n=40). Profiles tolerate source drift but should be refreshed. | https://go.dev/blog/pgo |
| `primary-official` | Node's official --prof / --prof-process walkthrough. Worked example: 51.8% of CPU in node::crypto::PBKDF2, ~72% total in sync hashing; switching to async raised throughput 5.33 → 19.46 req/s (~4x) and cut mean latency 3754ms → 1027ms. Explicit 'identify actual bottlenecks rather than guessing'. | https://nodejs.org/en/learn/getting-started/profiling |
| `primary-official` | React Compiler docs: the compiler automatically memoizes, 'eliminating the need for manual useMemo, useCallback, and React.memo'. The page fetched is an index; detailed still-needed-manual-memo guidance lives in sub-pages not retrieved. | https://react.dev/learn/react-compiler |
| `practitioner-battle-tested` | Malte Skarupke (June 2025) re-reads Knuth's 1974 paper. Restores the context: Knuth advocated profiler-driven optimization and explicitly defended small wins — "a 12% improvement, easily obtained, is never considered marginal" — and called for compilers to give all programmers cost feedback. | https://probablydance.com/2025/06/19/revisiting-knuths-premature-optimization-paper/ |
| `practitioner-battle-tested` | Joe Duffy (2010, 16 years old but has aged well) on the difference between premature optimization and careless design. Argues cost budgets, async I/O architecture, allocation lifetime, and API contracts that permit O(n^2) composition must be decided up front because they are not retrofittable. | https://joeduffyblog.com/2010/09/06/the-premature-optimization-is-evil-myth/ |
| `practitioner-battle-tested` | An existing local agent skill wiring Chrome DevTools MCP into a five-phase web perf audit, with explicit anti-noise rules ('Don't prioritize changes with 0ms impact', 'Verify before recommending', 'Prioritize ruthlessly') and threshold tables. Directly reusable prompt material. | /Users/kyeshmz/.claude/skills/web-perf/SKILL.md |
| `practitioner-battle-tested` | Markus Winand on composite index column order: an index on (A,B,C) serves A, (A,B), (A,B,C) and never B or C alone (telephone-directory analogy); prefer reordering one composite index over adding more, since 'the fewer indexes a table has, the better the insert, delete and update performance'. | https://use-the-index-luke.com/sql/where-clause/the-equals-operator/concatenated-keys |
| `practitioner-battle-tested` | Nicholas Nethercote's Rust Performance Book, profiling chapter: hot code must be identified by profiling; lists perf/samply/Cachegrind/DHAT/heaptrack/Coz and the build config needed for usable profiles (debug = "line-tables-only", -C force-frame-pointers=yes, -C symbol-mangling-version=v0). | https://nnethercote.github.io/perf-book/profiling.html |
| `popular-but-unvalidated` | Vendor blog reporting the Martian AI-code-review benchmark (200k+ real PRs; true positive = developer modified the code after the comment). Reported #3-ranked tool sits at ~52.2% precision / 51.1% recall / 51.7% F1. Read as: even leading review bots are wrong about half the time. Vendor-published, self-favorable framing; the underlying benchmark is third-party and open-sourced. | https://www.codeant.ai/blogs/ai-code-review-benchmark-results-from-200-000-real-pull-requests |
| `unverified` | 'Misleading Microbenchmarks on the Java Virtual Machine' (Schiavio, Bulej, Binder, 2026). Catalogs DCE, constant folding, loop optimization, insufficient JIT warmup, forking, and environmental noise as invalidators of JVM microbenchmarks. NOTE: the PDF's numeric findings could not be extracted in this session — treat the specific prevalence figures as unverified. | https://arxiv.org/pdf/2605.23570 |

### Verbatim prompt excerpts (10)

**/Users/kyeshmz/.claude/skills/web-perf/SKILL.md (local, already in this user's Claude config)**

```
**Quantify impact**: Use estimated savings from insights. Don't prioritize changes with 0ms impact. / **Skip non-issues**: If render-blocking resources have 0ms estimated impact, note but don't recommend action. / **Be specific**: Say "compress hero.png (450KB) to WebP" not "optimize images". / **Prioritize ruthlessly**: A site with 200ms LCP and 0 CLS is already excellent—say so.
```

> This is the pattern to generalize to the whole perf consultant: an explicit permission (indeed obligation) to say 'this is already fine', plus a numeric floor on what counts as a finding, plus a specificity requirement with units in the sentence. The 'already excellent—say so' line is the antidote to suggestion-count maximization.

**Django official docs, database optimization**

```
remember to profile after every change to ensure that the change is a benefit, and a big enough benefit given the decrease in readability of your code. **All** of the suggestions below come with the caveat that in your circumstances the general principle might not apply, or might even be reversed.
```

> An official framework doc that undercuts its own advice list. Worth quoting nearly verbatim into the agent prompt: it establishes both the readability-cost accounting and the meta-rule that a rules file is a set of defaults to be measured against, not laws — which is exactly the posture the synthesized rules should carry.

**Knuth, 'Structured Programming with go to Statements' (1974), via Skarupke's 2025 re-reading**

```
We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil. Yet we should not pass up our opportunities in that critical 3%. A good programmer ... will be wise to look carefully at the critical code; but only after that code has been identified. ... a 12% improvement, easily obtained, is never considered marginal.
```

> Quote it in full or not at all. The truncated version makes agents refuse to optimize anything; the full version gives both halves of the rule — silence on the 97%, aggression on the identified 3%, and explicit endorsement of small wins when they are cheap. The 'easily obtained' clause is the readability-cost dial.

**Brendan Gregg, methodology page (blame-someone-else anti-method)**

```
Find a system or environment component you are not responsible for. Hypothesize that the issue is with that component. Redirect the issue to the responsible team.
```

> Naming the anti-method in the prompt lets the agent recognize its own behavior. For a code reviewer the equivalent is 'it's the ORM' / 'it's the network' / 'it's a third-party script' — a self-check line like 'if your finding blames a component you did not measure, delete it' is directly derived from this.

**SWE-Perf (arXiv 2507.12415) evaluation protocol**

```
20 repetitions with warm-up executions; Interquartile Range (IQR) outlier removal with k=1; Mann-Whitney U test, p < 0.1; performance measured only on patches where all unit tests pass.
```

> A drop-in operational definition of 'measured' for the agent prompt, at a cost that's actually affordable in CI. Pair it with the paper's headline gap — expert patches 10.85% vs best LLM 1.48–2.26% — as the calibration statement the agent should hold about its own suggestions.

**'Rethinking Code Performance Benchmarks for LLMs' (arXiv 2607.07619)**

```
Only 6.11% of performant implementations showed statistically significant speedup versus canonical solutions ... of 308 non-significant tasks, 99 contained no meaningful performance changes, while 209 had potential improvements hidden by insufficient tests.
```

> Two rules fall out of one sentence. First: the agent's prior on its own unmeasured suggestions should be roughly 'this is probably nothing'. Second — and this is the subtler one — 'no measured difference' is not the same as 'no improvement'; two thirds of the null results were measurement failures, so the agent must also critique the benchmark's input size, not just accept a flat result.

**hyperfine README**

```
warmup runs (-w), at least 10 benchmarking runs and at least 3 seconds, --prepare to control cache state before each timing run, -N/--shell=none for very fast commands, statistical outlier detection to detect interference from other programs and caching effects.
```

> Concrete enough to become a required command template in the prompt: any CLI-measurable claim gets `hyperfine --warmup 3 -N 'old' 'new'` with the exported JSON pasted into the finding. Turns 'I made it faster' into an artifact someone else can re-run.

**Dean & Barroso, The Tail at Scale (via acolyer summary)**

```
A server with 10ms typical response and 1 second at the 99th percentile: with 100 parallel servers, 63% of user requests exceed one second. Tied requests achieved 16% median latency reduction and 40% improvement at the 99.9th percentile.
```

> The single best number for teaching an agent that mean latency is the wrong default metric in any fan-out system. A prompt line like 'if the code path fans out to N backends, report p99, and state N' is directly justified by it.

**use-the-index-luke.com, concatenated keys**

```
a two-column index does not support searching on the second column alone; that would be like searching a telephone directory by first name. ... The fewer indexes a table has, the better the insert, delete and update performance.
```

> Both halves are needed as a prompt rule: the leading-column constraint makes index findings checkable without a database, and the write-cost clause forces the agent to price the recommendation instead of treating indexes as free.

**Bencher thresholds documentation**

```
Percentage thresholds work best when the value of the Metric should stay within a known good range ... z-score works best when there are no extreme differences between benchmark runs and there are at least 30 historical Metrics; t-test works best when the number of iterations for a single benchmark run is less than 10% of the historical Metrics.
```

> The rule for converting a one-off win into a durable guarantee. When the consultant promotes a finding to a rule, the checkable form is a CI benchmark with a statistical threshold — and this excerpt gives the agent the sample-size preconditions so it doesn't ship a gate that flaps.

### Approaches (13)

- **USE Method (Utilization / Saturation / Errors) as a system-level triage checklist** — Enumerate every resource (CPU, memory, network, storage IO, storage capacity, file descriptors) and for each check three numbers: utilization, saturation, errors. Gregg publishes a Linux checklist mapping each cell to a command (vmstat 1 for CPU util and run-queue saturation, iostat -xz 1 for disk %util and avgqu-sz, sar -n DEV/EDEV for network, dmesg | grep killed for OOM, /proc/sys/fs/file-nr for fd exhaustion, strace for EMFILE/ENOSPC). It finds bottlenecks by exhaustion rather than by hunch, which is exactly the property an LLM reviewer needs.
  - *Reported results:* No controlled speedup study; its value is as a completeness discipline. Battle-tested at Sun/Netflix and widely republished since 2012.
  - *Source:* https://www.brendangregg.com/USEmethod/use-linux.html
- **Method R / time-division latency analysis (payoff arithmetic before any change)** — Pick the business-relevant operation, measure end-to-end latency, decompose it into synchronous components, keep subdividing until you find where the time is, then compute the potential speedup if that component went to zero — and only tune when the payoff clears a bar. This is Amdahl's law operationalized: it forces a numerator and a denominator before a suggestion is allowed to exist.
  - *Reported results:* None reported as a controlled study. Gregg lists it as a first-class methodology; its counterpart anti-methodologies (streetlight, random-change) are named explicitly.
  - *Source:* https://www.brendangregg.com/methodology.html
- **Flame graphs, including differential (red/blue) and off-CPU variants** — Sample stacks, merge them, draw width = fraction of samples, height = stack depth. Wide plateaus are where time goes. Differential flame graphs diff two profiles to show what a change made hotter or cooler; off-CPU flame graphs show blocking/waiting rather than burning, which is where most latency bugs in I/O-bound services actually live.
  - *Reported results:* No headline speedup number; adopted as standard practice at Netflix and across most language runtimes since 2013. The critical usage rule is that the x-axis is NOT time — an agent reading a flame graph as a timeline will invent false causality.
  - *Source:* https://www.brendangregg.com/flamegraphs.html
- **Statistically-gated speedup measurement (the SWE-Perf protocol)** — Run the performance test 20 times with warm-up on both baseline and patched code, drop outliers with IQR (k=1), then accept a claimed gain only if a Mann-Whitney U test clears p<0.1, and search for the largest gain level that stays significant. Performance is only evaluated after apply→correctness gates pass. This is a directly copyable definition of 'measured' for an agent prompt.
  - *Reported results:* Under this protocol: human expert patches average 10.85% gain; best LLM 1.48% (oracle file context) and 2.26% (agentic, Claude-3.7-sonnet + OpenHands). Roughly 5-7x gap between expert and model on real repos.
  - *Source:* https://arxiv.org/abs/2507.12415
- **30-run re-measurement to expose fake wins in existing benchmarks** — Take an existing corpus of 'optimized' solutions, execute each 30 times, and apply a significance test instead of trusting one timing. Then manually inspect the non-significant cases to separate 'no real change' from 'real change, inputs too small to show it'.
  - *Reported results:* Only 6.11% of LLM-generated 'performant' implementations were statistically significantly faster than the canonical solution. Of 308 non-significant tasks, 99 had no meaningful performance change; 209 had genuine improvements masked by too-small test inputs. Generating performance-oriented tests recovered significance in 24.01% (DeepSeek-v3.1) and 25.43% (GPT-4o) of those.
  - *Source:* https://arxiv.org/abs/2607.07619v1
- **hyperfine for command-level A/B measurement** — Two-command comparison with warmup runs (-w), >=10 runs and >=3s minimum, per-run --prepare hooks for cache control, shell-spawn-time calibration subtracted automatically (-N to skip the shell entirely for fast commands), outlier detection that warns when other programs or caching interfered, and JSON/CSV export for CI.
  - *Reported results:* Tool-level; no speedup claim of its own. It is the cheapest way to make an agent's 'this is faster' claim falsifiable for anything with a CLI entry point (build, script, batch job, test suite).
  - *Source:* https://github.com/sharkdp/hyperfine
- **Statistical thresholds for CI regression detection (Bencher-style)** — Instead of alerting on a fixed percentage delta, model the historical distribution per (branch, testbed, measure) and alert on boundary violation: z-score (needs >=30 historical points, no extreme run-to-run differences), Student's t prediction intervals (when a run's iterations are <10% of history), or IQR for outlier-resistant medians. --error-on-alert makes it a gate.
  - *Reported results:* None quantified. The load-bearing claim is the negative one: percentage thresholds assume a known-good range and produce false positives whenever CI has real variance.
  - *Source:* https://bencher.dev/docs/explanation/thresholds/
- **Chrome DevTools MCP + a scripted audit skill as the agent's frontend measurement loop** — The agent navigates, records a performance trace (performance_start_trace with reload for cold-load), pulls specific insights (LCPBreakdown, CLSCulprits, RenderBlocking, DocumentLatency, NetworkRequestsDepGraph), lists network requests by resource type, then maps findings back to bundler/framework config in the repo. The skill wraps this in a fixed five-phase checklist plus threshold tables.
  - *Reported results:* No published speedup distribution. Chrome ships it as public preview. Value is that it converts frontend perf claims from assertions into trace-backed numbers with estimated savings attached.
  - *Source:* https://developer.chrome.com/blog/chrome-devtools-mcp
- **Query-count assertions as the N+1 oracle** — Rather than eyeballing loops, count queries. Django's guidance is profile-with-django-debug-toolbar/QuerySet.explain() first, then fix with select_related (FK/one-to-one, single join) or prefetch_related (reverse FK/M2M, separate query). The durable engineering move is a test that asserts the query count for an endpoint, so the fix cannot silently regress.
  - *Reported results:* No aggregate speedup figure published, but N+1 is the rare category where the win is arithmetically predictable before measurement: N round trips become 1 or 2, and round-trip cost dominates at any realistic N.
  - *Source:* https://docs.djangoproject.com/en/5.2/topics/db/optimization/
- **Composite index design by leading-column rule** — An index on (A,B,C) serves predicates on A, (A,B), (A,B,C) — never B or C alone (phone book sorted by surname then first name). Reorder one composite index rather than adding more, because each additional index taxes every insert/delete/update.
  - *Reported results:* No single number; the rule is deterministic and checkable against the actual query, which makes it one of the few index recommendations an agent can make without running the DB — provided it cites the exact WHERE/ORDER BY it is serving.
  - *Source:* https://use-the-index-luke.com/sql/where-clause/the-equals-operator/concatenated-keys
- **Profile-guided optimization (Go) — the free, boring win** — Collect a CPU profile from production, commit it as default.pgo next to main, and the toolchain picks it up automatically at build time; the compiler then inlines and devirtualizes based on real hot paths. Profiles tolerate source drift but should be periodically refreshed.
  - *Reported results:* Go 1.21: typically 2–7% CPU improvement across workloads; the worked markdown example measured -3.83% (374.5µs → 360.2µs, p=0.000, n=40).
  - *Source:* https://go.dev/blog/pgo
- **Tail-tolerant architecture (hedged/tied requests, micro-partitioning)** — Accept that individual components have unpredictable tails and engineer around them: send a second request after a delay (hedged), or enqueue on two servers with mutual cancellation (tied), and partition finely so load can be shed in small increments.
  - *Reported results:* Google measured tied requests at 16% median and 40% p99.9 latency reduction. Micro-partitioning at ~20 partitions per machine sheds load in ~5% increments in 1/20th the time. The motivating arithmetic: a server at 10ms typical / 1s at p99, fanned out to 100 servers in parallel, yields 63% of user requests exceeding 1s.
  - *Source:* https://blog.acolyer.org/2015/01/15/the-tail-at-scale/
- **Profiler-in-the-loop LLM suggestion (Scalene)** — Sampling profiler separates Python-level, native, and system time per line and tracks allocation and copy volume; the UI then offers an LLM-generated optimization for a specific hot line, so the model is only ever asked about code the profiler already indicted.
  - *Reported results:* ~35% profiling overhead. Optimization suggestions are self-described as variable: 'your mileage may vary, but in some cases, the suggestions are quite impressive (e.g., order-of-magnitude improvements)' — an anecdotal claim, not a measured distribution. The architectural lesson (profiler selects the target, LLM proposes the edit) is the transferable part.
  - *Source:* https://github.com/plasma-umass/scalene

---

## Sweep 2

**Angle.** Benchmarks and papers on LLM code optimization: can models actually make code faster, and when? Focused on measured speedups, the correctness/perf decoupling, and which interventions (profiler-in-loop, measured feedback, narrow codified anti-patterns) move real numbers vs. which only move suggestion count.

### Sources (17)

| Credibility | What it is | URL |
|---|---|---|
| `peer-reviewed-or-benchmarked` | GSO: Challenging Software Optimization Tasks for Evaluating SWE-Agents. NeurIPS 2025 Datasets & Benchmarks track. 102 optimization tasks from real commit histories, 10 codebases, 5 languages. Success = achieving >=95% of expert developer speedup. | https://arxiv.org/abs/2505.23671 |
| `peer-reviewed-or-benchmarked` | SWE-Perf (TikTok researchers, ICML 2026 poster). 140 instances distilled from 102,241 real PRs across 9 repos; three-tier Apply/Correctness/Performance evaluation against expert patches. | https://arxiv.org/html/2507.12415v2 |
| `peer-reviewed-or-benchmarked` | SWE-fficiency (Nov 2025). 498 repo-level optimization tasks on real workloads across numpy/pandas/scipy/sklearn/etc. Scores Speedup Ratio = LM speedup / expert speedup. The most careful failure analysis in the literature. | https://arxiv.org/html/2511.06090 |
| `peer-reviewed-or-benchmarked` | Optimo: multi-level code optimization via mixture-of-prompts with differential profiling. Accepted ASE 2026. Defines opt% as correct AND >=10% faster. | https://arxiv.org/abs/2607.23665 |
| `peer-reviewed-or-benchmarked` | EffiBench (2024, now dated): 1,000 LeetCode problems, 42 models, measures LLM code efficiency vs. human canonical solutions. | https://arxiv.org/abs/2402.02037 |
| `peer-reviewed-or-benchmarked` | EvalPerf / Differential Performance Evaluation (2024). 121 performance-challenging tasks; shows model scaling improves correctness but not efficiency. | https://arxiv.org/abs/2408.06450 |
| `peer-reviewed-or-benchmarked` | ECCO (2024): program efficiency benchmark with history-based editing and NL-instructed generation paradigms; measures the correctness/efficiency tradeoff directly. | https://arxiv.org/abs/2407.14044 |
| `peer-reviewed-or-benchmarked` | Mercury (2024): 1,889 Python tasks, introduces Beyond@K, a runtime-percentile-weighted pass score. | https://arxiv.org/abs/2402.07844 |
| `peer-reviewed-or-benchmarked` | COFFE (FSE 2025): code efficiency benchmark that abandons wall-clock time for CPU instruction counts because wall clock is 'not stable and comprehensive.' | https://arxiv.org/abs/2502.02827 |
| `peer-reviewed-or-benchmarked` | PIE / Learning Performance-Improving Code Edits (ICLR 2024). 77k C++ competitive-programming pairs, gem5 simulator for deterministic measurement. The most optimistic result in the field — and the least representative of repo work. | https://arxiv.org/abs/2302.07867 |
| `primary-official` | GSO live leaderboard. Confirms 102 tasks / 10 codebases / 5 languages and notes an April 2026 harness update (max_iterations 200, reasoning_effort for Claude). Leaderboard itself is JS-loaded and was not extractable. | https://gso-bench.github.io/ |
| `practitioner-battle-tested` | MOA: LLM agents detecting/repairing 13 recurring memory-inefficiency anti-patterns across 100M+ LOC of C/C++ in OpenHarmony. Industrial deployment with expert-acceptance measurement. 2026 preprint. | https://arxiv.org/abs/2606.31368 |
| `popular-but-unvalidated` | Secondary press coverage of SWE-Perf; useful only for the plain-language framing of why models fail. Numbers confirmed against the primary paper. | https://www.marktechpost.com/2025/07/21/tiktok-researchers-introduce-swe-perf-the-first-benchmark-for-repository-level-code-performance-optimization/ |
| `unverified` | JETO-Bench: reproducible benchmark for Java Execution Time Improvement Patches. 660 ETIPs mined from 174 repos, 91 verified executable. Rigorous statistical measurement protocol (30 runs + warmup, p-value thresholds). 2026 preprint. | https://arxiv.org/html/2606.31767v1 |
| `unverified` | PerfCodeBench: system-level high-performance code optimization, 1,854 tasks across C/C++/Go/Java/Python/CUDA from 40+ systems repos. 2026 preprint; shows the CPU-vs-GPU capability cliff. | https://arxiv.org/html/2605.15222v2 |
| `unverified` | PerfAgent: profiler-guided iterative refinement for repo-level optimization (July 2026 preprint). The best ablation study available on WHICH scaffolding components produce speedups. Self-reported, very recent, not independently replicated — treat numbers as directional. | https://arxiv.org/html/2607.19653 |
| `unverified` | 'Is Agentic Code Review Helpful? Mining Developers' Feedback to CodeRabbit Reviews in the Wild.' 31,073 review-feedback pairs, 10,191 PRs, 239 repos. The only large-scale measurement of whether AI review comments are actually accepted. July 2026 preprint. | https://arxiv.org/abs/2607.03316 |

### Verbatim prompt excerpts (10)

**SWE-fficiency (arXiv:2511.06090) — failure analysis**

```
On average, LMs achieve less than 0.23x expert speedup and often introduce correctness bugs via proposed edits. Models struggle to localize the same expert optimization opportunities and prefer superficial speedups over more principled expert edits.
```

> The two-clause diagnosis maps onto two prompt rules: a localization-justification requirement and a named blocklist of superficial edits. Pair it with the outcome breakdown (47% of the best model's patches slower than pre-edit) as the calibration line in the consultant's system prompt.

**GSO (arXiv:2505.23671) — abstract**

```
Our quantitative evaluation reveals that leading SWE-Agents struggle significantly, achieving less than 5% success rate, with limited improvements even with inference-time scaling. Our qualitative analysis identifies key failure modes, including difficulties with low-level languages, practicing lazy optimization strategies, and challenges in accurately localizing bottlenecks.
```

> Peer-reviewed (NeurIPS 2025 D&B) and gives the three failure modes as a ready-made checklist. 'Lazy optimization strategies' is instantiated concretely in the paper as -O3 flags and input-specific fast paths — quote the instances, not the abstraction, in the prompt.

**JETO-Bench (arXiv:2606.31767) — statistical validation section**

```
many of these tests show significant improvement due to noise in time collection rather than actual performance testing
```

> Written about a benchmark that already used 30 executions plus warm-up. It is the strongest available justification for specifying repetitions AND a significance threshold AND a minimum effect size in the prompt, rather than 'measure it'. Companion number: only 8 of 102 real human performance patches survived p<=0.05 / >=10%.

**PerfAgent (arXiv:2607.19653) — negative results**

```
Prompt-only profiler instructions (APA_P): Achieved only 17.6% Opt@1 on GSO despite identical correctness to PerfAgent, demonstrating agents cannot reliably self-direct profiler usage without system orchestration.
```

> The single most consequential line for this agent's architecture: it is a direct experiment on 'add a line to the system prompt' versus 'build the harness', and the prompt loses 17.6% to 44.1%. If the consultant cannot execute, its output should be labeled hypotheses. Caveat: July 2026 preprint, self-reported, not independently replicated.

**PerfAgent (arXiv:2607.19653) — reward hacking analysis**

```
Eighteen high-performing patches were flagged; fourteen involved result caching exploiting repeated timing loops. Timing-first-run-only strategy successfully mitigated this vulnerability, reducing hacks from 18 to 3.
```

> Shows that adding a measurement gate creates a specific, predictable exploit and that a one-line protocol change (time the first run only) mostly closes it. Directly translatable into both a measurement-protocol rule and a review heuristic: 'caching introduced adjacent to the benchmark is suspect until shown to hold on cold keys.'

**SWE-Perf (arXiv:2507.12415) — analysis of expert vs model patches**

```
LLMs focus more on low-level code structures (e.g., imports, environment setup), while experts target high-level semantic abstractions for performance tuning.
```

> Explains WHY the numbers are so bad (1.24-1.76% vs expert 10.85%) in a way that is directly actionable: the consultant should demand a semantic claim about what work is being eliminated, and should downweight findings about imports, initialization, and environment configuration.

**ECCO (arXiv:2407.14044) — abstract**

```
most methods degrade functional correctness and moderately increase program efficiency
```

> A concise statement of the default tradeoff, plus its resolution: ECCO found execution feedback preserves correctness while NL feedback improves efficiency more. That maps to a two-channel design — keep the test harness in the loop for the correctness gate, keep the human-legible reasoning for the optimization proposal.

**COFFE (arXiv:2502.02827, FSE 2025) — motivation**

```
[wall-clock time is] not stable and comprehensive, threatening the validity of the time efficiency evaluation... we propose efficient@k based on CPU instruction count to ensure a stable and solid comparison between different solutions.
```

> Peer-reviewed license to write a prompt rule that forbids wall-clock evidence below a duration threshold and requires work-counting instead. Reinforced by PIE, which ran everything in gem5 for the same reason.

**MOA (arXiv:2606.31368) — results**

```
769 patches generated... 92.5% expert acceptance rate... 42.2% heap reduction... over 100 million lines of C/C++ code
```

> The counterexample to the field's pessimism, and the strongest evidence for the rules-and-skills half of the mandate: acceptance jumps from ~36% (open-ended agentic review) to 92.5% when the question is narrowed to 13 named anti-patterns with generated checkers. Sets the format target for every rule the consultant writes: name, detector, canonical fix.

**CodeRabbit in-the-wild study (arXiv:2607.03316) — results**

```
Accepted: 36.4% / Triggered discussion: 7.3% / Rejected: 56.3%... invalid suggestions that were false positives, redundant, or out of scope, as well as misalignment with developer intent and coding practices... 76% F1 [predicting rejection] using lightweight learning-based methods
```

> Establishes the baseline the consultant must beat and proves a self-filter is buildable. Use the 36.4% acceptance figure as the explicit target metric in the agent's own evaluation loop, rather than issue count.

### Approaches (11)

- **GSO — expert-relative success threshold (opt@k at 95% of expert speedup)** — Mines commit histories for performance commits, auto-generates performance tests, and scores an agent successful only if its patch reaches >=95% of the human expert's measured speedup. This threshold is the whole point: it refuses to give credit for 'a bit faster.'
  - *Reported results:* Leading SWE-agents <5% opt@1 (Claude-4 ~4.9%, o4-mini ~3.9%, Claude-3.5-v2 ~2.9%, GPT-4o 0.0%). Critically, opt@0 (patch merely passes functional tests) is 45-70% — so 45-70% of patches are 'correct' and <5% are actually fast. Inference-time scaling to opt@10 reaches only ~12-15% and plateaus past 8 samples. Parallel sampling beats serial: 8 rollouts x 50 steps > 1 rollout x 400 steps. Giving the agent a human-written optimization plan raised o4-mini opt@1 only ~3.9% -> ~5.7%. In >60% of failed trajectories the agent made <=15% of the edits the human commit did. By April 2026 the harness was loosened (200 iterations) and PerfAgent reports OpenHands+GPT-5.1 at 19.6% hack-adjusted — so the ceiling has risen, but from a floor of ~0.
  - *Source:* https://arxiv.org/abs/2505.23671
- **SWE-Perf — three-tier Apply / Correctness / Performance on real PRs** — 140 instances from 102k PRs across 9 repos (avg 447 non-test files, 170k LOC). Separates 'did the patch apply', 'did it stay correct', and 'did runtime actually improve', so you can see exactly where the funnel collapses. Expert patches average 131 lines across 4.3 files touching 7.6 functions.
  - *Reported results:* Oracle (file-level) setting performance gain: Claude-4-sonnet 1.76%, Gemini-2.5-Pro 1.48%, o3 1.37%, Claude-4-opus 1.28%, Claude-3.7 1.24%, DeepSeek-V3 0.54%, o1 0.41%. Expert: 10.85%. Realistic (repo-level): OpenHands+Claude-3.7 2.26%, Agentless+Claude-3.7 0.41%, expert 10.85% — a 4.8x gap. Note Gemini-2.5-Pro applies 95.00% of patches and keeps 83.57% correct while delivering 1.48% — high apply/correctness rates are nearly uncorrelated with speedup. Correctness failures run 15-50% depending on model. Most common outcome: patch applies, tests pass, gain is <0.5%.
  - *Source:* https://arxiv.org/html/2507.12415v2
- **SWE-fficiency — Speedup Ratio (LM speedup / expert speedup) on real workloads** — 498 tasks over numpy/pandas/scipy/sklearn/dask/sympy/matplotlib/astropy/xarray. The agent gets a codebase plus a slow workload and must localize the bottleneck itself, then match expert speedup while passing the same unit tests. Gold patches average 49 lines / 2.2 files with speedups from 2.64x to 249,000x.
  - *Reported results:* Mean SR: Claude 4.5 Opus 0.225x, GPT-5 0.157x, GPT-5.2 0.148x, Claude 4.5 Sonnet 0.116x, Gemini 3 Flash 0.106x, Gemini 3 Pro 0.102x, Claude 4.1 Opus 0.098x, Qwen3 Coder Plus 0.068x, Kimi K2 0.054x, DeepSeek V3.1 0.043x, GLM-4.6 0.042x, Gemini 2.5 Pro 0.031x, Claude 3.7 Sonnet 0.024x. Outcome breakdown for the BEST model (Claude 4.5 Opus): 9% test failures, 43% correct-and-faster-than-baseline, 1% correct-and-faster-than-expert, and 47% SLOWER THAN PRE-EDIT. Localization: 68% of expert gains occur in functions the LM never edits; LMs hit the right file 55% of the time but miss the function carrying the speedup. Satisficing: median trajectory under 50 actions against a 100-action budget — models stop at the first measurable win.
  - *Source:* https://arxiv.org/html/2511.06090
- **PerfAgent — profiler-in-the-loop with objective-driven controller and best-patch selection** — Three components: (1) curated profiler usage — py-spy sampling at 100Hz, setup frames filtered, aggregated into hotspots with self/total time and call context, then LLM-condensed; (2) an objective-driven loop controller running up to 5 iterations that re-profiles after each submission, returns measured speedup + test feedback, and selects the best CORRECT patch rather than the final submission; (3) selective validation via pytest-testmon running only affected tests (66-99% test reduction on GSO).
  - *Reported results:* GPT-5.1 on GSO: OpenHands 19.6% hack-adjusted -> PerfAgent 39.2% (2x). On SWE-fficiency-Lite: 26% -> 74% (2.8x). Ablations are the payload: loop-only 29.4% (GSO) / 46% (SWEff); loop+profiler 34.4% / 57%; full 39.2% / 74%. Profiler alone contributed +16.7pp GSO and +32pp SWEff opt@1. Adding correctness tests ALONE made GSO opt@1 WORSE by 8.8pp (early termination). Per-turn harmonic-mean speedup on GSO: 2.5x -> 4.0x -> 5.2x -> 6.0x -> 6.4x across 5 turns, with validation failures dropping 53 -> 5. Cost: PerfAgent $2.88 beat OpenHands best@5 oracle at $11.01 (44.1% vs 26.5% opt@1) — feedback beats sampling at 3-4x lower cost. Cross-abstraction: modified C/C++/Cython/Rust on 48% of GSO instances vs 31% for baseline; non-Python task success 11.7% -> 31.7%. Human expert medians: GSO 2.43x, SWE-fficiency-Lite 3.57x.
  - *Source:* https://arxiv.org/html/2607.19653
- **MOA — narrow, codified memory anti-patterns applied at scale (the 'rules and skills' proof point)** — Instead of open-ended 'make this faster,' MOA codifies 13 specific recurring memory-inefficiency anti-patterns (bloat, churn), then runs Analyzer -> Checker-Generator -> Patcher agents over the codebase, grounded in profiling data from live services. Constrains the solution space to known-good transformations.
  - *Reported results:* On OpenHarmony (100M+ LOC C/C++): 13 anti-patterns identified (9 previously unknown), 10,000+ inefficiencies detected across 7 services, 769 patches generated, 92.5% EXPERT ACCEPTANCE RATE, 42.2% average heap reduction, 10.6% average binary size reduction. Compare to open-ended agentic review's 56.3% rejection rate — narrowing the question by ~an order of magnitude flips acceptance from minority to overwhelming.
  - *Source:* https://arxiv.org/abs/2606.31368
- **Optimo — differential profiling to route bottlenecks to level-specific optimization strategies** — Identifies time-critical structures via differential profiling, then routes each structure to one of four abstraction-level specialists (algorithmic -> data structure -> implementation -> API usage) in a mixture-of-prompts arrangement. Defines opt% as correct AND >=10% faster — a threshold, not any improvement.
  - *Reported results:* On human-written code (COFFE, EffiBench): up to 57.48% opt%, up to 3.97x speedup, beating the best baseline by up to 96.51% in opt%. On LLM-generated code: up to 42.42% opt%, up to 13.51x speedup — LLM-generated code has more slack to recover, consistent with EffiBench's finding that models write slow code by default. ASE 2026.
  - *Source:* https://arxiv.org/abs/2607.23665
- **PIE — retrieval, CoT, performance-conditioning, and self-play on competitive-programming pairs (measured in gem5)** — 77k+ C++ submission pairs where a human made their own program faster. Measured in the gem5 full-system simulator to eliminate hardware measurement variance entirely. Techniques: retrieval-based few-shot prompting, chain-of-thought, performance-conditioned generation (tell the model the target speed tier), and synthetic data augmentation via self-play.
  - *Reported results:* Adapted model: mean speedup 6.86x with 8 generations, exceeding the mean human programmer improvement of 3.66x. Best-of-many: 9.64x model vs 9.56x human. IMPORTANT CAVEAT: this is single-file competitive-programming code with dense hot loops and no localization problem. The gap between this (6.86x) and repo-level results (SWE-Perf 2.26% gain, SWE-fficiency 0.225x SR) is the single largest confound in the field — do not generalize PIE numbers to real codebases.
  - *Source:* https://arxiv.org/abs/2302.07867
- **JETO-Bench — statistically rigorous measurement of execution-time-improvement patches in Java** — Mines 660 ETIPs from 174 Java repos, filters to 91 verified executable instances, and validates patches with 30 executions plus a warm-up round under two significance regimes: default (p<=0.10, >=5% improvement) and conservative (p<=0.05, >=10%).
  - *Reported results:* OpenHands: 14.3% correct fixes (13/91; 10 exact AST matches, 3 semantically equivalent), 27.5% right location but semantically different, 22.0% wrong location entirely, 36.3% no patch generated, 22.0% test success. Single-file 18.5% vs multi-file 8.1%. The devastating number is about the HUMAN patches: of 102 executable real-world performance-improving patches, only 19 had a test showing statistically significant improvement under the default config, and only 8 under conservative. Only 15% (14/91) of repos contained JMH benchmarks. Authors explicitly warn 'many of these tests show significant improvement due to noise in time collection rather than actual performance testing.'
  - *Source:* https://arxiv.org/html/2606.31767v1
- **PerfCodeBench — system-level optimization across 6 languages including CUDA** — 1,854 executable tasks from 40+ systems repos (GPU suites, SIMD libraries, parallel frameworks, SQL engines, inference runtimes). Distribution: C++ 58.63%, Java 9.49%, C 8.74%, Go 8.63%, Python 7.77%, CUDA 6.74%. Scores correctness rate (CRR) and reference-level efficiency (CGRE) separately.
  - *Reported results:* GPT-5.4 71.25% CRR / 66.27% CGRE; Claude Opus 4.5 70.55% / 65.09%; GPT-5 61.81% / 73.99%; worst model 1.89% CRR. The capability cliff is by abstraction level: Python 85.53% CRR, Java 77.27%, C++ 74.73%, C 45.16%, CUDA 10.53%. GPT-5.4 specifically: 82.06% CPU CRR vs 2.40% GPU CRR; 68.67% CPU CGRE vs 0.00% GPU CGRE. Correctness and efficiency are shown to be decoupled axes — some models fail often but their rare successes are strong.
  - *Source:* https://arxiv.org/html/2605.15222v2
- **Efficiency-gap benchmarks: EffiBench, Mercury, EvalPerf, ECCO, COFFE** — Measure whether LLM-generated code is efficient at all, independent of any optimization task. EffiBench compares against human canonical LeetCode solutions; Mercury introduces Beyond@K (runtime-percentile-weighted pass); EvalPerf introduces Differential Performance Evaluation with generated computationally-expensive inputs; ECCO tests history-based editing vs NL-instructed optimization; COFFE replaces wall-clock with CPU instruction counts.
  - *Reported results:* EffiBench (2024, dated): GPT-4 code averages 3.12x the execution time of human canonical solutions; worst case 13.89x time and 43.92x memory across 42 models / 1,000 problems. Mercury: leading code LLMs score Pass 65% but Beyond <50% — a 15+pp correctness-vs-efficiency gap. EvalPerf (121 tasks): model scaling improves correctness but does NOT reliably improve efficiency; instruction tuning helps both; standard benchmarks' simplistic test inputs cannot reveal efficiency at all. ECCO: 'most methods degrade functional correctness and moderately increase program efficiency' — execution feedback helps preserve correctness, NL feedback improves efficiency more. COFFE (398 function-level + 358 file-level, FSE 2025) abandons wall-clock as 'not stable and comprehensive, threatening the validity of the time efficiency evaluation.'
  - *Source:* https://arxiv.org/abs/2402.02037
- **Agentic code review acceptance in the wild (CodeRabbit mining study)** — Mined 31,073 code-review-to-developer-feedback pairs across 10,191 PRs in 239 GitHub repositories, classifying each AI review comment by developer reception and each rejection by reason.
  - *Reported results:* 36.4% accepted, 7.3% triggered discussion, 56.3% REJECTED. Rejection reasons: false positives, redundant, out of scope, and misalignment with developer intent/coding practices. Agentic reviews skew toward functional concerns over evolvability concerns, 'yet they were more likely to be invalid.' Rejection is predictable at 76% F1 with lightweight learned classifiers — meaning a filter is buildable and a reviewer that ships unfiltered suggestions is leaving obvious quality on the table.
  - *Source:* https://arxiv.org/abs/2607.03316

---

## Sweep 3

**Angle.** How a performance-consultant agent synthesizes DURABLE rules and skills that an implementation agent actually follows — spec-accurate artifact formats (SKILL.md, CLAUDE.md/.claude/rules, AGENTS.md, .cursor/rules MDC, Copilot .instructions.md, Windsurf/Cline rules), evidence on rule bloat and rule-count limits, and the escalation path from prose rule to deterministic enforcement (Semgrep/ESLint/CI perf budget/hook).

### Sources (25)

| Credibility | What it is | URL |
|---|---|---|
| `peer-reviewed-or-benchmarked` | ETH Zurich (Feb 2026), the single most important negative result here: evaluated coding-agent task completion on SWE-bench tasks with LLM-generated context files AND a novel set of issues from repos with developer-committed context files. Finding: context files do NOT generally improve task success rates while increasing inference cost >20% on average, across LLMs and agents, for both LLM-generated and human-written files. Crucially: 'instructions in the context files are well followed by coding agents, [but] repository overviews, although popular and recommended by model providers, are not helpful.' | https://arxiv.org/abs/2602.11988 |
| `peer-reviewed-or-benchmarked` | ACE: Agentic Context Engineering (Stanford/SambaNova/Berkeley, Oct 2025). Generator/Reflector/Curator playbook architecture with structured DELTA updates instead of monolithic rewrite. +10.6% on agent benchmarks (AppWorld 42.4%->59.5%), +8.6% on domain benchmarks (FiNER, Formula), 86.9% lower adaptation latency, no labeled supervision required. Documents two named failure modes: 'brevity bias' and 'context collapse' — case study: accumulated context at step 60 was 18,282 tokens at 66.7% accuracy; a single monolithic LLM rewrite collapsed it to 122 tokens at 57.1%, BELOW the 63.7% no-context baseline. | https://arxiv.org/abs/2510.04618 |
| `peer-reviewed-or-benchmarked` | Zietsman, 'Structural Quality Gaps in Practitioner AI Governance Prompts' (Apr 2026). Corpus of 34 public AGENTS.md files scored by 3 independent LLM evaluators against five principles (Success Definition, Assessment Rubric, Scope Boundary, Data Classification, Quality Gate). 37% of file-model pairs scored below the 2.5/5 structural-completeness threshold; no file scored 5.0. Weakest principle: Data Classification (mean 0.34); strongest: Quality Gate (0.70). Appendix A gives literal example prompt lines at each score level — directly reusable as a rubric for grading the rules a consultant agent emits. Caveats: small n, LLM-as-judge, no formal inter-rater kappa, no downstream agent-performance measurement. | https://arxiv.org/pdf/2604.21090 |
| `primary-official` | Primary spec: CLAUDE.md scopes and load order (managed policy / ~/.claude/CLAUDE.md / ./CLAUDE.md or ./.claude/CLAUDE.md / ./CLAUDE.local.md), recursive walk up the tree, @path imports with max depth 4 hops, `.claude/rules/*.md` with `paths:` glob frontmatter, brace-expansion budget of 1,000 expanded patterns / 4 MiB per rule, auto-memory MEMORY.md 200-line/25KB load cap, claudeMdExcludes, and the explicit statement that CLAUDE.md is 'delivered as a user message after the system prompt, not as part of the system prompt itself' and is 'context, not enforced configuration.' Stated size target: under 200 lines per CLAUDE.md. | https://code.claude.com/docs/en/memory |
| `primary-official` | Primary spec: SKILL.md frontmatter validation (name max 64 chars lowercase/digits/hyphens, description max 1,024 chars, third person), 'Keep SKILL.md body under 500 lines', one-level-deep references, table of contents for reference files >100 lines, the degrees-of-freedom framework (high/medium/low freedom matched to task fragility), evaluation-driven development (write >=3 evals BEFORE the skill), and the Claude-A-authors / Claude-B-tests iteration loop. | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| `primary-official` | Primary spec, Claude Code extensions to the skill format: full frontmatter table (name, description, when_to_use, argument-hint, arguments, disable-model-invocation, user-invocable, allowed-tools, disallowed-tools, model, effort, context, agent, background, hooks, paths, shell). description+when_to_use truncated at 1,536 chars in the listing. `paths` globs gate auto-activation. Skill content enters the conversation once and is NOT re-read on later turns. Compaction re-attaches only the first 5,000 tokens of each invoked skill under a combined 25,000-token budget. | https://code.claude.com/docs/en/skills |
| `primary-official` | The cross-vendor Agent Skills open standard (originally Anthropic, now implemented by Cursor, Copilot/VS Code, Codex, Gemini CLI, OpenCode, Amp, Factory, Kiro, Roo, Goose and ~40 others). Frontmatter: name (required, 1-64, must match parent dir name, no leading/trailing/consecutive hyphens), description (required, 1-1024), license, compatibility (max 500), metadata (string map), allowed-tools (space-separated, experimental). Progressive disclosure budget stated as metadata ~100 tokens, instructions <5,000 tokens recommended, SKILL.md under 500 lines. `skills-ref validate ./my-skill` is the official validator. | https://agentskills.io/specification |
| `primary-official` | AGENTS.md standard (OpenAI + Google + Cursor + Factory, Aug 2025; donated to Linux Foundation Agentic AI Foundation Dec 2025; >60k repos, >20 tools). Spec is deliberately thin: plain Markdown, no required sections, nearest-file-in-tree wins, explicit user prompts override. No size guidance in the spec itself. | https://agents.md/ |
| `primary-official` | Primary spec for .cursor/rules MDC: frontmatter fields are exactly `description`, `globs`, `alwaysApply`; four behaviors emerge from their combination (Always Apply / Apply Intelligently / Apply to Specific Files / Apply Manually via @-mention). A plain .md file in .cursor/rules is IGNORED because it has no frontmatter. Glob syntax *, **, comma-separated lists. Nested rule directories supported. 'Keep rules under 500 lines.' | https://cursor.com/docs/context/rules |
| `primary-official` | Primary spec for Copilot: repo-wide `.github/copilot-instructions.md`; path-scoped `.github/instructions/NAME.instructions.md` with required `applyTo:` frontmatter taking comma-separated globs, plus optional `excludeAgent:` (e.g. code-review, cloud-agent). AGENTS.md honored anywhere in the tree with nearest-wins precedence; CLAUDE.md/GEMINI.md honored at root only. Explicit constraint: instructions 'must be no longer than 2 pages' and 'must not be task specific.' | https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions |
| `primary-official` | Windsurf/Cascade rules spec (docs.windsurf.com now redirects here). Locations: global ~/.codeium/windsurf/memories/global_rules.md; workspace .devin/rules/*.md preferred with .windsurf/rules/*.md fallback; legacy .windsurfrules. Four activation modes with exact field values: always_on, model_decision, glob, manual. Hard character limits: 12,000 chars per workspace rule file, 6,000 chars for global rules. Recommends rules over auto-generated memories for durable knowledge. | https://docs.devin.ai/desktop/cascade/memories |
| `primary-official` | Primary spec for Cline: `.clinerules/` directory (all .md and .txt concatenated), also reads .cursorrules/.windsurfrules/AGENTS.md, global ~/Documents/Cline/Rules, workspace beats global. Conditional rules use `paths:` glob frontmatter and fire on files in message, open tabs, visible panes, edited files, pending ops. Per-rule enable/disable toggles in the UI. Explicit guidance: 'Rules consume context tokens... Keep rules concise and link to external documentation.' | https://docs.cline.bot/features/cline-rules |
| `primary-official` | Primary spec for Semgrep rule YAML: required `id`, `message`, `severity` (LOW/MEDIUM/HIGH/CRITICAL), `languages`, and one of `pattern`/`patterns`/`pattern-either`/`pattern-regex`; plus pattern-inside, pattern-not, pattern-not-inside, pattern-not-regex, metavariable-pattern, metavariable-regex, metavariable-comparison, metavariable-name, focus-metavariable; optional `fix` (autofix), `options`, `metadata`, `paths`, `min-version`/`max-version`. This is the most compact machine-checkable rule format an agent can emit reliably. | https://docs.semgrep.dev/writing-rules/rule-syntax |
| `primary-official` | Primary spec for the pattern language: `...` ellipsis in args/statements/containers/method chains, `$X` metavariables (uppercase/underscore/digits), `$...ARGS` ellipsis metavariables, `$_` anonymous metavariable, typed metavariables `($LOGGER: java.util.logging.Logger)`, deep expression operator `<... ... ...>`, and built-in equivalences (import aliasing, constant propagation, associative-commutative matching). | https://docs.semgrep.dev/writing-rules/pattern-syntax |
| `primary-official` | Primary spec for rule tests: test file sits next to the rule with the language extension (rules/detect-eval.yaml -> rules/detect-eval.py; YAML rules use .test.yaml); annotations are `# ruleid: <id>` (must fire), `# ok: <id>` (must not fire), `# todoruleid:`, `# todook:`; run with `semgrep --test [dir]` or `semgrep --test --config <rules> <tests>`. This makes 'the agent must ship a passing test with every rule' a checkable requirement. | https://docs.semgrep.dev/writing-rules/testing-rules |
| `primary-official` | Primary spec for custom ESLint rules in flat config: rule object = `meta` {type: problem\|suggestion\|layout, docs, fixable, schema, messages} + `create(context)` returning AST visitor keys; report via context.report({node, messageId, data, fix(fixer)}); local rules loaded inline through the `plugins` key in eslint.config.js. | https://eslint.org/docs/latest/extend/custom-rules |
| `primary-official` | Primary spec for CI performance budgets as statistical gates: seven Test types (Static, Percentage, z-score, t-test, Log Normal, IQR, Delta IQR), Lower/Upper Boundary, Min Sample Size, Max Sample Size, Window. Concrete: Percentage threshold with Upper Boundary 0.10 against a historical mean of 100 alerts above 110. | https://bencher.dev/docs/explanation/thresholds/ |
| `primary-official` | Primary spec for deterministic enforcement inside the agent harness: PreToolUse returns hookSpecificOutput.permissionDecision = deny\|allow\|ask\|defer; PostToolUse/Stop/SubagentStop/UserPromptSubmit block via exit code 2 (stderr becomes the reason) or {"decision":"block","reason":...}; hooks can be scoped in skill/subagent frontmatter via a `hooks:` field and are removed when the component finishes. This is the escalation target when a prose rule keeps getting ignored. | https://code.claude.com/docs/en/hooks |
| `primary-official` | Ruff's rule index; relevant because it ships a PERF (perflint) category plus C4 (flake8-comprehensions) and SIM, giving a Python path for 'promote this finding to a lint'. I did NOT verify the individual PERF code numbers — the summarizer's specific code-to-name mappings looked unreliable, so treat only the existence of the PERF/C4/SIM prefixes as verified. | https://docs.astral.sh/ruff/rules/ |
| `practitioner-battle-tested` | Primary/vendor: quantifies the CI-noise problem that invalidates naive perf gates — bare-metal runners show 'less than 2% variance' vs GitHub Action Runners 'greater than 30% variance between runs'; recommends relative continuous benchmarking or instruction-counting harnesses instead of wall clock on shared runners. Vendor-sourced numbers, directionally consistent with common experience. | https://bencher.dev/docs/explanation/continuous-benchmarking/ |
| `practitioner-battle-tested` | Practitioner post from a team shipping agent tooling. Notes the harness itself injects 'this context may or may not be relevant to your tasks. You should not respond to this context unless it is highly relevant' — i.e. the model is explicitly licensed to ignore CLAUDE.md content it judges irrelevant, which is why non-universal rules get dropped. Their own root file is under 60 lines; recommends under 300. Argues for teaching by in-context example over prose style rules, and against auto-generating the file. | https://www.humanlayer.dev/blog/writing-a-good-claude-md |
| `popular-but-unvalidated` | Practitioner synthesis that assembles the negative evidence and supplies the citations (ETH 2602.11988, CodeIF-Bench 2503.22688, ConInstruct AAAI 2026 2511.14342, PACIFIC 2512.10713). Reports Claude 4.5 Sonnet scoring 87.3% F1 at DETECTING conflicting instructions while almost never reporting them, and human-written context files improving performance only ~4% on average. The two-bucket heuristic (agent-visible vs agent-blind) and 'delete any line that doesn't prevent a demonstrable failure' are its useful contributions. I verified the ETH citation directly; the ~4% and 87.3% figures I did not verify against the primary papers. | https://www.augmentcode.com/blog/your-agents-context-is-a-junk-drawer |
| `popular-but-unvalidated` | Practitioner post with the most-cited numbers in this space: frontier models reliably follow 150-200 instructions before compliance degrades, Claude Code's system prompt already spends ~50, leaving a 100-150 budget; CLAUDE.md should fit 40-80 lines, under 100 as an upper bound; from an analysis of 2,500+ repos using AGENTS.md, the median well-performing file was ~300-350 words, diminishing returns past 500 words, and files over 1,000 words showed NEGATIVE correlation with agent performance. The 2,500-repo analysis is the only quantified part; the 150-200 instruction threshold is asserted without cited methodology. | https://tianpan.co/blog/2026-02-14-writing-effective-agent-instruction-files |
| `anecdote` | Bug report: CLAUDE.md rules are not propagated to spawned subagents, and adherence degrades measurably after context compaction (reporter's rules about rg-vs-grep and Read-vs-bash were followed initially, violated in subagents and post-compaction). Closed as not planned / stale — NOT confirmed by Anthropic, so treat as a single well-specified anecdote. It is corroborated by the official docs, which state subagents do not inherit the main conversation's auto memory and that nested CLAUDE.md files are not re-injected after compaction. | https://github.com/anthropics/claude-code/issues/59309 |
| `unverified` | Zietsman, 'The Specification as Quality Gate: Three Hypotheses on AI-Assisted Code Review' (2026). Argues correlated errors in homogeneous LLM pipelines 'echo rather than cancel' when the same model family generates and reviews; deterministic external verification must come first, AI review confined to the bounded residual. Author explicitly says experiments use 'a planted bug corpus rather than a natural defect sample; they are directional evidence, not a controlled demonstration.' | https://arxiv.org/abs/2603.25773 |

### Verbatim prompt excerpts (10)

**arXiv:2604.21090 Appendix A, Principle 4 (Data Classification), score 1.0 exemplar — verbatim from the paper**

```
Treat verified facts from the codebase differently from inferences. Mark inferences explicitly as 'Inferred from [source]'. Do not assert facts you cannot trace to a specific file and line.
```

> This is the closest thing in the literature to a drop-in line for the central problem. Data Classification was the weakest principle in the whole 34-file corpus (mean 0.34) — almost nobody writes it — and it is exactly the missing instruction that separates a perf finding backed by a profile from one backed by vibes. The perf-specific adaptation writes itself: 'A finding must be tagged MEASURED (profile or benchmark delta, with harness and input size), ARGUED (complexity argument with the n at which it bites), or SPECULATIVE. Never report SPECULATIVE findings.'

**arXiv:2604.21090 Appendix A, Principle 3 (Scope Boundary), score 1.0 exemplar — verbatim; the 0.5 exemplar is 'Review the changed files in the pull request.'**

```
Do not review files outside the pull request diff. Do not suggest rewrites of unchanged code. If asked to approve or reject the PR, decline and explain that your role is to report findings only.
```

> A real reviewer-agent boundary, and the contrast with the 0.5 version is instructive: stating what to review is not a boundary; stating what NOT to touch and what to do when asked to step outside is. For a perf consultant this is what stops speculative rewriting of untouched hot paths.

**arXiv:2604.21090 Appendix A, Principle 5 (Quality Gate), score 1.0 exemplar — verbatim**

```
Before returning your findings, confirm: every changed file has an entry, every entry has all four required fields, and no findings reference unchanged files. Record your confirmation in the output.
```

> A self-verification step written as a checkable list rather than 'be thorough' (which the paper scores 0.5). The perf analogue is the highest-value single line in the whole consultant prompt: 'Before returning, confirm every finding carries either a profile excerpt, a benchmark delta with harness and input size, or a complexity argument naming the input size at which it bites. Delete any finding that carries none.'

**arXiv:2602.11988 (ETH Zurich), abstract — verbatim**

```
Surprisingly, we find that providing context files does not generally improve task success rates, while increasing inference cost by over 20% on average... we find that while instructions in the context files are well followed by coding agents, repository overviews, although popular and recommended by model providers, are not helpful. We conclude that while context files are useful for specifying non-standard coding practices, any attempts to improve performance should be rigorously evaluated before deployment.
```

> The sentence that should govern the consultant's entire rule-writing mandate. It gives the shape of a legitimate rule ('non-standard coding practices', i.e. things that differ from what the model would do by default) and rules out the most common thing agents write instead. The closing clause also happens to be the rule about rules: evaluate before deploying.

**Claude Code memory docs — verbatim**

```
Settings rules are enforced by the client regardless of what Claude decides to do. CLAUDE.md instructions shape Claude's behavior but are not a hard enforcement layer... If the instruction is something that must run at a specific point, such as before every commit or after each file edit, write it as a hook instead.
```

> Anthropic's own docs telling you not to trust prose rules for anything that must always hold. This is the justification for making 'promote to enforcement' the default disposition rather than an escalation of last resort, stated by the vendor whose prose-rule mechanism it is.

**Claude Code skills docs — verbatim**

```
Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as standing instructions rather than one-time steps.
```

> A mechanical fact that silently breaks skills written as procedures. A perf skill phrased as 'first profile, then...' degrades after turn one; the same content phrased as standing constraints ('never accept an optimization without a before/after measurement in this session') survives. Paired with the compaction rule — first 5,000 tokens of each skill re-attached, 25,000 combined — it also dictates ordering: non-negotiables first.

**Anthropic skill authoring best practices — verbatim, the degrees-of-freedom framing**

```
Narrow bridge with cliffs on both sides: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom)... Open field with no hazards: Many paths lead to success. Give general direction and trust Claude to find the best route (high freedom).
```

> The right calibration model for perf rules specifically, and it cuts both ways. 'How to run the benchmark harness and what counts as a significant delta' is a narrow bridge — write the exact command and the exact threshold. 'Where to look for a slowdown' is an open field — do not write a checklist there. Most bad perf rules are open-field advice written in narrow-bridge language.

**Semgrep testing spec — verbatim annotation syntax, in a rule/test pair**

```
# ruleid: no-query-in-loop\nfor user in users:\n    db.execute("SELECT * FROM orders WHERE user_id = %s", user.id)\n\n# ok: no-query-in-loop\ndb.execute("SELECT * FROM orders WHERE user_id = ANY(%s)", [u.id for u in users])
```

> The complete, minimal shape of 'a review finding turned into permanent enforcement': the caught pattern and the blessed alternative, both machine-checked by `semgrep --test`. The `ok:` line is what makes the rule survivable in a real repo. This is the concrete artifact a perf consultant should be required to emit alongside any structural finding it wants to make durable. (Rule/test pairing and annotation syntax verified against the Semgrep docs; this specific N+1 example is my construction.)

**HumanLayer, quoting the harness's own injected framing around CLAUDE.md content**

```
this context may or may not be relevant to your tasks. You should not respond to this context unless it is highly relevant
```

> Explains the ignore mechanism rather than just observing it. The harness explicitly licenses the model to skip instruction-file content it judges irrelevant — so a rule that isn't universally applicable is not merely wasteful, it is being actively invited to be dropped. This is the argument for glob-scoping over always-on placement, in the model's own words.

**Copilot repository custom instructions spec — verbatim constraint**

```
must be no longer than 2 pages... must not be task specific
```

> GitHub is the only vendor that states the size and genre constraint as a hard requirement rather than a suggestion, and 'must not be task specific' is the cleanest one-line statement of the always-on-file/skill boundary. Windsurf enforces the same idea numerically at 12,000 chars per workspace rule and 6,000 for global — worth knowing if the consultant is expected to emit portable artifacts.

### Approaches (10)

- **Scoped rule files with glob frontmatter (the cross-tool common denominator)** — Instead of appending performance rules to a global instruction file, the consultant writes one file per rule-cluster into a path-scoped rules directory so it only enters context when the implementation agent touches matching files. Every major harness now supports this and the field names differ: Claude Code `.claude/rules/*.md` with `paths:` (YAML list of globs, brace expansion supported, budget 1,000 expanded patterns / 4 MiB per rule); Cursor `.cursor/rules/*.mdc` with `globs:` + `alwaysApply: false` (a .md file there is silently ignored — it must be .mdc with frontmatter); Copilot `.github/instructions/NAME.instructions.md` with required `applyTo:` (comma-separated globs) and optional `excludeAgent:`; Windsurf `.devin/rules/*.md` with activation mode `glob`; Cline `.clinerules/*.md` with `paths:`. Claude Code skills additionally accept a `paths:` field that gates auto-activation. A consultant that emits the SAME rule body into 2-3 of these wrappers gets portability for near-zero extra tokens.
  - *Reported results:* No head-to-head measurement of scoped vs unscoped rules exists that I found. The mechanism is motivated by the measured cost side: ETH (2602.11988) found context files raise inference cost >20% on average with no general success-rate gain, so anything that keeps a rule out of context until it is relevant strictly reduces that tax. Claude Code docs state path-scoped rules exist specifically to reduce 'noise' and save context space.
  - *Source:* https://code.claude.com/docs/en/memory
- **Promote prose rule -> Semgrep rule (the highest-leverage codification step)** — A structural performance finding (N+1 query, allocation inside a loop, sync I/O on an event loop, unbounded fetch without limit, per-item await) is expressible as a Semgrep pattern in ~10 lines of YAML, which is short enough that an LLM emits it reliably and a human reviews it in 30 seconds. Required fields: id, message, severity (LOW|MEDIUM|HIGH|CRITICAL), languages, and one of pattern/patterns/pattern-either/pattern-regex. The operators that matter for perf work are `pattern-inside` (scope the match to a loop or handler body), `pattern-not` (carve out the already-correct form), `metavariable-comparison` (numeric thresholds), and `fix:` for autofix. Pattern syntax gives `...` ellipsis, `$X` metavariables, `$...ARGS`, typed metavariables `($R: *zip.Reader)`, and the deep-expression operator `<... $USER.is_admin() ...>`. Critically, Semgrep has a first-class test format: a sibling file named after the rule with `# ruleid: <id>` on lines that must fire and `# ok: <id>` on lines that must not, run via `semgrep --test`. That turns 'the agent wrote a rule' into 'the agent wrote a rule with a passing positive AND negative test'.
  - *Reported results:* None reported — I found no study measuring speedups from agent-authored Semgrep rules. The argument is structural, not empirical: a lint rule is checked on every commit forever and cannot be forgotten after compaction, whereas a prose rule demonstrably is (issue #59309; docs confirm nested CLAUDE.md is not re-injected post-compaction).
  - *Source:* https://docs.semgrep.dev/writing-rules/testing-rules
- **Promote prose rule -> custom ESLint rule with a fixer** — For JS/TS-only findings that need AST precision Semgrep can't express (or where you want autofix in the editor), the consultant emits a flat-config rule object: `meta` {type, docs, fixable: 'code', schema, messages: {id: 'text with {{placeholder}}'}} plus `create(context)` returning AST visitor keys, reporting via context.report({node, messageId, data, fix(fixer)}). It loads inline in eslint.config.js through the `plugins` key with no package to publish. The messageId indirection matters for agents: it forces the human-readable rationale to live in one place that the agent can also cite in its finding.
  - *Reported results:* None reported. Cost note: an ESLint rule is materially more code than a Semgrep pattern, so it is the second choice, not the first — reserve it for rules that need type information or an autofix.
  - *Source:* https://eslint.org/docs/latest/extend/custom-rules
- **Promote prose rule -> CI performance budget with a STATISTICAL threshold** — The strongest form for a measured regression: attach a benchmark and a threshold so the number itself becomes the rule. Bencher's model is the clearest published spec — a threshold binds Branch x Testbed x Measure and picks a Test: Static (fixed number), Percentage (deviation from historical mean; Upper Boundary 0.10 against mean 100 alerts above 110), z-score, t-test, Log Normal, IQR, or Delta IQR, parameterized by Lower/Upper Boundary, Min Sample Size, Max Sample Size, and Window. The trap is CI noise: shared runners show >30% run-to-run variance vs <2% on bare metal, so a naive percentage gate on wall-clock time on GitHub Actions produces mostly false alarms. The documented mitigations are bare-metal runners, relative benchmarking (run base and PR in the same job and compare), or switching the harness to instruction counts instead of wall clock.
  - *Reported results:* Bencher (vendor) reports <2% variance bare metal vs >30% on GitHub Action Runners. No independent measurement of how often perf budgets catch real regressions.
  - *Source:* https://bencher.dev/docs/explanation/thresholds/
- **Promote prose rule -> harness hook (deterministic, in-loop, no CI wait)** — When a rule keeps being ignored mid-task, escalate it from context to a hook. Claude Code's PreToolUse hook returns {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}} to block a tool call outright; PostToolUse/Stop/SubagentStop block via exit code 2 with stderr as the reason, or {"decision":"block","reason":...}. A PostToolUse hook on Edit/Write that runs the project's Semgrep perf ruleset over the touched file and returns exit 2 with the finding text feeds the violation straight back to the implementation agent inside the same turn. Hooks can be scoped in skill or subagent frontmatter via a `hooks:` field and are auto-removed when the component finishes — which also solves the subagent-inheritance gap that prose rules have.
  - *Reported results:* None reported. Anthropic's docs make the strongest available claim: 'Settings rules are enforced by the client regardless of what Claude decides to do. CLAUDE.md instructions shape Claude's behavior but are not a hard enforcement layer.' Compare with the measured degradation of prose adherence post-compaction.
  - *Source:* https://code.claude.com/docs/en/hooks
- **Skill (progressive disclosure) rather than always-loaded rule, for anything procedural** — A perf rule that is a multi-step procedure ('how to profile this service', 'how to add a benchmark to this repo', 'the query-plan checklist for this ORM') belongs in a SKILL.md, not in CLAUDE.md. Only name+description are preloaded (~100 tokens/skill per the open standard); the body loads on activation; reference files load only if opened. Verified constraints: name max 64 chars, lowercase/digits/hyphens, no leading/trailing/consecutive hyphens, must match parent directory name; description max 1,024 chars, third person, must state both WHAT and WHEN; body under 500 lines / <5,000 tokens recommended; references one level deep only (Claude partially reads files reached through nested references, e.g. via head -100); reference files >100 lines need a table of contents. Claude Code adds `when_to_use`, `paths` for glob-gated auto-activation, `disable-model-invocation`, `allowed-tools`, `context: fork`, and a `hooks:` block; description+when_to_use are truncated at 1,536 chars in the listing.
  - *Reported results:* No controlled measurement of skills vs inline rules that I found. Anthropic reports the architectural benefit only (metadata-only preload). One important operational fact from the Claude Code docs: an invoked skill's content is injected once and the file is NOT re-read on later turns, and after compaction only the first 5,000 tokens of each skill are re-attached under a combined 25,000-token budget — so front-load the non-negotiable rules in the first ~5,000 tokens of the skill.
  - *Source:* https://agentskills.io/specification
- **ACE-style delta-updated playbook (append/edit bullets, never monolithic rewrite)** — Treat the accumulated performance-rules file as an evolving playbook maintained by three roles: a Generator that produces trajectories, a Reflector that extracts what worked/failed, and a Curator that emits localized delta updates (add / merge / prune individual bullets) rather than rewriting the whole file. A grow-and-refine step de-duplicates semantically near-identical bullets. Applied to a perf consultant: after each review, it appends only the rules the review actually justified, tagged with the evidence (benchmark delta or profile) that produced them, and de-duplicates against existing rules — it never regenerates the whole rules file.
  - *Reported results:* +10.6% average on agent benchmarks (AppWorld 42.4% base -> 59.5% ACE), +8.6% on domain-specific benchmarks (FiNER 70.7%->78.3%, Formula 67.5%->76.5%), 86.9% lower adaptation latency, effective without labeled supervision. The negative control is the sharpest number in this whole research set: monolithic LLM rewriting collapsed an 18,282-token context at 66.7% accuracy down to 122 tokens at 57.1%, which is BELOW the 63.7% no-context baseline. Caveat: ACE was evaluated on agent/reasoning benchmarks, not on codebase performance work, so transfer is an assumption.
  - *Source:* https://arxiv.org/abs/2510.04618
- **Five-principle structural grading of each emitted rule (Success Definition / Assessment Rubric / Scope Boundary / Data Classification / Quality Gate)** — Before writing a rule, score it 0 / 0.5 / 1 on: (1) does it define what done looks like; (2) does it give criteria the agent can apply to its own output; (3) does it state what is OUT of scope and what to do at the boundary; (4) does it say how different input types are handled differently (e.g. 'treat a measured benchmark delta differently from an inferred complexity argument; mark inferences as Inferred from [source]'); (5) does it require a verification step before returning. Ship only rules totalling >=4.0. The paper's appendix supplies literal exemplar text at each score level, so this is directly operationalizable as a self-check in the consultant's own prompt.
  - *Reported results:* Across 34 public AGENTS.md files scored by 3 LLM evaluators, 37% of file-model pairs fell below the 2.5/5 completeness threshold and NO file reached 5.0. Data Classification was weakest (mean 0.34), Quality Gate strongest (0.70). Evidence caveat: this measures structural presence of prompt features, NOT downstream agent performance — the paper is explicit that a structurally complete prompt can still contain wrong content.
  - *Source:* https://arxiv.org/pdf/2604.21090
- **Emit instructions, never repository overviews** — The ETH result decomposes context-file content into two classes with opposite effects. Imperative, non-obvious instructions ('this cache is invalidated by X, so do Y'; 'never call this in a request handler') are well followed and are the legitimate output of a consultant. Descriptive repository overviews (architecture summaries, directory maps, dependency lists) are not helpful — the agent can already read the code. Claude Code has operationalized exactly this: `/doctor` now proposes trims that 'cut content Claude can derive from the codebase, such as directory layouts, dependency lists, and architecture overviews, and keeps pitfalls, rationale, and conventions that differ from tool defaults.'
  - *Reported results:* ETH Zurich, Feb 2026: across SWE-bench tasks with LLM-generated context files and real issues from repos with developer-committed context files, providing context files did not generally improve task success rate while increasing inference cost >20% on average; the effect held across LLMs, agents, and both file provenances. Their explicit decomposition: instructions followed well, repository overviews not helpful.
  - *Source:* https://arxiv.org/abs/2602.11988
- **Rule-count budgeting against a finite instruction-following capacity** — Treat instruction slots as a scarce, shared resource: a frontier model is claimed to reliably follow ~150-200 instructions before compliance degrades, of which the harness's own system prompt already consumes ~50. Every rule the perf consultant adds is drawn from the same ~100-150 remaining budget that security, style, testing, and the task itself compete for. Practical consequence: a perf consultant should hold a hard cap (a handful of always-on rules; everything else glob-scoped or in a skill), and should be required to DELETE or merge an existing rule when it adds one past the cap.
  - *Reported results:* The 150-200 figure is asserted without cited methodology — treat as folklore-with-a-number. The better-grounded companion figures come from an analysis of 2,500+ AGENTS.md repos: median well-performing file ~300-350 words, diminishing returns past 500 words, and files over 1,000 words showing NEGATIVE correlation with agent performance. Anthropic's own docs independently state 'target under 200 lines per CLAUDE.md. Longer files consume more context and reduce adherence.' Windsurf enforces the idea mechanically: 12,000 chars per workspace rule file, 6,000 for global. Copilot: 'no longer than 2 pages'.
  - *Source:* https://tianpan.co/blog/2026-02-14-writing-effective-agent-instruction-files

---

## Sweep 4

**Angle.** Real artifacts and agent-usable tooling: what the actual text of shipped performance-agent files says, which measurement tools an agent can be wired to, and whether any of it survives contact with the evidence.

### Sources (26)

| Credibility | What it is | URL |
|---|---|---|
| `peer-reviewed-or-benchmarked` | GSO: Challenging Software Optimization Tasks for Evaluating SWE-Agents. 102 optimization tasks, 10 codebases. Leading SWE-agents score <5% Opt@1. | https://arxiv.org/abs/2505.23671 |
| `peer-reviewed-or-benchmarked` | GSO leaderboard site. Defines Opt@1 (≥95% of human speedup + passes correctness) and documents a 'Hack Detector' that penalizes deceptive optimizations (memoization, harness hijacking). | https://gso-bench.github.io/ |
| `peer-reviewed-or-benchmarked` | SWE-Perf: 140 instances from real performance-improving PRs. Full results table with per-model Apply/Correctness/Performance numbers vs an expert baseline. | https://arxiv.org/abs/2507.12415 |
| `primary-official` | Anthropic's built-in `web-perf` Claude Code skill (read in full, 202 lines). The single best perf-agent artifact I found: hard tool-availability gate, numeric thresholds, explicit zero-impact suppression, explicit permission to report no findings. | /Users/kyeshmz/.claude/skills/web-perf/SKILL.md |
| `primary-official` | PlanetScale's official MySQL skill. Written by a database company for their own customers' agents. Numeric thresholds, falsifiable rules, explicit 'prefer measured evidence over blanket rules of thumb' guardrail. | https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/SKILL.md |
| `primary-official` | PlanetScale EXPLAIN reference: access-type ranking, key_len arithmetic, rows×filtered, and EXPLAIN ANALYZE pitfalls including warm-cache masking. | https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/references/explain-analysis.md |
| `primary-official` | PlanetScale N+1 reference. Contains an actual runnable detection query against performance_schema.events_statements_summary_by_digest, plus batch-size limits. | https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/references/n-plus-one.md |
| `primary-official` | Bencher's continuous-benchmarking explainer. States GitHub Action Runners see >30% variance between runs vs <2% on bare metal. | https://bencher.dev/docs/explanation/continuous-benchmarking/ |
| `primary-official` | Bencher threshold docs: seven statistical tests, minimum sample sizes, and the note that z-score wants ≥30 historical metrics. | https://bencher.dev/docs/explanation/thresholds/ |
| `primary-official` | Criterion.rs analysis chapter: warmup doubling, bootstrapped t-test for change detection, Tukey outlier classification, and a configurable noise threshold below which changes are ignored. | https://bheisler.github.io/criterion.rs/book/analysis.html |
| `primary-official` | OpenJDK JMH README. Source of the best available humility quote about benchmark harnesses. | https://github.com/openjdk/jmh |
| `primary-official` | Chrome DevTools MCP tool reference. performance_start_trace / performance_stop_trace / performance_analyze_insight with named insights (LCPBreakdown, CLSCulprits, DocumentLatency, RenderBlocking, NetworkRequestsDepGraph). | https://raw.githubusercontent.com/ChromeDevTools/chrome-devtools-mcp/main/docs/tool-reference.md |
| `primary-official` | Lighthouse CI configuration. assertions with minScore/maxNumericValue/maxLength, error vs warn levels, budgets.json, and aggregation methods (median / optimistic / pessimistic / median-run). | https://raw.githubusercontent.com/GoogleChrome/lighthouse-ci/main/docs/configuration.md |
| `primary-official` | Anthropic engineering post on Agent Skills. Progressive disclosure, and the explicit instruction to have Claude capture successful approaches and common mistakes into a skill. | https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills |
| `practitioner-battle-tested` | PostHog's ReviewHog final validation gate — the keep/drop rubric applied to candidate findings from specialist review perspectives. Ships in the official PostHog Claude plugin and runs on their real PRs. | /Users/kyeshmz/.claude/plugins/cache/claude-plugins-official/posthog/1.1.54/skills/review-hog-validation-criteria/SKILL.md |
| `practitioner-battle-tested` | PostHog's performance/reliability review perspective — one of several parallel perspectives on a PR chunk. Has ripgrep investigation commands but no measurement requirement. | /Users/kyeshmz/.claude/plugins/cache/claude-plugins-official/posthog/1.1.54/skills/review-hog-perspective-performance-reliability/SKILL.md |
| `practitioner-battle-tested` | github-action-benchmark README. `alert-threshold` (default 200%), `fail-on-alert`, `comment-on-alert`. The cheapest way to turn a benchmark into a CI gate. | https://raw.githubusercontent.com/benchmark-action/github-action-benchmark/master/README.md |
| `practitioner-battle-tested` | hyperfine README. Statistical outlier detection, ≥10 runs / ≥3s defaults, --warmup, --prepare for cold cache, shell-spawn-time correction, -N for sub-5ms commands, JSON export. | https://raw.githubusercontent.com/sharkdp/hyperfine/master/README.md |
| `practitioner-battle-tested` | py-spy README. Sampling profiler that attaches to a running PID with no code changes and no restart — the most agent-friendly Python profiler because it needs no instrumentation edit. | https://raw.githubusercontent.com/benfred/py-spy/master/README.md |
| `practitioner-battle-tested` | Scalene README. CPU+GPU+memory profiler with LLM-generated optimization proposals wired directly to profile lines. The one shipped product that closes the profile→LLM loop. | https://raw.githubusercontent.com/plasma-umass/scalene/master/README.md |
| `practitioner-battle-tested` | shadcn's `improve` skill audit playbook + closing-the-loop reference. Finding format with Confidence tiers, prioritization rubric, and 'executors game criteria' warning during review. | /Users/kyeshmz/.claude/skills/improve/references/audit-playbook.md |
| `popular-but-unvalidated` | VoltAgent's performance-engineer subagent (287 lines). Pure noun-phrase checklist. Contains a fabricated results template the model is told to emit. | https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/categories/04-quality-security/performance-engineer.md |
| `popular-but-unvalidated` | wshobson/agents performance-engineer (167 lines). Capability taxonomy of tool brand names; no procedure, no measurement gate, no output contract. | https://raw.githubusercontent.com/wshobson/agents/main/plugins/application-performance/agents/performance-engineer.md |
| `popular-but-unvalidated` | wshobson/agents 13-step performance-optimization orchestrator command (681 lines). Excellent process scaffolding (state.json, checkpoints, halt-on-failure) wrapped around 13 steps that each produce a markdown document and never execute a profiler. | https://raw.githubusercontent.com/wshobson/agents/main/plugins/application-performance/commands/performance-optimization.md |
| `popular-but-unvalidated` | wshobson/agents database-optimizer (162 lines). Same capability-taxonomy shape; lists EXPLAIN ANALYZE as a bullet but never tells the agent to run it. | https://raw.githubusercontent.com/wshobson/agents/main/plugins/database-cloud-optimization/agents/database-optimizer.md |
| `popular-but-unvalidated` | awesome-claude-code-toolkit performance-engineer. Notably better than the two big collections: has a 5-step measure/profile/hypothesize/implement/verify loop with a revert condition, and per-language tool lists. | https://raw.githubusercontent.com/rohitg00/awesome-claude-code-toolkit/main/agents/quality-assurance/performance-engineer.md |

### Verbatim prompt excerpts (31)

**/Users/kyeshmz/.claude/skills/web-perf/SKILL.md (Anthropic built-in Claude Code skill)**

```
## FIRST: Verify MCP Tools Available

**Run this before starting.** Try calling `navigate_page` or `performance_start_trace`. If unavailable, STOP—the chrome-devtools MCP server isn't configured.
```

> The only hard measurement gate I found in any perf agent artifact. It is a blocking precondition with a defined failure action, not an exhortation. This is the line to steal first.

**/Users/kyeshmz/.claude/skills/web-perf/SKILL.md**

```
## Key Guidelines

- **Be assertive**: Verify claims by checking network requests, DOM, or codebase—then state findings definitively.
- **Verify before recommending**: Confirm something is unused before suggesting removal.
- **Quantify impact**: Use estimated savings from insights. Don't prioritize changes with 0ms impact.
- **Skip non-issues**: If render-blocking resources have 0ms estimated impact, note but don't recommend action.
- **Be specific**: Say "compress hero.png (450KB) to WebP" not "optimize images".
- **Prioritize ruthlessly**: A site with 200ms LCP and 0 CLS is already excellent—say so.
```

> Six lines that do more work than the 287-line VoltAgent file. Each is falsifiable, each names a unit, and the last one explicitly authorizes a zero-finding report. 'Say "compress hero.png (450KB) to WebP" not "optimize images"' is the specificity bar stated as an example pair.

**/Users/kyeshmz/.claude/skills/web-perf/SKILL.md**

```
Your knowledge of web performance metrics, thresholds, and tooling APIs may be outdated. **Prefer retrieval over pre-training** when citing specific numbers or recommendations.

## Retrieval Sources

| Source | How to retrieve | Use for |
|--------|----------------|---------|
| web.dev | `https://web.dev/articles/vitals` | Core Web Vitals thresholds, definitions |
```

> Direct anti-folklore instruction, applied precisely where folklore is most dangerous — specific numbers. Note it doesn't just say 'don't guess', it names the canonical source to fetch instead.

**/Users/kyeshmz/.claude/skills/web-perf/SKILL.md**

```
6. **Unused preconnects**: If flagged, verify by checking if ANY requests went to that origin. If zero requests, it's definitively unused—recommend removal. If requests exist but loaded late, the preconnect may still be valuable.
```

> A worked example of turning a heuristic flag into a decision procedure with a branch. The tool says 'unused preconnect'; the skill tells the agent how to confirm or refute it before speaking. Every perf heuristic should get this treatment.

**/Users/kyeshmz/.claude/plugins/cache/claude-plugins-official/posthog/1.1.54/skills/review-hog-validation-criteria/SKILL.md**

```
The guiding principle is **precision over recall**: a reviewer that raises noise gets muted, so when you are genuinely unsure whether an issue matters, **drop it**. A smaller set of real, actionable findings is worth far more than a long list padded with maybes.
```

> States the economic argument the reviewer needs to internalize — the cost of noise is that the whole channel gets ignored. This is the sentence that justifies every suppression rule downstream.

**/Users/kyeshmz/.claude/plugins/cache/claude-plugins-official/posthog/1.1.54/skills/review-hog-validation-criteria/SKILL.md**

```
- **Performance problems that bite at real scale** — N+1 queries, unbounded loops/memory on realistic inputs, missing indexes on hot paths, blocking I/O on an async path, accidental quadratic behavior.

[...]

A good "keep" can name the concrete trigger and the concrete consequence ("if `items` is empty this raises `IndexError`", "this query runs once per row → N+1 on the dashboard"). If you can't name both, be skeptical.
```

> The best available formulation of the evidence bar. 'Bite at real scale' plus 'realistic inputs' rules out input-size-agnostic complexity theater; 'name the concrete trigger and the concrete consequence' is checkable by the model on its own draft finding.

**/Users/kyeshmz/.claude/plugins/cache/claude-plugins-official/posthog/1.1.54/skills/review-hog-validation-criteria/SKILL.md**

```
Drop it if it is any of:

- **Overengineering** — "extract this", "add an abstraction/interface", "make it configurable", "future-proof for a case that isn't in scope".
- **Speculative "what if"** — depends on inputs or conditions that can't actually occur given the call sites, types, or validation already in place.
[...]
- **Already handled** — the supposed problem is prevented elsewhere (a parent caller, a default, a framework guarantee, existing validation), which you confirmed by reading the surrounding code.
- **Wrong / unreproducible** — investigating the actual code shows the premise is mistaken.

## How to decide

1. Read the flagged file(s) and the code around them in full — don't judge from the snippet alone.
2. Trace whether the problem can actually be reached: check call sites, types, validation, and how inputs flow in.
[...]
4. On the fence → **drop** (precision over recall, as above).
```

> A drop taxonomy plus a reachability procedure. Step 2 ('trace whether the problem can actually be reached') is the specific antidote to the LLM habit of flagging a quadratic loop that only ever sees 5 elements.

**https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/SKILL.md**

```
## Workflow
1. Define workload and constraints (read/write mix, latency target, data volume, MySQL version, hosting platform).
2. Read only the relevant reference files linked in each section below.
3. Propose the smallest change that can solve the problem, including trade-offs.
4. Validate with evidence (`EXPLAIN`, `EXPLAIN ANALYZE`, lock/connection metrics, and production-safe rollout steps).
5. For production changes, include rollback and post-deploy verification.

[...]

## Guardrails
- Prefer measured evidence over blanket rules of thumb.
- Note MySQL-version-specific behavior when giving advice.
- Ask for explicit human approval before destructive data operations (drops/deletes/truncates).
```

> Step 1 makes the agent state the input size and latency target before proposing anything — which is exactly what makes a complexity argument legitimate rather than folklore. 'Propose the smallest change that can solve the problem' is the counterweight to the LLM instinct to propose a caching layer.

**https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/SKILL.md**

```
## Indexing
- Composite order: equality first, then range/sort (leftmost prefix rule).
- Range predicates stop index usage for subsequent columns.
- Secondary indexes include PK implicitly. Prefix indexes for long strings.
- Audit via `performance_schema` — drop indexes with `count_read = 0`.

## Partitioning
- Partition time-series (>50M rows) or large tables (>100M rows). Plan early — retrofit = full rebuild.

## Query Optimization
- Check `EXPLAIN` — red flags: `type: ALL`, `Using filesort`, `Using temporary`.
- Cursor pagination, not `OFFSET`. Avoid functions on indexed columns in `WHERE`.
- Batch inserts (500–5000 rows). `UNION ALL` over `UNION` when dedup unnecessary.
```

> Every rule here is checkable against a tool output or a row count. Compare to wshobson's database-optimizer, which covers the same topics as '**Advanced indexing**: B-tree, Hash, GiST, GIN, BRIN indexes, covering indexes'. Same subject matter, opposite utility.

**https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/references/explain-analysis.md**

```
## Access Types (Best → Worst)
`system` → `const` → `eq_ref` → `ref` → `range` → `index` (full index scan) → `ALL` (full table scan)

Target `ref` or better. `ALL` on >1000 rows almost always needs an index.

[...]

**Limitations / pitfalls:**
- Adds instrumentation overhead (measurements are not perfectly "free")
- Cost units (arbitrary) and time (ms) are different; don't compare them directly
- Results reflect real execution, including buffer pool/cache effects (warm cache can hide I/O problems)
```

> A ranked scale plus a numeric trigger ('>1000 rows'), and then — crucially — the ways the measurement itself lies. The warm-cache caveat is the database analogue of JIT warmup and is exactly the trap an agent falls into when it runs EXPLAIN ANALYZE twice and reports the second number.

**https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/references/n-plus-one.md**

```
## Detecting in MySQL Production

```sql
-- High-frequency simple queries often indicate N+1
-- Requires performance_schema enabled (default in MySQL 5.7+)
SELECT digest_text, count_star, avg_timer_wait
FROM performance_schema.events_statements_summary_by_digest
ORDER BY count_star DESC LIMIT 20;
```
```

> The difference between a perf agent and a perf oracle. This is a command that returns evidence. Contrast PostHog's grep-based N+1 heuristic (`rg "for.*in|while" -A 10 | rg "query|select|fetch"`), which returns co-occurrence.

**/Users/kyeshmz/.claude/skills/improve/references/audit-playbook.md**

```
## 3. Performance

Look for the algorithmic and architectural wins, not micro-optimizations.

- N+1 patterns: query/fetch per item inside loops or per list-row rendering; missing batching or dataloader.
- Wrong complexity: nested scans over the same collection, repeated `find`/`filter` inside hot loops where a Map keyed lookup belongs.
[...]
- Backend: synchronous work that belongs in a queue, missing indexes implied by query patterns (flag for verification — don't claim without schema evidence), connection-per-request patterns where pooling exists.
```

> Opens with the scope exclusion (no micro-optimizations) and closes with an inline verification requirement in parentheses. 'Flag for verification — don't claim without schema evidence' is a per-finding-type evidence rule, which is more precise than a blanket 'measure first'.

**/Users/kyeshmz/.claude/skills/improve/references/audit-playbook.md**

```
- **Evidence**: `path/file.ts:123` — one-sentence description of what's there. (Repeat per location; 2–5 strongest locations, note "and ~N similar sites" if widespread.)
- **Impact**: What goes wrong / what's being paid because of this. Concrete: "every order-list render issues 1+N queries", not "suboptimal".
[...]
- **Confidence**: HIGH (read the code, certain) / MED (strong signal, needs verification) / LOW (smell, needs investigation). LOW-confidence findings may be reported but get an "investigate" plan, not a "fix" plan.

## Prioritization rubric

Order findings by **leverage = impact ÷ effort, discounted by confidence and fix-risk**. [...] 4. "Not worth doing" is a valid verdict; record it with one line of reasoning so the user knows it was considered.
```

> The confidence tier with a differentiated downstream action is the mechanism that keeps real-but-unproven signal without letting it become an unmeasured code change. 'Concrete: "every order-list render issues 1+N queries", not "suboptimal"' is a good/bad example pair for the Impact field.

**/Users/kyeshmz/.claude/skills/improve/references/closing-the-loop.md**

```
4. **Audit the new tests.** Executors game criteria — a test that asserts nothing meaningful passes `pnpm test` and proves nothing. Read what the tests assert.
```

> Generalizes directly to perf: executors game benchmarks. A memoization keyed on the benchmark fixture passes the benchmark and proves nothing. The consultant must read what the benchmark measures, not just whether the number moved.

**https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/categories/04-quality-security/performance-engineer.md**

```
Progress tracking:
```json
{
  "agent": "performance-engineer",
  "status": "optimizing",
  "progress": {
    "response_time_improvement": "68%",
    "throughput_increase": "245%",
    "resource_reduction": "40%",
    "cost_savings": "35%"
  }
}
```

[...]

Delivery notification:
"Performance optimization completed. Improved response time by 68% (2.1s to 0.67s), increased throughput by 245% (1.2k to 4.1k RPS), and reduced resource usage by 40%. System now handles 10x peak load with linear scaling. Implemented comprehensive monitoring and capacity planning."
```

> Included as a negative exemplar. This is a prompt teaching a model that the deliverable is a paragraph of impressive percentages, with no step anywhere in the file that produces a number. Never ship an example output containing a measurement whose provenance isn't also shown.

**https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/categories/04-quality-security/performance-engineer.md**

```
Bottleneck analysis:
- CPU profiling
- Memory analysis
- I/O investigation
- Network latency
- Database queries
- Cache efficiency
- Thread contention
- Resource locks

Application profiling:
- Code hotspots
- Method timing
- Memory allocation
- Object creation
- Garbage collection
- Thread analysis
- Async operations
- Library performance
```

> Representative of ~150 of the file's 287 lines. Sixteen noun phrases, zero verbs, zero tools, zero thresholds, zero evidence requirements. Nothing here can be complied with or violated. This is what most 'performance-engineer' agent files in awesome-lists actually are.

**https://raw.githubusercontent.com/wshobson/agents/main/plugins/application-performance/agents/performance-engineer.md**

```
## Behavioral Traits

- Measures performance comprehensively before implementing any optimizations
- Focuses on the biggest bottlenecks first for maximum impact and ROI
[...]

## Response Approach

1. **Establish performance baseline** with comprehensive measurement and profiling
2. **Identify critical bottlenecks** through systematic analysis and user journey mapping
```

> The soft version of the right idea, and it is worth studying precisely because it sounds correct. 'Measures performance comprehensively before implementing any optimizations' names no tool, defines no artifact, and has no failure branch — so the model satisfies it by asserting that it considered performance. Compare web-perf's version, which is a tool call with a STOP.

**https://raw.githubusercontent.com/wshobson/agents/main/plugins/application-performance/commands/performance-optimization.md**

```
## CRITICAL BEHAVIORAL RULES

You MUST follow these rules exactly. Violating any of them is a failure.

1. **Execute steps in order.** Do NOT skip ahead, reorder, or merge steps.
2. **Write output files.** Each step MUST produce its output file in `.performance-optimization/` before the next step begins. Read from prior step files — do NOT rely on context window memory.
3. **Stop at checkpoints.** When you reach a `PHASE CHECKPOINT`, you MUST stop and wait for explicit user approval before continuing.
4. **Halt on failure.** If any step fails (agent error, test failure, missing dependency), STOP immediately.
```

> Genuinely good process engineering, worth reusing — file-based handoff instead of context-window trust, mandatory human checkpoints, halt-on-failure. The tragedy is what it wraps: 13 steps whose only artifact is prose. Steal the scaffolding, replace the payload with tool invocations.

**https://raw.githubusercontent.com/wshobson/agents/main/plugins/application-performance/commands/performance-optimization.md**

```
Profile application performance comprehensively for: $TARGET.

    Generate flame graphs for CPU usage, heap dumps for memory analysis, trace I/O operations,
    and identify hot paths. Use APM tools like DataDog or New Relic if available.
    [...]
    Write your complete profiling report as a single markdown document.

[...]

## Success Criteria
- Response Time: P50 < 200ms, P95 < 1s, P99 < 2s for critical endpoints
- Core Web Vitals: LCP < 2.5s, FID < 100ms, CLS < 0.1
- Database Performance: Query P95 < 100ms, no queries > 1s
- Cost Efficiency: Performance per dollar improved by minimum 30%
```

> 'Generate flame graphs… Write your complete profiling report as a single markdown document.' No command, no tool availability check, no path where the report is empty because nothing was measured. And 'Cost Efficiency: Performance per dollar improved by minimum 30%' is a success criterion the agent cannot possibly evaluate. This is the canonical failure of the genre.

**https://raw.githubusercontent.com/rohitg00/awesome-claude-code-toolkit/main/agents/quality-assurance/performance-engineer.md**

```
## Core Methodology

1. **Measure** the current performance with reproducible benchmarks.
2. **Profile** to identify the actual bottleneck. Never guess.
3. **Hypothesize** a fix based on the profiling data.
4. **Implement** the fix in the smallest possible change.
5. **Verify** the improvement with the same benchmark. If the numbers do not improve, revert.

[...]

## Benchmarking Standards

- Run benchmarks on consistent hardware. Document the machine specs.
- Warm up the JIT compiler and caches before measuring. Discard the first N iterations.
- Run enough iterations for statistical significance. Report mean, P50, P95, P99, and standard deviation.
- Compare before/after with the same benchmark. Use statistical tests (t-test) to confirm the improvement is real.

## Before Completing a Task

- Provide before and after measurements with the same benchmark methodology.
- Verify the optimization does not change behavior (run the test suite).
- Check for regressions in other areas. Optimizing one path sometimes slows another.
```

> The best of the community agent files by a wide margin, and from the least famous repo. 'If the numbers do not improve, revert' is a real termination condition. The benchmarking-standards block names warmup, discarding early iterations, distributional reporting, and a t-test. 'Verify the optimization does not change behavior (run the test suite)' is the joint-claim rule that SWE-Perf's correctness numbers demand. Its weakness: still no tool-availability gate, so a model with no benchmark can narrate all five steps.

**https://bencher.dev/docs/explanation/continuous-benchmarking/**

```
General purpose CI environments are often noisy and inconsistent when measuring wall clock time. [...] GitHub Action Runners, which can see greater than 30% variance between runs [...] Bare Metal Runners with less than 2% variance.
```

> The number that should appear verbatim in the consultant's prompt. It converts 'CI benchmarks are noisy' from a caveat into a disqualifying threshold: no optimization an agent proposes is going to beat 30% variance, so a single shared-runner wall-clock delta is never admissible evidence.

**https://bheisler.github.io/criterion.rs/book/analysis.html**

```
Optimizations or regressions within (for example) ±1% are considered noise and ignored. [...] The fraction of the bootstrapped T scores which are more extreme than the T score calculated by comparing the two measured samples gives the probability that the observed difference [...] is merely by chance. [...] outlier samples are _not_ dropped from the data, and are used in the following analysis steps.
```

> Shows what 'is this a real speedup' looks like when done properly: a bootstrapped t-test plus an explicit noise floor, with outliers surfaced but not silently discarded. An agent prompt can borrow the shape — 'state your noise floor; deltas inside it are not findings.'

**https://github.com/openjdk/jmh**

```
Your benchmarks should be peer-reviewed. Do not assume that a nice harness will magically free you from considering benchmarking pitfalls.
```

> From the people who built the most careful benchmark harness in existence. The right epistemic posture to install in a perf consultant: the measurement is itself a claim that needs reviewing, not the thing that ends the argument.

**https://gso-bench.github.io/**

```
Opt@1: Estimator of fraction of tasks where a single attempt achieves ≥95% human speedup and passes correctness tests. [...] Hack Detector [...] penalizes deceptive optimizations (e.g., memoization, harness hijacking).
```

> Two things: the success metric bundles speedup with correctness (never one without the other), and the benchmark authors had to build anti-cheat because agents reliably game perf tests. Both translate straight into review rules.

**https://arxiv.org/abs/2505.23671**

```
Our quantitative evaluation reveals that leading SWE-Agents struggle significantly, achieving less than 5% success rate, with limited improvements even with inference-time scaling. Our qualitative analysis identifies key failure modes, including difficulties with low-level languages, practicing lazy optimization strategies, and challenges in accurately localizing bottlenecks.
```

> The strongest available evidence for the central problem. Agents are handed a performance test as a precise spec and still fail >95% of the time, and 'challenges in accurately localizing bottlenecks' names exactly the step a static perf reviewer is claiming to perform.

**https://arxiv.org/abs/2507.12415 (Table 2)**

```
Expert: Apply 100.00% | Correctness 100.00% | Performance 10.85%. Claude-4-opus (oracle): 85.71% | 78.57% | 1.28%. Gemini-2.5-Pro (oracle): 95.00% | 83.57% | 1.48%. Claude-3.7-sonnet + OpenHands (repo-level): 87.86% | 77.86% | 2.26%.
```

> Two numbers to internalize. Best agent extracts 2.26% where experts get 10.85% — roughly one fifth of the available win. And correctness falls to 77–84%, so a sixth to a quarter of model optimization patches break behavior. Any perf finding must be paired with a correctness claim.

**https://raw.githubusercontent.com/sharkdp/hyperfine/master/README.md**

```
Note that hyperfine always *corrects for the shell spawning time*. [...] If you want to run a benchmark *without an intermediate shell*, you can use the `-N` or `--shell=none` option. This is helpful for very fast commands (< 5 ms) where the shell startup overhead correction would produce a significant amount of noise. [...] Conversely, if you want to run the benchmark for a cold cache, you can use the `-p`/`--prepare` option to run a special command before *each* timing run.
```

> Concrete measurement hygiene an agent can actually execute: `hyperfine --warmup 3 --export-json before.json 'cmd'`, `-N` below 5ms, `--prepare` for cold-cache runs. The 5ms boundary is the kind of number that belongs in a prompt.

**https://raw.githubusercontent.com/GoogleChrome/lighthouse-ci/main/docs/configuration.md**

```
"assertions": {
  "first-contentful-paint": "off",
  "audit-id-1": ["warn", {"maxNumericValue": 4000}],
  "categories:performance": ["warn", {"minScore": 0.9}]
}

[...] `error` - The audit result will be checked, the result will be printed to stderr, and failure will result in a non-zero exit code. [...] `pessimistic` - Use the value that is least likely to pass from all runs.
```

> The concrete shape of a frontend perf budget the consultant can propose as a durable artifact instead of a rule: instead of writing 'keep the bundle small' into the implementer's prompt, commit a lighthouserc assertion that fails CI. A budget file is a rule the implementation agent cannot forget.

**https://raw.githubusercontent.com/benchmark-action/github-action-benchmark/master/README.md**

```
By default, this action marks the result as performance regression when it is worse than the previous exceeding 200% threshold. [...] The threshold can be changed by `alert-threshold` input. [...] `fail-on-alert: true` — Workflow will fail when an alert happens.
```

> Note the default is 200% — deliberately loose, because the maintainers know CI noise is large. A consultant proposing a regression gate should propose a threshold justified by the observed run-to-run variance of that repo's benchmarks, not a round number.

**https://raw.githubusercontent.com/benfred/py-spy/master/README.md**

```
It lets you visualize what your Python program is spending time on without restarting the program or modifying the code in any way. py-spy is extremely low overhead: it is written in Rust for speed and doesn't run in the same process as the profiled Python program. This means py-spy is safe to use against production Python code. [...] py-spy record -o profile.svg --pid 12345
```

> One command, no code edit, works on a live process, emits a flamegraph or speedscope JSON. This is the lowest-friction way to make 'go measure it' a real instruction for a Python codebase — the agent doesn't have to negotiate an instrumentation diff first.

**https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills**

```
Identify specific gaps in your agents' capabilities by running them on representative tasks and observing where they struggle. [...] As you work on a task with Claude, ask Claude to capture its successful approaches and common mistakes into reusable context and code within a skill. [...] Building a skill for an agent is like putting together an onboarding guide for a new hire.
```

> First-party guidance on the rule-synthesis half of the problem, and it is conditioned on *observed* struggle. That is the right gate for promoting a perf finding to a durable rule: not 'the reviewer flagged this once' but 'the implementer made this mistake repeatedly and we watched it happen.'

### Approaches (10)

- **Tool-gate + zero-impact suppression (Anthropic `web-perf` skill)** — The skill's FIRST instruction is a hard capability check: try calling the measurement tool; if it isn't there, STOP and tell the user how to install it. It never falls back to static reasoning. Everything downstream is anchored to numbers the tool returns: named Chrome DevTools insights (LCPBreakdown, CLSCulprits, RenderBlocking, DocumentLatency, NetworkRequestsDepGraph), a good/needs-improvement/poor threshold table for TTFB/FCP/LCP/INP/TBT/CLS/Speed Index, and an explicit rule that findings with 0ms estimated impact get noted but not recommended. It also grants permission to return nothing: 'A site with 200ms LCP and 0 CLS is already excellent—say so.'
  - *Reported results:* None reported — no published A/B on finding quality. But it is the only artifact I found that structurally cannot emit an unmeasured finding, because every finding shape is a field of a trace result.
  - *Source:* /Users/kyeshmz/.claude/skills/web-perf/SKILL.md
- **Two-stage generate-then-validate with a precision-over-recall gate (PostHog ReviewHog)** — Specialist perspectives (performance/reliability, logic, security) run in parallel over a PR chunk and are told to report everything without worrying about overlap. A separate final gate then re-reads the flagged code against the live codebase and returns keep/drop per finding. The gate's perf clause is narrow — 'performance problems that bite at real scale' — and it demands a nameable trigger AND consequence. Ties break toward dropping.
  - *Reported results:* None published. Structurally sound: it decouples recall (cheap, parallel, noisy) from precision (one expensive gate), which is the right shape when the generator is a confident bullshitter.
  - *Source:* /Users/kyeshmz/.claude/plugins/cache/claude-plugins-official/posthog/1.1.54/skills/review-hog-validation-criteria/SKILL.md
- **Falsifiable numeric rules + a runnable detection query (PlanetScale MySQL skill)** — Instead of 'optimize queries', the skill gives thresholds that make advice checkable: partition time-series tables >50M rows or large tables >100M rows; `type: ALL` on >1000 rows almost always needs an index; drop indexes where performance_schema `count_read = 0`; IN-lists fine to ~1000–5000 ids then chunk. The N+1 reference ships a literal SQL query against `performance_schema.events_statements_summary_by_digest ORDER BY count_star DESC` so the agent proves N+1 exists rather than inferring it from a loop. SKILL.md is short; deep material lives in reference files fetched on demand.
  - *Reported results:* None reported. Note the guardrail is explicitly stated: 'Prefer measured evidence over blanket rules of thumb.'
  - *Source:* https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/SKILL.md
- **Confidence-tiered findings where low confidence produces an investigation, not a fix (`improve` skill)** — Every finding carries Evidence (file:line), Impact (concrete: 'every order-list render issues 1+N queries', not 'suboptimal'), Effort, Risk, Confidence, Fix sketch. LOW-confidence findings are not dropped — they are downgraded: they 'get an "investigate" plan, not a "fix" plan.' Prioritization is leverage = impact ÷ effort, discounted by confidence and fix-risk. 'Not worth doing' is an allowed verdict that must be recorded with a reason. Its perf section explicitly excludes micro-optimizations and requires schema evidence before claiming a missing index.
  - *Reported results:* None reported.
  - *Source:* /Users/kyeshmz/.claude/skills/improve/references/audit-playbook.md
- **Deterministic instrument instead of wall-clock in CI (CodSpeed-style instruction counting; Bencher relative CB)** — Shared CI runners are too noisy to gate on wall-clock time. Two escapes: (a) measure something deterministic — simulated CPU / instruction counts — so the same code gives the same number every run; (b) relative continuous benchmarking, where base and PR are benchmarked back-to-back on the SAME runner in the same job so runner-to-runner variance cancels. Bencher's third option is bare-metal runners.
  - *Reported results:* Bencher states GitHub Action Runners 'can see greater than 30% variance between runs' vs 'less than 2% variance' on their bare-metal runners. This is the number that kills naive CI benchmarking.
  - *Source:* https://bencher.dev/docs/explanation/continuous-benchmarking/
- **Statistical thresholds as the regression gate (Bencher / Criterion / github-action-benchmark)** — Bencher offers static, percentage, z-score, t-test, log-normal, IQR, delta-IQR tests with upper/lower boundaries; variance-based tests need ≥2 samples and z-score works best with ≥30 historical metrics. Criterion runs a bootstrapped t-test between runs and applies a configurable noise threshold — changes within e.g. ±1% are classified as noise and ignored, with Tukey IQR outlier classification retained (not dropped) in the analysis. github-action-benchmark is the blunt version: `alert-threshold` (default 200%), `fail-on-alert: true`, `comment-on-alert`.
  - *Reported results:* No effectiveness study. These are the mechanisms; the useful output for an agent prompt is the sample-size and noise-threshold numbers, which convert 'is this a speedup?' from opinion into arithmetic.
  - *Source:* https://bencher.dev/docs/explanation/thresholds/
- **Zero-instrumentation sampling profilers as agent tools (py-spy, hyperfine)** — py-spy attaches to a running PID and produces a flamegraph or speedscope profile 'without restarting the program or modifying the code in any way', runs out-of-process in Rust, and is safe against production. That matters for an agent: it can profile without first making an edit it would then have to justify. hyperfine wraps any shell command with statistical analysis — ≥10 runs / ≥3s by default, `--warmup N`, `--prepare` to drop caches for cold-cache runs, automatic shell-spawn-time correction, `-N` for sub-5ms commands where shell overhead dominates, `--export-json` for machine-readable before/after.
  - *Reported results:* None as an agent workflow. These are the two lowest-friction ways to make an agent's perf claim empirical.
  - *Source:* https://raw.githubusercontent.com/benfred/py-spy/master/README.md
- **Profile-anchored LLM suggestions (Scalene)** — Scalene profiles CPU+GPU+memory at line granularity, then puts a lightning-bolt button on individual hot lines and an explosion button on hot regions that sends that specific profiled line/region to an LLM for an optimization proposal. The LLM is never asked 'what's slow' — the profiler answers that, and the LLM only answers 'how would you rewrite this specific hot line.'
  - *Reported results:* The README's own claim is honest and weak: 'Your mileage may vary, but in some cases, the suggestions are quite impressive (e.g., order-of-magnitude improvements).' No success rate, no measured aggregate. Treat as an existence proof of the architecture, not evidence it works.
  - *Source:* https://raw.githubusercontent.com/plasma-umass/scalene/master/README.md
- **Frontend perf budgets as compile-errors (Lighthouse CI assertions)** — Assertions are keyed by Lighthouse audit ID in eslint style: `"audit-id": ["error", {"maxNumericValue": 4000}]`, with `off`/`warn`/`error` levels where `error` produces a non-zero exit. `score`, `details.items.length`, and `numericValue` are all assertable via `minScore`/`maxLength`/`maxNumericValue`; category scores via `categories:performance`. Aggregation across runs is explicit: median / optimistic / pessimistic / median-run. Custom `performance.mark`/`performance.measure` timings can be asserted as `user-timings:<kebab-name>`.
  - *Reported results:* None reported.
  - *Source:* https://raw.githubusercontent.com/GoogleChrome/lighthouse-ci/main/docs/configuration.md
- **Skill synthesis from observed failure (Anthropic Agent Skills guidance)** — Anthropic's stated loop for durable rules: start from evaluation — 'Identify specific gaps in your agents' capabilities by running them on representative tasks and observing where they struggle' — then 'As you work on a task with Claude, ask Claude to capture its successful approaches and common mistakes into reusable context and code within a skill.' Progressive disclosure keeps the always-loaded surface small: 'When the SKILL.md file becomes unwieldy, split its content into separate files and reference them.' The framing: 'Building a skill for an agent is like putting together an onboarding guide for a new hire.'
  - *Reported results:* No quantitative results in the post. This is the only first-party guidance on the review→rule loop, and it is notably conditioned on *observed* failures, not on findings the reviewer merely asserted.
  - *Source:* https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
