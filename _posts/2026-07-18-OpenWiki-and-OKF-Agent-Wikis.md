---
layout: post
read_time: true
show_date: true
title: "OpenWiki and OKF: Agent-Readable Code Wikis"
date: 2026-07-18
media_subpath: /assets/img/posts/20260718
image:
  path: hangers.webp
tags: [ai, agents, openwiki, okf, wiki, copilot, claude code]
category: ai
meta_description: "How OpenWiki generates OKF v0.1 wikis for agents from your codebase — init, CI auto-updates, inference providers, and the personal brain mode."
---

Documenting a codebase has always been hard. Writing good documentation takes time, and keeping it current as the code evolves takes discipline that most teams cannot consistently sustain. The result is the familiar pattern: documentation that starts accurate, drifts, contradicts the code, and eventually gets ignored altogether.

Coding agents change this. An agent can read source files, infer intent, summarize modules, and write concept documents faster than any human team. For the first time, keeping documentation current is genuinely tractable — run a command, get a wiki, automate the refresh in CI.

But this creates a new problem in the opposite direction.

Agents are good at producing documentation. If left unconstrained, they produce a lot of it. A large codebase generates a large wiki — dozens or hundreds of files, each accurate in isolation, but collectively too large for an agent to load at once. As I covered in [Knowledge Graph Tools for AI Code Agents](/posts/Code-Agent-Knowledge-Graphs/), dumping a large number of files into an agent's context is one of the most common ways to waste tokens and degrade output quality. The agent either reads everything and runs out of context, or reads a subset and misses what matters.

The documentation layer has to be navigable. An agent needs to find the right two pages without loading the other forty. A human needs to browse it without tooling. Both consumers need the same artifact — and that only works if the format is designed for both from the start.

That is exactly the gap that [OpenWiki](https://github.com/langchain-ai/openwiki) and the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) address together. OpenWiki generates structured, hierarchical OKF wikis from your codebase, keeps them current automatically, and wires them into your agent configuration so every session starts with the index in reach rather than the raw source files.

This post explains what OpenWiki produces, what format it uses, how agents discover and consume the output, and how to keep everything current with minimal effort.

## The Problem with AGENTS.md Alone

`AGENTS.md` and `CLAUDE.md` are the right place for project-wide conventions: build commands, testing instructions, file structure rules, coding standards. They are short, stable, and high-signal. As I described in [From Hero Prompts to Shared AI Infrastructure](/posts/From-Hero-Prompts-to-Shared-AI-Infrastructure/), the goal is to move durable knowledge out of one-off prompts and into versioned project assets.

The problem comes when you try to put too much into them — and the consequences are worse than they first appear.

`AGENTS.md` is not a reference document that agents look up when needed. It is injected into the context window at the start of every session, unconditionally. Every line in it costs tokens on every task, regardless of whether those tokens are relevant to what the agent is doing right now. A bloated `AGENTS.md` is not just hard to maintain — it silently taxes every agent session that runs against your repository.

As the codebase grows, there are more modules to describe, more API contracts to document, more architectural decisions to record. An `AGENTS.md` that tries to capture all of this becomes a direct, per-session token drain: documentation about the payments module burns context on a task that only touches the auth module, documentation about deployment burns context on a refactor, and so on. The cost compounds across every session, every day, every developer.

The correct architecture is a separation of concerns:

- `AGENTS.md` stays short: build commands, testing conventions, coding standards, file organization.
- The wiki handles the rest: module-level descriptions, cross-cutting concepts, API surfaces, ADRs.

`AGENTS.md` then points at the wiki. The agent reads the index, navigates to what is relevant for the current task, and ignores everything else.

## OKF: The Format Underneath

[Open Knowledge Format (OKF) v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) is a minimal standard from Google for agent-readable knowledge bundles. Its design principle is intentional: the format standardizes only what is needed for a corpus to be self-describing. Everything beyond that is left to the producer.

In practice, an OKF bundle is a directory of markdown files with YAML frontmatter. No tooling required to read it. No schema registry. No central authority. If you can `cat` a file, you can read OKF; if you can `git clone` a repo, you can ship it.

### Concept documents

Every file in the bundle is a concept document — one unit of knowledge. The only requirement is a YAML frontmatter block with a non-empty `type` field:

```yaml
---
type: Module
title: Authentication
description: Handles JWT issuance, validation, and refresh for all API clients.
tags: [auth, security]
timestamp: 2026-07-15T10:00:00Z
---

The `auth` module is the single entry point for all authentication flows. It issues
short-lived JWTs on login, validates them on every protected route via middleware,
and handles refresh via a sliding window.

See [User model](/models/user.md) for the claims structure.
```

The `type` value is not centrally registered — producers choose their own. Consumers are required to tolerate unknown types. This keeps the format useful across codebases without requiring coordination.

The recommended frontmatter fields — `title`, `description`, `tags`, `timestamp` — are optional. Consumers that need a title when it is absent may derive one from the filename.

### Reserved files

Two filenames have defined meaning at any level of the hierarchy:

- **`index.md`** — a directory listing. No frontmatter. Lists the concepts in that directory with their descriptions. Used for progressive disclosure: an agent (or human) can see what is available before opening individual documents.
- **`log.md`** — a chronological update history. Records what changed and when, newest entries first.

Everything else is a concept document.

### Cross-links

Standard markdown links between concept documents express relationships:

```markdown
See [User model](/models/user.md) for the claims structure.
Depends on [Token store](/services/token-store.md).
```

A link from A to B asserts a relationship. The semantics are in the surrounding prose, not the link itself. OKF does not prescribe edge types — consumers that build graph views treat all links as directed edges of an untyped relationship. Broken links are tolerated; a link whose target does not exist is not malformed, it may simply represent not-yet-written knowledge.

### Bundle structure

A conformant bundle is a directory tree:

```
bundle/
├── index.md              # root listing, declares okf_version: "0.1"
├── log.md                # root update history
├── modules/
│   ├── index.md
│   ├── auth.md
│   └── payments.md
└── models/
    ├── index.md
    └── user.md
```

The bundle can be distributed as a git repository (recommended — provides history and diffs), a subdirectory within a larger repo, or a tarball.

### Why OKF matters

The value of a standard format is interoperability. When every wiki generator emits the same structure, every agent can consume any wiki without bespoke adapters. OKF is also committed-to-git-friendly: diffs are meaningful, history is traceable, and the wiki lives alongside the code it describes.

OKF's conformance rules are intentionally permissive. A bundle is conformant if every non-reserved `.md` file has a parseable YAML frontmatter block with a non-empty `type` field. Everything else is guidance, not a requirement. This keeps the format useful as bundles grow and get partially generated by agents.

## OpenWiki: Generating OKF from Your Codebase

[OpenWiki](https://github.com/langchain-ai/openwiki) (12k+ stars, MIT, LangChain AI) is a CLI that generates and maintains OKF bundles for codebases. It scans your repository with LLM inference, writes concept documents to `openwiki/`, and auto-updates `AGENTS.md` and `CLAUDE.md` to point agents at the wiki.

### Install

```bash
npm install -g openwiki
```

### Initial generation

```bash
openwiki --init
```

The first run prompts for an inference provider and model, saves credentials to `~/.openwiki/.env`, and generates the initial wiki. After generation:

1. `openwiki/` contains OKF v0.1 concept documents.
2. `openwiki/INSTRUCTIONS.md` is created — a user-authored brief for scope and priorities. This file is never rewritten on subsequent runs; edit it to guide future generations.
3. `AGENTS.md` and `CLAUDE.md` at the repo root are updated with an `<!-- OPENWIKI:START -->…<!-- OPENWIKI:END -->` block that instructs agents to consult `openwiki/` when searching for context. Any content outside that block is left untouched.

The injection pattern is important. On every run, OpenWiki rewrites only its own block. Your existing `AGENTS.md` conventions — build commands, coding standards, tool restrictions — survive intact. The wiki reference is appended the first time and refreshed on subsequent runs.

### What gets generated

For a typical web API project, `openwiki/` might look like:

```
openwiki/
├── index.md
├── log.md
├── INSTRUCTIONS.md
├── modules/
│   ├── index.md
│   ├── auth.md
│   ├── payments.md
│   └── notifications.md
├── models/
│   ├── index.md
│   └── user.md
└── api/
    ├── index.md
    └── endpoints.md
```

Each concept document covers module purpose, public API surface, key dependencies, and cross-cutting concerns. The structure reflects the codebase organization. Cross-links connect related concepts.

### Keeping it current

```bash
openwiki --update
```

Update reads git diffs since the last run, rewrites concept documents for changed modules, and refreshes `index.md` and `log.md`. It does not rebuild the full wiki — only what has changed. The practical cadence is: run after significant commits, or automate in CI.

## CI: Keeping the Wiki Fresh Without Manual Effort

A wiki that goes stale is worse than no wiki. Agents trust stale documentation and make confident wrong decisions. The right answer is automatic updates via CI.

OpenWiki ships ready-to-use workflow files for GitHub Actions, GitLab CI, and Bitbucket Pipelines. The GitHub Actions example runs on a schedule, executes `openwiki code --update --print`, and opens a pull request with any wiki changes. The `--print` flag makes it non-interactive. `--update` creates the initial `openwiki/` if it does not exist yet, so you do not need a separate init step in CI.

```yaml
# .github/workflows/openwiki-update.yml (from the provided examples)
env:
  OPENWIKI_PROVIDER: anthropic
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

The CI pull request includes updated concept documents, a refreshed root `index.md`, new `log.md` entries, and any changes to the `AGENTS.md`/`CLAUDE.md` injection block.

The practical result: any agent running against the main branch always has a current wiki. No developer needs to remember to run `openwiki --update`. The PR also provides a human-readable changelog of what the codebase description changed between runs.

## Inference Providers

OpenWiki is not tied to any single provider. Configuration lives in `~/.openwiki/.env`:

| Provider | Auth mechanism |
|---|---|
| OpenAI | API key |
| OpenAI (ChatGPT login) | Browser OAuth — draws on your ChatGPT subscription |
| Anthropic | API key |
| Gemini AI Studio | API key |
| Gemini Enterprise (Vertex AI) | Google ADC — IAM, no separate API key |
| AWS Bedrock | IAM credentials — no separate API key |
| OpenRouter | API key |
| OpenAI-compatible | API key + base URL (LiteLLM, local models, etc.) |

Bedrock and Vertex AI are notable because they use IAM-based authentication rather than API keys, making them easier to rotate and audit in organizational settings. The `openai-chatgpt` provider draws on a ChatGPT Plus/Pro/Team subscription instead of per-token API billing — useful if you already have a subscription and want to avoid a separate API account.

## How Agents Consume the Wiki

Agents do not need special tooling to consume an OKF bundle. The consumption path is standard:

1. The agent reads `AGENTS.md` at session start — this is standard behavior for all major agents (Copilot, Claude Code, Codex, Gemini CLI).
2. `AGENTS.md` contains the OpenWiki injection block, which tells the agent that `openwiki/` holds structured context and instructs it to consult the wiki when looking for context.
3. The agent reads `openwiki/index.md` — a single call that shows the full directory of concept documents.
4. The agent navigates to the relevant pages and reads them.

This is the same read-file workflow agents already use, directed at structured content instead of raw source files. No new MCP server. No protocol change. No additional configuration.

The token economics are favorable. Reading `openwiki/index.md` is cheap — it is a compact listing. Reading a specific concept document is also cheap — documents are purpose-written summaries, not raw source files. Compare this to the alternative: the agent reads multiple source files, reconstructs the module structure, infers the API surface, and figures out the dependencies — at full token cost, every session.

## Interactive Mode

OpenWiki also runs as an interactive CLI session where you can ask questions directly against the generated wiki:

```bash
openwiki                                          # interactive session
openwiki "Which module handles payment retries?"  # start with a request
openwiki -p "List all public API endpoints"       # one-shot, print and exit
```

Useful for onboarding, quick lookups, and exploring unfamiliar areas of a codebase without opening files manually.

## Personal Mode

Code mode is for repositories. Personal mode is for everything else.

```bash
openwiki personal --init
```

Personal mode builds a wiki in `~/.openwiki/wiki/` from connected sources. Connectors are authenticated via `openwiki auth <provider>`:

| Connector | What it ingests |
|---|---|
| Gmail | Recent mail, via Google OAuth |
| Notion | Pages and databases, via Notion OAuth |
| X/Twitter | Timeline, bookmarks, mentions, via X OAuth |
| Git repositories | Local repo structure and commits |
| Web Search | Tavily-powered search results |
| Hacker News | Feed and search, no credentials needed |

Each connector can be configured multiple times with separate topic scopes. Run ingestion with `openwiki ingest all` or target a specific connector with `openwiki ingest web-search`.

Personal mode addresses a different context problem. Repository wikis cover what the codebase is and how it works. The personal brain covers the broader knowledge you actually use: design notes in Notion, thread discussions on X, recent emails, research in web search. The same OKF format works for both, which means both wikis can be committed to version control, diffed, and shared with others if appropriate.

## INSTRUCTIONS.md: Scoping the Wiki

One design detail worth calling out: `openwiki/INSTRUCTIONS.md` is explicitly not a generated file. OpenWiki creates it on the first run with a template, then never overwrites it. It is where you tell OpenWiki what matters about your codebase:

- Which modules are most important to document thoroughly.
- Which parts of the codebase the agent frequently gets wrong.
- What the team's most important architectural constraints are.
- Which areas are under active construction and should be documented more lightly.

This file is your steering wheel. Without it, OpenWiki makes reasonable default choices. With it, it produces documentation that reflects your actual priorities.

## Where OpenWiki Fits

OpenWiki is not a graph-query tool. It does not expose MCP tools for blast-radius analysis, call-chain traversal, or Cypher queries. If you need those, a dedicated indexer is the right complement — I covered the full landscape of graph-query tools in [Knowledge Graph Tools for AI Code Agents](/posts/Code-Agent-Knowledge-Graphs/).

OpenWiki fills a different gap. Graph-query tools produce machine-consumable output: graph nodes, edge lists, structured query results. That output is useful for automated reasoning but opaque to a human trying to understand an unfamiliar module. OpenWiki produces human-readable narrative documentation that is simultaneously agent-consumable through the `AGENTS.md` reference.

A combination that works well in practice: OpenWiki for the documentation layer (module descriptions, API summaries, ADRs, cross-cutting concerns) alongside a graph-query tool for structural analysis (call graphs, blast radius, type resolution). Both run against the same repository. The agent queries whichever has the answer the current task needs.

## Closing

The stateless nature of agent sessions is a first-principles problem. Every session forgets everything. The codebase grows larger and more complex faster than any context window can capture it. Without persistent, navigable structure, agents rediscover the same facts repeatedly at full token cost.

OpenWiki and OKF address this at the format level. Generate structured documentation once, commit it with the code, keep it current with CI, and let agents find it automatically through `AGENTS.md`. The output serves both agents — through the injection block and the structured navigation hierarchy — and humans — through readable markdown they can browse and edit.

This is the documentation layer of agent infrastructure. It is not glamorous, but it is fundamental: ensuring the agent always has a current, navigable description of what the codebase is and how it works, without paying to rediscover it on every session.
