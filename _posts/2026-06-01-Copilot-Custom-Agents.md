---
layout: post
read_time: true
show_date: true
title: "Custom Agents in GitHub Copilot: VS Code, CLI & Cloud"
date: 2026-06-01
img_path: /assets/img/posts/20260601
image: Museum of Etnography - Budapest.jpg
tags: [development, ai, copilot, agents, productivity]
category: ai
meta_description: "Learn how to build custom GitHub Copilot agents for VS Code, CLI, and Cloud, including orchestration, handoffs, subagents, and skills for multi-agent workflows."
---

## The problem: one agent doing everything

Picture a typical Copilot session. You ask it to add a feature. The agent searches your codebase, reads files, makes edits, runs tests, hits an error, backtracks, searches again. Forty turns in, the conversation is bloated with abandoned paths, irrelevant code snippets, and stale context.

The model starts producing worse output — not because it's less capable, but because it's [drowning in accumulated context](/posts/Reducing-Token-Usage-in-Code-Agents/). Your token budget is being spent re-reading noise from twenty turns ago rather than focusing on the current step.

Now imagine the same task split across two agents. A **Planner** researches the codebase and writes a concise plan. Then an **Implementer** — starting with a fresh, clean context — reads only that plan and the relevant files, then codes the solution. Each agent sees only what it needs. No pollution from the other's work.

That's the core idea behind custom agents: **separation of concerns at the AI layer**, the same discipline we already apply to our code.

## Your first custom agent

Every custom agent is a Markdown file: YAML frontmatter declaring capabilities, followed by a body that serves as the system prompt. No SDK, no build step, no deployment.

### Step 1: Create the file

Create a file at `.github/agents/security-reviewer.agent.md` in your repository:

```markdown
---
description: Reviews code for security vulnerabilities using OWASP Top 10 guidelines.
model: Claude Sonnet 4.6 (copilot)
tools: ['read', 'search']
---

You are a security reviewer. For every file presented, identify potential vulnerabilities
following the OWASP Top 10 taxonomy. Report findings in a structured table with severity,
location, and remediation guidance.

Do NOT modify files. Report only.
```

Three things are happening here:

- **`description`** tells the runtime (and other agents) *when* to invoke this agent.
- **`tools`** restricts what it can access — this reviewer can read and search, but cannot edit files or run commands.
- **The body** is the system prompt — its personality, instructions, and constraints.

### Step 2: Invoke it

In VS Code, open the Chat panel and select your agent from the **Agents** dropdown (it appears automatically once the file exists in your workspace). Then type your request:

> Review the authentication middleware in src/auth/ for security vulnerabilities.

In the CLI, use `@security-reviewer` inline in your prompt, the `/agent security-reviewer` command, or the `--agent security-reviewer` flag.

### Step 3: Verify it loaded

If the agent doesn't appear in VS Code's dropdown:

- Confirm the file is in `.github/agents/`, `~/.copilot/agents/`, or another recognized path.
- Confirm the filename ends in `.agent.md`.
- Check that the YAML frontmatter is valid (no tabs, proper indentation).

That's it. You have a reusable, version-controlled, team-shareable agent that anyone on the project gets on `git pull`.

### Why this beats a prompt

You could paste those same instructions into a chat message every time. But:

- Every team member would need their own copy.
- You'd waste tokens sending the instructions on every request.
- You couldn't restrict tool access — the model could still edit files.
- Changes wouldn't propagate automatically.

Custom agents solve all of this. They're infrastructure, not prompts.

## Why custom agents matter for token efficiency

If you read the [token usage post](/posts/Reducing-Token-Usage-in-Code-Agents/), you know that context size is the main cost driver in agent sessions. Custom agents directly address this:

- **Fresh context per task.** Each agent starts clean with only what it needs. No pollution from earlier conversation turns.
- **Right model, right job.** Pin o4-mini for cheap planning, Claude Sonnet 4.6 for heavy implementation. Cheaper models for cheaper tasks.
- **Tool isolation.** A read-only planner *cannot* accidentally modify files. Fewer tools in context means less noise for the model.
- **Encode knowledge once.** Domain expertise lives in the agent definition, loaded automatically — you don't re-send it on every message.

One cost tradeoff to keep in mind: splitting work across multiple agents means more total LLM interactions than a monolithic session — each agent starts its own conversation with the model. The tradeoff is usually worth it — fresh context per agent produces higher-quality output with fewer hallucinations, and parallelization cuts wall-clock time — but it's a conscious cost decision. Multi-agent architectures trade token efficiency per-request for better results overall. The overhead can also be offset by applying the [token-saving tools and context engineering techniques](/posts/Reducing-Token-Usage-in-Code-Agents/) covered in the first post of this series — RTK-AI, Graphify, Caveman, and LSP keep each agent's context lean, which directly reduces the cost per interaction.

## The three runtimes

GitHub Copilot supports custom agents across three surfaces: [**VS Code**](https://docs.github.com/en/copilot/how-tos/chat-with-copilot/get-started-with-chat-in-your-ide), the [**Copilot CLI**](https://docs.github.com/copilot/how-tos/copilot-cli), and [**Cloud**](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent). They share the `.agent.md` file format and accept agent files from `.github/agents/` or `~/.copilot/agents/`. VS Code also recognizes `.md` files in `.claude/agents/` following the [Claude sub-agents format](https://code.claude.com/docs/en/sub-agents), making it possible to share agent definitions with Claude Code.

But beyond file format, the runtimes diverge significantly in how they coordinate multiple agents.

### VS Code: explicit orchestration

VS Code gives you precise control over multi-agent coordination through:

- An `agents:` allowlist in frontmatter that declares which subagents an agent may invoke.
- Visibility controls (`user-invocable`, `disable-model-invocation`) that lock down who can call whom.
- The `agent` tool for dispatching subagents programmatically.
- Handoffs for human-in-the-loop transitions between agents.
- Platform-specific tools like `vscode/memory` (persistent memory) and `vscode/askQuestions` (structured user interaction).

VS Code also ships with built-in agents that are always available:

| Agent | User-invocable | What it does |
|-------|:--------------:|---------|
| Agent | yes | Autonomously plans and implements changes across files, runs terminal commands, and invokes tools |
| Plan | yes | Creates a structured, step-by-step implementation plan before writing any code; hands the plan off to an implementation agent when ready |
| Ask | yes | Answers questions about coding concepts, your codebase, or VS Code itself without making file changes |
| Explore | no (subagent only) | Fast read-only codebase exploration and Q&A — runs in a separate context to avoid bloating the main conversation; safe to call in parallel |

### CLI: autonomous delegation

The CLI takes a fundamentally different approach. Instead of explicit orchestrators dispatching specific agents, the CLI model **autonomously decides** when to delegate — reading each agent's `description` field and routing accordingly.

This means the `description` field does double duty: it tells humans what the agent does *and* tells the model when to invoke it. Vague descriptions like "Backend developer" won't trigger delegation. Be specific about scope and triggers.

You can also invoke agents explicitly: `@agentName` inline in your prompt, the `/agent` slash command, or the `--agent` CLI flag.

**When to use which approach:** Use autonomous delegation (good descriptions, let the model route) for simple projects with a handful of agents. Define an explicit orchestrator agent when you need deterministic sequencing — when the order of operations matters and you can't leave routing decisions to the model's judgment.

The CLI ships with built-in specialist agents it uses automatically:

| Agent | What it does |
|-------|---------|
| Explore | Quick codebase analysis without bloating the main context |
| Task | Runs commands (tests, builds); brief summaries on success, full output on failure |
| General Purpose | Handles complex, multi-step tasks requiring the full toolset; runs in a separate context |
| Code Review | Reviews changes, focuses on genuine issues, minimizes noise |
| Research | Deep research across codebase and web; produces reports with citations |
| Rubber Duck | Constructive critic on non-trivial tasks; invoked automatically |

The CLI also provides the **[`/fleet` command](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet)** — a built-in way to parallelize work without writing an orchestrator yourself. When you prefix a prompt with `/fleet`, Copilot analyzes the request, decomposes it into independent subtasks, and dispatches subagents to execute them in parallel. Each subagent gets its own fresh context window, preventing the bloat problem we discussed in the [token usage post](/posts/Reducing-Token-Usage-in-Code-Agents/).

A typical `/fleet` workflow:

1. Press Shift+Tab to enter plan mode and collaborate on an implementation plan.
2. Once the plan is complete, select **Accept plan and build on autopilot + /fleet**.
3. Copilot decomposes the plan into parallelizable subtasks and assigns subagents.
4. If you have custom agents, Copilot will route subtasks to the most appropriate one — or you can force it with `@agent-name` in your prompt.

`/fleet` is ideal for tasks that decompose naturally: creating a test suite for multiple modules, refactoring several independent files, or updating dependencies across packages. It's less useful for inherently sequential work where each step depends on the previous one.

The key tradeoff: `/fleet` is an ad-hoc command, not infrastructure committed to your repository. Unlike a custom orchestrator agent (which lives in `.github/agents/`, evolves with the codebase, and is shared via `git pull`), `/fleet` decomposition is ephemeral — the model decides how to split work on each invocation, and that logic isn't reproducible or reviewable by your team. For well-understood workflows that you want to run consistently, a committed orchestrator agent is the more disciplined choice; `/fleet` shines for exploratory or one-off parallelization.

### Cloud: fire-and-forget autonomous execution

Cloud agents run on remote infrastructure, working autonomously without real-time interaction. You assign a task and walk away. Their natural output is a pull request.

The tradeoffs:
- **No local tools.** They can't see your VS Code selections, terminal output, or local file system. Limited to cloud-configured MCP servers.
- **Asynchronous.** Progress appears in VS Code's Chat view or on GitHub.com.
- **Custom agent support.** You can select a custom agent when starting a cloud session, giving the remote agent your specialized instructions — but multi-agent coordination (subagents, squads) is not available.

You can start a cloud session through several entry points:

- **VS Code**: New Chat → Cloud, or the Agents window.
- **MCP clients**: any IDE or agentic tool that supports MCP via the GitHub MCP server ([Use Cloud Agent with MCP](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-with-mcp)).
- **CLI handoff**: a local session using the [`/delegate` command](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/delegate-tasks-to-cca).
- **GitHub.com repository UI**: the Agents tab or assign an issue/PR to the Copilot cloud agent.

The handoff pattern is powerful: use a local Plan agent to interactively clarify requirements, then hand off to a cloud agent for autonomous implementation. The cloud agent receives the entire conversation history as context.

### Platform comparison

Now that you've seen each runtime in action, here's the full comparison:

| Feature | VS Code | CLI | Cloud |
|---------|---------|-----|-------|
| Multi-agent coordination | Orchestrator pattern + handoffs | Explicit + autonomous delegation | Single agent per session |
| Subagent invocation | `agent`/`runSubagent` tool + `agents:` allowlist | `task` tool, `/agent` command, `/fleet`, or auto-delegation | Not available |
| Memory handoff | `vscode/memory` tool | File system | PR context + repository |
| User interaction | `vscode/askQuestions` tool | `ask_user` tool | Asynchronous (PR comments) |
| Terminal/shell execution | `execute/runInTerminal` tool | Shell commands via tool approval | Sandboxed environment |
| Skill loading | Automatic (from multiple paths) | Loaded when task matches description | Not available |
| Model pinning | `model:` frontmatter | `model:` frontmatter or `--model` flag | Selected at session start |
| MCP tools | `<server>/*` tool pattern | `<server>/*` tool pattern | Cloud-configured MCP servers only |
| Visibility control | `user-invocable` + `disable-model-invocation` | Same properties | N/A |
| Organization sharing | `.github-private` repo | `.github-private` repo | `.github-private` repo |
| Execution environment | Local machine | Local machine | Remote infrastructure |

## Building a two-agent workflow (VS Code)

Let's build something practical: a Planner that researches and writes a plan, followed by an Implementer that codes the solution. This is the simplest useful multi-agent setup.

### The Planner

```markdown
---
name: Planner
description: Researches the codebase and writes a concrete implementation plan.
model: o4-mini (copilot)
target: vscode
tools: ['search', 'read', 'vscode/memory']
handoffs:
  - label: Start Implementation
    agent: Implementer
    prompt: Implement the plan in /memories/session/plan.md
    send: false
---

You are the Planner. Your job is to research the codebase and produce a plan.

## Protocol
1. Understand the user's request
2. Explore relevant files using search and read
3. Write your plan to `/memories/session/plan.md`
4. Never write production code — only the plan
```

### The Implementer

```markdown
---
name: Implementer
description: Implements code changes following a plan written by the Planner.
model: Claude Sonnet 4.6 (copilot)
target: vscode
tools: ['search', 'read', 'edit', 'run_in_terminal', 'vscode/memory']
---

You are the Implementer. Follow the plan exactly.

## Protocol
1. Read the plan from `/memories/session/plan.md`
2. Implement each step
3. Run tests after changes
4. Report completion
```

Notice the model split: the Planner uses `o4-mini` (cheap reasoning, good for exploration) while the Implementer uses `Claude Sonnet 4.6` (strong at code generation). Each model does what it's best at, and you pay less for the planning phase.

The `handoffs:` property on the Planner creates a button that appears after the plan is generated. Click it to switch to the Implementer with a pre-filled prompt. Since `send: false`, you get to review the prompt before it submits — a human checkpoint in the pipeline.

### Visibility controls explained

By default, **any agent can invoke any other agent** in VS Code. The visibility controls let you lock this down:

- **`user-invocable: false`** — the developer cannot select this agent from the dropdown; only other agents can invoke it.
- **`disable-model-invocation: true`** — no agent can invoke this one *unless* it explicitly lists it in its `agents:` allowlist.

When combined, these create a strict hierarchy: only agents that declare a specific subagent in their `agents:` array can call it. This prevents accidental invocations and makes the coordination graph explicit and auditable.

The `model:` field can also accept a prioritized array — the runtime tries each in order until an available one is found. One constraint: a subagent's requested model cannot exceed the cost tier of the main model; if it does, the subagent falls back to the main model.

## Handoffs vs. subagents: choosing the right coordination

You now have two ways to connect agents:

**Handoffs** insert a human checkpoint between steps. After one agent finishes, a button appears. You review the output, optionally edit the pre-filled prompt, then click to continue. Use handoffs when:
- The intermediate output needs human review (plans, architectural decisions).
- You want to abort early if the plan is wrong.
- The workflow is high-stakes or unfamiliar.

**Subagent orchestration** is fully autonomous. An Orchestrator agent dispatches subagents via the `agent` tool without pausing. Use subagents when:
- The workflow is repetitive and well-understood.
- You trust the pipeline and don't need to inspect intermediate steps.
- Speed matters more than oversight.

To define handoffs, add them to the agent's frontmatter:

```markdown
---
description: Generate an implementation plan
tools: ['search', 'read']
handoffs:
  - label: Start Implementation
    agent: implementation
    prompt: Now implement the plan outlined above.
    send: false
    model: GPT-4.1 (copilot)
---

You are a planning agent. Research the codebase and produce a step-by-step plan.
```

When `send: true`, the prompt auto-submits without confirmation. The optional `model` field switches models at the transition point.

## Squads: orchestrated teams (VS Code)

Once you're comfortable with two-agent workflows, you can scale up to full **squads** — coordinated teams with an Orchestrator as the single entry point.

```text
                         ┌──────────────┐
                         │     User     │
                         └──────┬───────┘
                                │
                         ┌──────▼───────┐
                         │ Orchestrator │
                         └──┬───┬───┬───┘
                ┌───────────┘   │   └───────────┐
                │               │               │
         ┌──────▼──────┐ ┌─────▼──────┐ ┌──────▼───────┐
         │   Planner   │ │ Backend Dev│ │ Code Reviewer│
         └──────┬──────┘ └─────┬──────┘ └─────────────┘
                │               │
                │  writes plan  │ reads plan
                ▼               ▼
         ┌────────────┐
         │  Session   │
         │  Memory    │
         └────────────┘
```

Each role has a clear responsibility. The Orchestrator routes tasks but never edits files. The Planner researches but never writes production code. Specialists implement. Code Reviewers critique.

### Naming convention

To avoid naming clashes when a project has multiple squads, all agents in a squad share a short prefix:

- `mod-Orchestrator.agent.md`
- `mod-Planner.agent.md`
- `mod-BackendFixer.agent.md`
- `mod-Verifier.agent.md`

A documentation squad might use `doc-Orchestrator.agent.md`, `doc-Writer.agent.md`, etc. Memory files follow the same convention: `/memories/session/mod-plan.md`, `/memories/session/doc-outline.md`.

### Orchestrator example

```markdown
---
name: mod-Orchestrator
description: Routes legacy modernization tasks to specialist agents.
model: o4-mini (copilot)
target: vscode
tools: ['search', 'read', 'vscode/memory', 'agent']
agents: ['mod-Planner', 'mod-BackendFixer', 'mod-Verifier']
user-invocable: true
---

You are the Modernization Orchestrator. You coordinate the team but never write code.

## Protocol
1. Write the task brief to `/memories/session/mod-task-brief.md`
2. Invoke mod-Planner to research and plan
3. Invoke mod-BackendFixer to implement
4. Invoke mod-Verifier to validate
5. Report results to the user
```

The `agents:` allowlist declares which subagents this Orchestrator may invoke — without it, the `agent` tool could call any agent in the workspace. The Orchestrator is the only squad member with `user-invocable: true`; all others use `disable-model-invocation: true`, creating a controlled hierarchy.

## CLI: simulating squads with the task tool

The CLI supports **plan mode** (Shift+Tab) where it builds a structured implementation plan before writing code. In plan mode, the CLI may delegate individual plan steps to different agents — achieving something like VS Code's squad pattern, but driven by the model's judgment.

You can also define an explicit orchestrator in the CLI. The `task` tool spawns a fresh context for each subtask — the CLI equivalent of VS Code's `agent` tool:

```markdown
---
description: Orchestrates multi-step tasks by delegating to subagents with
  appropriate models. Use for complex tasks that benefit from specialized roles.
model: Claude Sonnet 4.6 (copilot)
tools: ['read', 'shell', 'ask_user', 'task', 'skill']
---

You are an orchestrator. You never write code directly — you delegate via the `task` tool.

## Protocol
1. Analyze the task and break it into subtasks.
2. For each independent subtask, dispatch a `task` with:
   - A detailed prompt describing exactly what to do.
   - The `model` field set to the most appropriate model for the job
     (e.g. "o4-mini (copilot)" for planning, "Claude Sonnet 4.6 (copilot)" for implementation).
3. Independent tasks CAN be dispatched in parallel.
4. Synthesize results and report back to the user.
```

Unlike VS Code (where model selection is static per agent definition), the CLI allows specifying the model at invocation time — you can reuse the same agent with different models dynamically.

## Skills: keeping agent files lean

When an agent needs deep domain knowledge (API patterns, validation rules, output templates), putting everything in the agent body wastes context tokens on every invocation — even when that knowledge isn't relevant to the current step.

Skills solve this by externalizing reference material into separate files that are loaded on demand. The agent body defines the *protocol* (what steps to follow); the skill contains the *reference material* (templates, checklists, examples). For a deeper dive into skills as a concept, see [post #3 in this series](/posts/The-Architecture-of-Code-Agents-Instructions-Skills-Agents-Hooks/).

VS Code searches for skills in several default locations (configurable via `chat.agentSkillsLocations`):

| Scope | Path |
|-------|------|
| Workspace | `.agents/skills/`, `.github/skills/`, `.claude/skills/` |
| User | `~/.agents/skills/`, `~/.copilot/skills/`, `~/.claude/skills/` |

Each path should contain skill subfolders with a `SKILL.md` file inside, e.g., `.agents/skills/security-review/SKILL.md`. This pattern keeps agent definitions to 50–100 lines while skills can contain hundreds of lines of domain knowledge — loaded only when needed.

## Sharing agents and skills across teams

Custom agents and skills can be shared at multiple levels:

| Scope | Agents location | Skills location | Available to |
|-------|----------------|-----------------|-------------|
| User | `~/.copilot/agents/` | `~/.copilot/skills/` or `~/.agents/skills/` | All projects on your machine |
| Repository | `.github/agents/` | `.github/skills/`, `.claude/skills/`, or `.agents/skills/` | Current project |
| Organization / Enterprise | `/agents/` in the `.github-private` repo | `/skills/` in the `.github-private` repo | All projects under the org or enterprise |

In VS Code, enabling `github.copilot.chat.organizationCustomAgents.enabled` makes organization-level agents appear in the Agents dropdown. The organization tier is powerful for standardization: a platform team can ship shared agents that every project inherits automatically. For versioned dependency management of these configurations, see [APM](/posts/APM-Package-Management-for-AI-Agent-Configuration/).

## Decision guide

```text
              Need a custom agent?
                      │
            Single focused task?
              /              \
           Yes                No
            │                  │
  Create one .agent.md    Which platform?
                        /    |    |       \
                VS Code   CLI  Cloud   Cross-platform
                  │        │     │          │
         Human review   Define  Well-defined  MCP tools +
          at each step? agents   scope + all   shared files
           /       \    w/good  context in repo?
         Yes       No   desc.    /        \
          │         │     │    Yes         No
       Handoffs  Orchestrator  │           │
                 + subagents Cloud agent  Start local,
          │         │     │     │      hand off to cloud
          └─────────┴─────┴─────┴──────────┘
                          │
              Pin optimal model per role
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Agent doesn't appear in VS Code dropdown | Wrong file location or extension | Ensure file is in `.github/agents/` and named `*.agent.md` |
| Agent appears but never gets invoked by other agents | Vague `description` field | Make description specific about scope and triggers |
| Subagent silently uses a different model than requested | Cost tier exceeded | A subagent can't request a model more expensive than the parent; check the parent's model tier |
| CLI ignores your agent | Missing or ambiguous `description` | The CLI routes based on description quality; add explicit trigger phrases |
| `disable-model-invocation` seems to have no effect | No other agents are trying to invoke it | This property only matters when other agents exist; without it, any agent with the `agent` tool can invoke yours |
| Cloud session can't use your squad | Multi-agent not supported in cloud | Cloud supports single custom agents only; use local for multi-agent, then hand off the result |
| Agent loads but produces poor output | Too many tools in context | Restrict `tools:` to only what the agent actually needs |

## Advanced: parallel subagents and adversarial review

VS Code can run subagents in parallel. The most compelling use case is **adversarial review**: dispatching multiple independent critics that approach the code fresh, without being anchored by each other's findings.

```markdown
---
name: Thorough Reviewer
tools: ['agent', 'read', 'search']
---
You review code through multiple perspectives simultaneously. Run each perspective
as a parallel subagent so findings are independent and unbiased.

When asked to review code, run these subagents in parallel:
- Correctness reviewer: logic errors, edge cases, type issues.
- Code quality reviewer: readability, naming, duplication.
- Security reviewer: input validation, injection risks, data exposure.
- Architecture reviewer: codebase patterns, design consistency.

After all subagents complete, synthesize findings into a prioritized summary.
```

> **Important**: By default, subagents cannot spawn further subagents — this prevents infinite recursion. To enable nested delegation, set `chat.subagents.allowInvocationsFromSubagents` to `true` in VS Code settings. When enabled, subagents can spawn their own subagents up to a maximum nesting depth of 5.

### The review tribunal pattern

The recommended pattern for high-quality review uses a **review tribunal** — three agents forming a complete review stage:

| Agent | Role | Key constraint |
|-------|------|----------------|
| `<prefix>-ReviewerA` | Independent reviewer #1 | Writes findings to its own output file |
| `<prefix>-ReviewerB` | Independent reviewer #2 | Writes findings to its own output file |
| `<prefix>-CodeReviewer` | Merge arbiter | Invokes both in parallel, deduplicates, merges, classifies severity |

The critical constraint: **ReviewerA and ReviewerB must use models from two different vendor families** (e.g., Claude vs GPT, GPT vs Gemini). Same-family models share blind spots, defeating the purpose.

```text
  ┌──────────────┐
  │ Orchestrator │
  └──────┬───────┘
         │ invoke
  ┌──────▼───────┐
  │ CodeReviewer │
  └───┬──────┬───┘
      │      │  parallel
┌─────▼───┐ ┌▼────────┐
│ReviewerA│ │ReviewerB │
│ (GPT)   │ │ (Claude) │
└────┬────┘ └────┬─────┘
     │ writes    │ writes
     ▼           ▼
┌──────────┐ ┌──────────┐
│reviewerA-│ │reviewerB-│
│output.md │ │output.md │
└─────┬────┘ └────┬─────┘
      └─────┬─────┘
            │ reads both, merges
     ┌──────▼──────┐
     │review-output│
     │    .md      │
     └─────────────┘
```

The workflow:

1. **The Orchestrator invokes CodeReviewer** (never the individual reviewers directly).
2. **CodeReviewer invokes ReviewerA and ReviewerB in parallel.** Neither sees the other's output.
3. **CodeReviewer reads both output files**, deduplicates, merges, and classifies severity (CRITICAL / HIGH / MEDIUM / LOW).
4. **The Orchestrator reads the merged report** and loops back to specialists for fixes if needed.

### Rubber Duck in the CLI

The CLI takes a different approach. Rather than requiring explicit adversarial agents, it includes a built-in [**Rubber Duck**](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/rubber-duck) agent that acts as a constructive critic automatically. On non-trivial tasks, the CLI silently consults the Rubber Duck before finalizing its response — challenging assumptions and flagging potential issues without any configuration on your part.

## Conclusion

The core principle is the same across all three platforms: **divide work into focused contexts, assign the right model to each, and pass only necessary context between steps.**

In VS Code, you achieve this through explicit orchestration — the `agents:` allowlist, handoffs, and subagent invocation give you precise control. In the CLI, the model takes a more autonomous approach, delegating based on descriptions. In the Cloud, agents work independently on well-scoped tasks and deliver pull requests.

Start simple: one custom agent that solves a real pain point. Verify it works. Then add a second agent and coordinate them. Build complexity gradually — the same way you'd build any other system.

One caveat: despite sharing the `.agent.md` format, VS Code, the CLI, and Cloud are developed by independent teams at GitHub and Microsoft. Frontmatter properties like `target`, tool names, and coordination mechanisms don't always translate across platforms. A squad that works perfectly in VS Code won't automatically run in the CLI without adjustments. Hopefully, as the ecosystem matures, these runtimes will converge — but for now, be prepared to maintain platform-specific variants when needed.
