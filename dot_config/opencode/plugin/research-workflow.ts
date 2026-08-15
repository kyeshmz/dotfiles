import { createHash } from "node:crypto"
import { mkdir, readdir, readFile, rename, writeFile } from "node:fs/promises"
import { basename, join, resolve, sep } from "node:path"
import { tool, type Plugin } from "@opencode-ai/plugin"

const stages = ["planned", "collecting", "verifying", "synthesizing", "auditing", "complete", "blocked"] as const
type Stage = (typeof stages)[number]

type Manifest = {
  run_id: string
  status: Stage
  created_at: string
  question: string
  evidence_revision: number
  evidence_fingerprint: string
  synthesis_revisions: number
}

const transitions: Record<Stage, Stage[]> = {
  planned: ["collecting", "blocked"],
  collecting: ["verifying", "blocked"],
  verifying: ["collecting", "synthesizing", "blocked"],
  synthesizing: ["auditing", "blocked"],
  auditing: ["synthesizing", "complete", "blocked"],
  complete: [],
  blocked: ["collecting", "verifying"],
}

function slugify(value: string) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 48) || "research"
}

function manifestText(value: Manifest) {
  return `---\nrun_id: ${value.run_id}\nstatus: ${value.status}\ncreated_at: ${value.created_at}\nquestion: ${JSON.stringify(value.question)}\nevidence_revision: ${value.evidence_revision}\nevidence_fingerprint: ${JSON.stringify(value.evidence_fingerprint)}\nsynthesis_revisions: ${value.synthesis_revisions}\n---\n\n# Research Run\n\nThis file is managed by the OpenCode research workflow.\n`
}

function parseManifest(text: string): Manifest {
  const field = (name: string) => text.match(new RegExp(`^${name}:\\s*(.+)$`, "m"))?.[1]?.trim()
  const status = field("status") as Stage
  if (!stages.includes(status)) throw new Error("manifest.md has an invalid status")
  return {
    run_id: field("run_id") || "",
    status,
    created_at: field("created_at") || "",
    question: JSON.parse(field("question") || '""'),
    evidence_revision: Number(field("evidence_revision") || 0),
    evidence_fingerprint: JSON.parse(field("evidence_fingerprint") || '""'),
    synthesis_revisions: Number(field("synthesis_revisions") || 0),
  }
}

// Agents decorate these lines as markdown (`**verified_revision:** 1`, `- PASS`), so the
// key/verdict markers tolerate list bullets and emphasis rather than deadlocking the run.
function marker(key: string) {
  return new RegExp(`^[-*\\s]*\\*{0,2}${key}\\*{0,2}\\s*:\\s*\\*{0,2}\\s*(\\d+)`, "mi")
}

function verdict(token: string) {
  return new RegExp(`^[-*\\s>]*\\*{0,2}\\s*${token}\\s*\\*{0,2}[.!]?\\s*$`, "m")
}

// websearch only exists when the opencode provider is active or OPENCODE_ENABLE_EXA is
// truthy. Scouts are search-first, so a run started without it quietly collects nothing:
// the agent reports "no websearch tool", which reads like a denial rather than a missing
// capability. Surface it before any scout is dispatched. Warning, not a hard gate,
// because the opencode provider enables the tool without the variable.
function websearchWarning() {
  const value = (process.env["OPENCODE_ENABLE_EXA"] || "").toLowerCase()
  if (value && value !== "0" && value !== "false") return undefined
  return "OPENCODE_ENABLE_EXA is not set, so the websearch tool almost certainly does not exist and scouts cannot search. Unless this session runs on the opencode provider, stop before dispatching scouts and have the user export OPENCODE_ENABLE_EXA=1 (the managed ~/.zshrc block sets it; a stale shell will not have it)."
}

function runPath(directory: string, input: string) {
  const root = resolve(directory, ".research")
  const target = resolve(directory, input)
  if (target !== root && !target.startsWith(`${root}${sep}`)) {
    throw new Error("run_dir must be inside the current project's .research directory")
  }
  return target
}

async function readManifest(run: string) {
  return parseManifest(await readFile(join(run, "manifest.md"), "utf8"))
}

async function writeManifest(run: string, manifest: Manifest) {
  const path = join(run, "manifest.md")
  const temporary = `${path}.${process.pid}.tmp`
  await writeFile(temporary, manifestText(manifest))
  await rename(temporary, path)
}

async function evidenceFingerprint(run: string) {
  const directory = join(run, "evidence")
  const files = (await readdir(directory)).filter((file) => file.endsWith(".md")).sort()
  const hash = createHash("sha256")
  for (const file of files) {
    hash.update(file)
    hash.update(await readFile(join(directory, file)))
  }
  return { files, value: hash.digest("hex") }
}

async function inspect(run: string) {
  const manifest = await readManifest(run)
  const issues: string[] = []
  const requiredFiles = ["brief.md", "coverage.md", "contradictions.md"]
  for (const file of requiredFiles) {
    try {
      const text = await readFile(join(run, file), "utf8")
      if (text.includes("TODO")) issues.push(`${file} still contains TODO fields`)
    } catch {
      issues.push(`${file} is missing`)
    }
  }
  const evidence = await evidenceFingerprint(run)
  if (manifest.status !== "planned" && evidence.files.length === 0) issues.push("no evidence cards exist")
  return { manifest, evidence, issues }
}

async function requireFile(run: string, file: string) {
  try {
    return await readFile(join(run, file), "utf8")
  } catch {
    throw new Error(`${file} is required for this transition`)
  }
}

const ResearchWorkflowPlugin: Plugin = async () => ({
  tool: {
    research_workflow_init: tool({
      description: "Initialize a unique, durable research run and its artifact templates. Call once before research begins.",
      args: {
        slug: tool.schema.string().min(1).describe("Short topic slug"),
        question: tool.schema.string().min(1).describe("Exact research question"),
      },
      async execute({ slug, question }, context) {
        const stamp = new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z")
        const topic = join(context.directory, ".research", slugify(slug))
        const run = join(topic, stamp)
        await mkdir(topic, { recursive: true })
        await mkdir(run)
        await mkdir(join(run, "evidence"))
        const manifest: Manifest = {
          run_id: `${slugify(slug)}-${stamp}`,
          status: "planned",
          created_at: new Date().toISOString(),
          question,
          evidence_revision: 0,
          evidence_fingerprint: "",
          synthesis_revisions: 0,
        }
        await writeManifest(run, manifest)
        await writeFile(join(run, "brief.md"), `# Research Brief\n\n- Question: ${question}\n- Run date: ${manifest.created_at.slice(0, 10)}\n- Question type: TODO\n- Audience: TODO\n- Decision or thesis: TODO\n- Supporting evidence would show: TODO\n- Weakening evidence would show: TODO\n- Criteria and vetoes: TODO\n- Scope and exclusions: TODO\n- Freshness cutoff: TODO\n- Required source types: TODO\n- Budget: TODO\n- Stopping conditions: TODO\n`)
        await writeFile(join(run, "coverage.md"), "# Coverage\n\n| ID | Required question or criterion | Required | Owner | Status | Claims | Counterevidence | Thesis relation |\n| --- | --- | --- | --- | --- | --- | --- | --- |\n| Q01 | TODO | yes | TODO | unassigned | - | - | unknown |\n")
        await writeFile(join(run, "contradictions.md"), "# Contradictions\n\nNo contradictions recorded. Replace this line when adding the first `Xnn` entry.\n")
        const warning = websearchWarning()
        return `${warning ? `WARNING: ${warning}\n\n` : ""}Initialized ${run}. Complete brief.md and coverage.md before advancing to collecting.`
      },
    }),
    research_workflow_check: tool({
      description: "Inspect a research run's durable state and report structural or freshness problems.",
      args: { run_dir: tool.schema.string().min(1).describe("Run directory inside .research") },
      async execute({ run_dir }, context) {
        const run = runPath(context.directory, run_dir)
        const result = await inspect(run)
        const warnings = [websearchWarning()].filter(Boolean)
        return JSON.stringify({ run_dir: run, status: result.manifest.status, evidence_revision: result.manifest.evidence_revision, evidence_cards: result.evidence.files, issues: result.issues, warnings }, null, 2)
      },
    }),
    research_workflow_advance: tool({
      description: "Advance a research run only when the next stage's deterministic artifact prerequisites pass.",
      args: {
        run_dir: tool.schema.string().min(1).describe("Run directory inside .research"),
        target: tool.schema.enum(stages).describe("Target workflow stage"),
      },
      async execute({ run_dir, target }, context) {
        const run = runPath(context.directory, run_dir)
        const { manifest, evidence, issues } = await inspect(run)
        if (!transitions[manifest.status].includes(target)) throw new Error(`invalid transition: ${manifest.status} -> ${target}`)
        if (target === "collecting" && manifest.status === "planned" && issues.length) throw new Error(issues.join("; "))
        if (target === "verifying") {
          if (!evidence.files.length) throw new Error("at least one evidence card is required")
          const coverage = await requireFile(run, "coverage.md")
          if (/\|\s*(unassigned|researching|gap)\s*\|/i.test(coverage)) throw new Error("required coverage remains unassigned, researching, or gap")
          if (evidence.value !== manifest.evidence_fingerprint) {
            manifest.evidence_revision += 1
            manifest.evidence_fingerprint = evidence.value
          }
        }
        if (target === "synthesizing") {
          const verification = await requireFile(run, "verification.md")
          const revision = Number(verification.match(marker("verified_revision"))?.[1] || -1)
          if (revision !== manifest.evidence_revision) throw new Error(`verification is stale: expected evidence revision ${manifest.evidence_revision}`)
          const coverage = await requireFile(run, "coverage.md")
          if (/\|\s*(unassigned|researching|evidence-found|gap)\s*\|/i.test(coverage)) throw new Error("required coverage is not resolved")
          if (manifest.status === "auditing") {
            if (manifest.synthesis_revisions >= 1) throw new Error("the single synthesis revision has already been used")
            manifest.synthesis_revisions += 1
          }
        }
        if (target === "auditing") await requireFile(run, "report.md")
        if (target === "complete") {
          const audit = await requireFile(run, "report-audit.md")
          if (!verdict("PASS").test(audit)) throw new Error("report-audit.md does not contain a PASS verdict")
        }
        manifest.status = target
        await writeManifest(run, manifest)
        return `Advanced ${basename(run)} to ${target}.`
      },
    }),
  },
})

export default ResearchWorkflowPlugin
