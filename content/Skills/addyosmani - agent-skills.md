---
Type: "[[§ Skill]]"
publish: true
URL: https://github.com/addyosmani/agent-skills
Owner: Addy Osmani
Domain: Software engineering / coding agents
Status: To Review
Comments:
---

**Production-grade engineering skills for AI coding agents** (Claude, Cursor, Gemini CLI, etc.) — encodes the disciplined practices senior engineers use across the full development lifecycle, so agents follow consistent quality standards instead of skipping testing, security, or docs. Markdown-based, tool-agnostic, MIT-licensed.

**24 skills by lifecycle phase:**
- **Define** — interview-me, idea-refine, spec-driven-development
- **Plan** — planning-and-task-breakdown
- **Build** — incremental-implementation, test-driven-development, context-engineering, source-driven-development, doubt-driven-development, frontend-ui-engineering, api-and-interface-design
- **Verify** — browser-testing-with-devtools, debugging-and-error-recovery
- **Review** — code-review-and-quality, code-simplification, security-and-hardening, performance-optimization
- **Ship** — git-workflow-and-versioning, ci-cd-and-automation, deprecation-and-migration, documentation-and-adrs, observability-and-instrumentation, shipping-and-launch
- **Meta** — using-agent-skills

Also bundles 4 specialist agent personas (code-reviewer, test-engineer, security-auditor, web-performance-auditor), 5 reference checklists, and 8 slash commands.

## Comparison vs. alternatives

From the repo's own [comparison doc](https://github.com/addyosmani/agent-skills/blob/main/docs/comparison.md), which weighs it against [[obra - superpowers]] and Matt Pocock's skills:

| Dimension | agent-skills | Superpowers | Matt Pocock |
|---|---|---|---|
| **Focus** | Full product lifecycle phases | Autonomous reasoning loops | Daily practical workflow |
| **Entry points** | Phase commands (`/spec`, `/plan`, `/build`, `/test`, `/review`, `/ship`) | Brainstorm → execute flow | TDD + requirement interrogation |
| **Distinctive** | Anti-rationalization tables, review personas, parallel validation | Subagent isolation, two-stage review, git-worktree separation | Strict agent-level TDD, pre-commit guards |

- **agent-skills** — guided lifecycle with human checkpoints per phase; parallel review/security/perf passes.
- **Superpowers** — long autonomous stretches and exploratory work; heavy upfront reasoning.
- **Guidance:** "pick the tool to the task" — none is universally better. **Don't stack multiple frameworks as routers at once** — they cause command conflicts.

Tracked alternative: [[obra - superpowers]]. I intend to test both and record my verdict in **Comments**.

#ai-generated
