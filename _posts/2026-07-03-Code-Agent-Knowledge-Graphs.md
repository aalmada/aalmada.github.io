---
layout: post
read_time: true
show_date: true
title: "The Index Layer: Comparing Knowledge Graph Tools for AI Code Agents"
date: 2026-07-03
img_path: /assets/img/posts/20260703
image:
  path: /assets/img/posts/20260703/Aquarium.jpg
tags: [ai, agents, knowledge graphs, tree-sitter, mcp, lsp, context engineering, copilot, claude code]
category: ai
redirect_from: /The-Index-Layer.html
meta_description: "Graphify, GitNexus, codebase-memory-mcp, and CodeGraph compared: how each indexes your codebase into a graph and what query surface it exposes to AI agents."
---

The previous posts in this series covered [why coding agents need LSP and semantic graphs](../From-Grep-to-Graph) and [how indexing tools are one of the most effective levers for reducing token usage in long agent sessions](../Reducing-Token-Usage-in-Code-Agents). This post goes deeper on those tools specifically: what they build, how they classify content, how they expose query interfaces to agents, and where each one fits.

We analyze the differences between **Graphify**, **GitNexus**, **codebase-memory-mcp**, and **CodeGraph** — the four most widely used tools in this space — and discuss which one is best for which scenario.

## The Origin: The LLM Wiki Pattern

The underlying idea is simple and well-known in the community. Instead of letting the agent explore your codebase raw on every session — grepping, reading files, following imports, rebuilding structure from scratch — you pre-build a persistent, navigable representation. The agent queries the representation instead of the raw files.

The pattern is sometimes called the ["LLM wiki"](https://x.com/karpathy/status/2039805659525644595) approach: treat your codebase the same way you would treat a knowledge base. Build it once, update it incrementally, and query it repeatedly at near-zero cost per query.

This is analogous to what compilers and IDEs have been doing for decades. They do not parse your entire codebase from scratch every time you hover over a symbol. They maintain an index, and they query the index. The only difference now is that the consumer is an LLM-based agent rather than a tooltip.

## Two Paths Into the Graph

The first architectural decision is how to extract entities and relationships from your source material. There are two fundamentally different approaches, and the right one depends entirely on what you are indexing.

### Parser-based: source code

When the input is source code, you have grammar. [Tree-sitter](https://tree-sitter.github.io/) is a battle-tested incremental parser that supports over 100 languages. It produces concrete syntax trees, which extractors traverse to pull out nodes (functions, classes, methods, interfaces) and edges (calls, imports, inheritance, implementations).

This path is:

- **Deterministic** — same input, same graph, every time
- **Free** — no LLM inference cost
- **Fast** — sub-second for most repositories, minutes for the Linux kernel
- **Precise** — edges are real parsed relationships, not probability-weighted guesses

The better tools in this class go further than tree-sitter alone. They add a **Hybrid LSP** layer: a lightweight, embedded type-resolution pass that can tell you that `user.profile.display_name()` resolves to `Profile.display_name` declared three modules away. Tree-sitter gives you syntax. Hybrid LSP gives you semantics.

### Reasoning-based: free-form content

Docs, PDFs, images, video transcripts, meeting notes — these lack grammar. You cannot parse a slide deck or a screenshot with tree-sitter. To extract entities and relationships from unstructured content, you need a reasoning model.

This path is:

- **Non-deterministic** — results vary by model and temperature
- **Costly** — each extraction consumes LLM tokens
- **Necessary** — some information only exists in natural language form
- **Capable of cross-modal linking** — a design doc that references code, linked back to the code it describes

Most tools in this space specialize in one path or the other. Graphify is the primary exception: it handles both within a single graph.

## The Query Layer

Building the graph is half the job. The other half is **how agents query it**.

This matters for a specific reason: the tool interface shapes token usage. Every time an agent calls a search-and-read cycle over raw files, it pays for the tool round-trips and the text of every file it opens. When an agent calls a graph query instead, it pays only for the structured answer.

Efficient query interfaces reduce tokens in two ways:

1. **Precision** — instead of reading a 500-line file to find one function, the agent requests that function directly and receives only its source plus its call context.
2. **Compression** — graph traversal results (callers, callees, blast radius, architecture summary) arrive as structured data, not as raw file contents scattered across multiple reads.

### MCP and CLI: two surfaces, different tradeoffs

All tools in this class expose their query layer through the **Model Context Protocol (MCP)**, so agents can call graph queries the same way they call any other tool. This works well for structured agent loops.

But several tools also expose the same queries through a **CLI**. This matters because CLI output can be piped, filtered, and composed with other shell tools — and because agents running in shell contexts (GitHub Copilot, Claude Code, Codex, Gemini CLI) can call CLI commands directly, often with smaller protocol overhead than a full MCP round-trip.

```bash
# MCP approach (agent calls graph tool via protocol)
# — structured, but protocol overhead is in every round-trip

# CLI approach (agent calls binary directly in a shell step)
gitnexus impact UserService
codebase-memory-mcp cli trace_path '{"function_name": "ProcessOrder", "direction": "both"}'
codegraph impact UserService --depth 3
```

For agents running in tight loops over large codebases, the CLI path can reduce per-step cost substantially. When combined with output compressors — [RTK-AI](https://www.rtk-ai.app/) rewrites specific CLI commands (git, test runners, linters) into compact signal before they reach the model; [Headroom](https://headroom-docs.vercel.app/docs) sits one layer up and compresses anything an agent reads (tool outputs, file reads, search results, logs, API responses) via a transparent proxy, Python/TypeScript SDK, or MCP integration — the savings compound further.

### LSP-equivalent operations

For code-specific tools, the query surface should cover the same operations that a language server exposes to an IDE — but served through MCP and CLI instead of the Language Server Protocol wire format.

The equivalent operations are:

| LSP operation | Graph query equivalent |
|---|---|
| Go to definition | `trace_path` / `context` (symbol definition lookup) |
| Find references | `callers` / `impact` (upstream dependency traversal) |
| Call hierarchy | `trace_path` (BFS across call chain) |
| Symbol search | `search_graph` / `query` (name pattern or semantic search) |
| Hover type info | `context` / `get_code_snippet` (symbol metadata + source) |
| Rename | `rename` (multi-file coordinated rename with graph + text) |
| Semantic tokens | Hybrid LSP edge types (`RESOLVED_CALLS`, `USAGE`) |
| Diagnostics | `detect_changes` (blast radius + risk classification on a diff) |

The critical difference from LSP: graph-based tools give you this at **repository scale** in a **single query**, rather than per-file per-cursor. An `impact` query answers "what is the full blast radius of this symbol across the entire codebase" — something no standard LSP server surfaces in one call.

---

## The Tools

### Graphify

[Graphify](https://graphifylabs.ai/) (76k+ stars, YC S26, MIT) is the widest-scope tool in this class. It is not a code indexer that also reads docs — it is a general-purpose knowledge graph engine that treats code as one of many input formats.

**What it indexes:**

- Code via 36 tree-sitter grammars: Python, TypeScript, Go, Rust, Java, C/C++, Ruby, C#, Kotlin, PHP, Swift, Lua, Zig, SQL, Elixir, Vue, Svelte, Astro, and more
- Docs: Markdown, MDX, HTML, PDF, RST, YAML
- Images: via vision model extraction
- Video and audio: local transcription via faster-whisper
- Google Workspace, Office docs, YouTube URLs
- SQL schemas and PostgreSQL introspection
- Terraform/HCL, MCP config files, package manifests

For code, tree-sitter extracts AST nodes locally — no API call required. For everything else, a reasoning model extracts entities and relationships from chunks of text. When running via the `/graphify` skill inside an IDE, the model API is provided by the IDE session — no extra keys are needed. For headless extraction (`graphify extract`), a backend must be configured explicitly: Gemini, Claude, OpenAI, DeepSeek, Kimi, and Azure OpenAI each require an API key from that provider; AWS Bedrock uses IAM credentials (no API key); Ollama runs fully locally; `claude-cli` routes through your existing Claude subscription. Leiden community detection groups related concepts into clusters and surfaces "god nodes" — the highest betweenness-centrality nodes whose failure has the largest blast radius.

**Output artifacts:**

```
graphify-out/
├── graph.html         # interactive browser visualization, click nodes and filter
├── GRAPH_REPORT.md    # god nodes, surprising connections, suggested questions
└── graph.json         # full graph — queryable offline
```

**Query surface:**

*CLI:*
```bash
graphify query "what connects auth to the database?"
graphify path "UserService" "DatabasePool"
graphify explain "RateLimiter"
```

*MCP tools (7):* `query_graph`, `get_node`, `get_neighbors`, `shortest_path`, `list_prs`, `get_pr_impact`, `triage_prs`

**Install:**
```bash
uv tool install graphifyy
graphify install   # default install target is Claude Code
graphify install --platform codex   # use --platform (or a platform-specific subcommand) for other agents
/graphify .        # build graph for current directory (inside an agent)
```

**Strengths:**

- Only tool that puts code, docs, images, and video into one queryable graph
- Incremental updates: only affected nodes and edges are rebuilt on file change
- Supports 20+ agent platforms through platform-specific install commands, skills, and hooks
- Leiden community detection surfaces architectural clusters automatically
- Graph can be committed to version control; teammates inherit the map
- Supports PR impact analysis and triage across the knowledge graph

**Limitations:**

- LLM extraction for non-code content is probabilistic; when running via the `/graphify` skill inside an IDE, the IDE session provides the model — no extra keys needed. Headless extraction (`graphify extract`) requires a configured backend: Gemini, Claude, OpenAI, DeepSeek, Kimi, or Azure OpenAI (each needs a provider key), AWS Bedrock (IAM, no API key), Ollama (local), or `claude-cli` (Claude subscription)
- No Hybrid LSP layer — type resolution stays at tree-sitter level for code
- No Cypher query interface; graph traversal is through the provided MCP tools and CLI commands
- Code-only repos need no API key; mixed corpora do

**Best fit:** projects where context lives across code, design docs, architecture decisions, and meeting notes. When you need to ask "which decision led to this implementation" and have the answer traced across three PDFs and two code modules.

---

### GitNexus

[GitNexus](https://github.com/abhigyanpatwari/GitNexus) (43k+ stars, PolyForm Noncommercial for OSS) positions itself as "the nervous system for agent context." It is a deep code intelligence engine: it understands not just what the code is, but which execution flows exist and what the blast radius of any change is.

**What it indexes:**

Source code in 14+ languages: TypeScript, JavaScript, Python, Java, Kotlin, C#, Go, Rust, PHP, Ruby, Swift, C, C++, Dart. Multi-phase pipeline: structure walk → tree-sitter parsing → cross-file resolution (imports, heritage, constructor inference, `self`/`this` receiver types) → Leiden community detection → process tracing (execution flows from entry points) → hybrid BM25 + semantic vector search (HuggingFace transformers.js embeddings, on-device).

All stored in LadybugDB (formerly KuzuDB), an embedded graph database with vector support.

**Query surface:**

*CLI (covers the main graph-analysis workflows directly):*
```bash
gitnexus query "what handles authentication?"
gitnexus context UserService
gitnexus impact get_embeddings --file src/embed.py
gitnexus trace main ProcessOrder
gitnexus detect-changes          # git diff → affected symbols + blast radius
```

*MCP tools (17 total: 15 per-repo + 2 group):*

| Tool | Purpose |
|---|---|
| `list_repos` | Discover all indexed repositories |
| `query` | Process-grouped hybrid search (BM25 + semantic + RRF fusion) |
| `context` | 360-degree symbol view — categorized refs, process participation |
| `impact` | Blast radius analysis with depth grouping and confidence scores |
| `trace` | Shortest directed path between two symbols |
| `detect_changes` | Git-diff impact — maps changed lines to affected processes |
| `rename` | Multi-file coordinated rename with graph + text search |
| `cypher` | Raw Cypher graph queries over the knowledge graph |
| `check` | Read-only structural checks against the indexed graph |
| `route_map` | API route map — which components fetch which endpoints |
| `tool_map` | MCP/RPC tool definitions — where they are defined and handled |
| `shape_check` | Validate API response shapes against consumer property access |
| `api_impact` | Pre-change impact report for an API route handler |
| `explain` | Explain taint findings (source→sink flows) |
| `pdg_query` | Query control/data dependence at statement level (`--pdg` indexes) |
| `group_list` | List configured repository groups |
| `group_sync` | Cross-repo contract registry and cross-linking |

**Install:**
```bash
npx gitnexus analyze        # index current repo, installs agent skills and hooks
npx gitnexus setup          # configure MCP for detected editors (one-time)
```

**Strengths:**

- Deep execution flow detection: entry points traced through full call chains, grouped as "processes"
- Hybrid search combines BM25 (keyword), semantic (vector), and Reciprocal Rank Fusion
- Multi-repo support: one MCP server indexes and serves multiple repositories
- Claude Code hooks: `PreToolUse` enriches Grep/Glob results with graph context before the model sees them
- `PostToolUse` hooks detect a stale index after commits and prompt re-indexing
- Auto-generates per-module agent skills from Leiden community clusters (`gitnexus analyze --skills`)
- Wiki generation from the graph structure
- Supports cross-repo contract registry for microservice architectures

**Limitations:**

- Code only — no docs, PDFs, images, or non-code content
- Node.js runtime required
- PolyForm Noncommercial license for the open-source version; commercial use requires enterprise licensing
- Larger install footprint than codebase-memory-mcp

**Best fit:** teams who want the deepest code intelligence available — execution flow tracing, blast radius analysis, multi-repo contract registries — and are working in a Node.js-friendly environment.

---

### codebase-memory-mcp

[codebase-memory-mcp](https://deusdata.github.io/codebase-memory-mcp/) (25k+ stars, MIT) is the performance extreme in this class. It is the only tool distributed as a **single static C binary** with zero runtime dependencies — no Node.js, no Python, no Docker, no API key.

**What it indexes:**

Source code in **158 languages** via vendored tree-sitter grammars compiled into the binary. Infrastructure-as-code (Dockerfiles, Kubernetes manifests, Kustomize overlays) as first-class graph nodes.

**Hybrid LSP:** for 10 languages (Python, TypeScript/JavaScript/JSX/TSX, PHP, C#, Go, C/C++, Java, Kotlin, Rust), a lightweight C implementation of type-resolution algorithms — structurally compatible with tsserver, pyright, gopls, Roslyn, Eclipse JDT, and rust-analyzer — runs on top of tree-sitter. It resolves `user.profile.display_name()` to `Profile.display_name` declared across module boundaries without spawning any language server process.

Semantic search uses nomic-embed-code embeddings (768d, int8) compiled into the binary. Fully local, no API key.

**Indexing performance (Apple M3 Pro):**

| Codebase | Time | Nodes | Edges |
|---|---|---|---|
| Linux kernel (28M LOC, 75K files) | 3 minutes | 4.81M | 7.72M |
| Django | ~6 seconds | 49K | 196K |

**Token savings (5 structural queries):** ~3,400 tokens via graph vs ~412,000 file-by-file (~120× reduction). A separate academic evaluation ([arXiv:2603.27277](https://arxiv.org/abs/2603.27277)) across 31 real-world repos reported 83% answer quality, 10× fewer tokens, and 2.1× fewer tool calls versus file-by-file exploration.

**Query surface:**

The CLI mirrors every MCP tool exactly, making it the most token-efficient path for shell-based agents:

```bash
# structural search
codebase-memory-mcp cli search_graph '{"name_pattern": ".*Handler.*", "label": "Function"}'

# type-inferred call chain traversal (Hybrid LSP-resolved)
codebase-memory-mcp cli trace_path '{"function_name": "ProcessOrder", "direction": "both"}'

# git diff → blast radius with risk classification
codebase-memory-mcp cli detect_changes '{}'

# openCypher read queries
codebase-memory-mcp cli query_graph '{"query": "MATCH (f:Function)-[:CALLS]->(g) WHERE f.name = \"main\" RETURN g.name"}'

# semantic vector search (no API key)
codebase-memory-mcp cli search_graph '{"semantic_query": ["retry", "backoff", "exponential"]}'

# full architecture overview in one call
codebase-memory-mcp cli get_architecture '{}'
```

*MCP tools (14):*

| Tool | Purpose |
|---|---|
| `index_repository` | Index a repository into the graph |
| `list_projects` | List all indexed projects with node/edge counts |
| `delete_project` | Remove a project and all graph data |
| `index_status` | Check indexing status of a project |
| `search_graph` | Structural, regex, semantic, or code search |
| `trace_path` | BFS call chain traversal, depth 1–5 |
| `detect_changes` | Git diff impact → blast radius + risk |
| `query_graph` | Read-only openCypher queries |
| `get_graph_schema` | Node/edge counts, relationship patterns, and property definitions |
| `get_architecture` | Languages, packages, routes, hotspots (git-history-derived churn), clusters in one call |
| `get_code_snippet` | Source for a symbol by qualified name |
| `manage_adr` | CRUD for Architecture Decision Records |
| `search_code` | Graph-augmented grep over indexed files |
| `ingest_traces` | Runtime trace ingestion to validate `HTTP_CALLS` edges |

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash
# Auto-configures all 11 supported agents
```

**Strengths:**

- Fastest indexer in the class: entire Linux kernel in 3 minutes, Django in 6 seconds
- Zero dependencies: single static binary, no runtime to manage
- 158 languages — including unusual ones (COBOL, Zig, Lean 4, OCaml, Fortran, Solidity, and more)
- Hybrid LSP for 10 languages: type-resolution without a language server process
- Semantic vector search bundled (no API key, no external process)
- Cross-service dependency detection: REST route-to-HTTP-call-site linking with confidence scoring; gRPC, GraphQL, and tRPC service detection; `EMITS`/`LISTENS_ON` pub/sub channel edges for Socket.IO, EventEmitter, and message buses; async queue dispatch — the graph captures how services actually communicate, not just how functions call each other within a service
- Data-flow tracing: `DATA_FLOWS` edges follow values from argument to parameter, including field-access chains — shows how data moves through the system, not just who calls whom
- Git co-change tracking: `FILE_CHANGES_WITH` edges are derived from git commit history and link files that frequently change together — useful for surfacing hidden coupling that does not appear in import graphs
- Team-shared graph artifact: one zstd-compressed snapshot committed to the repo lets teammates skip full reindex
- Architecture Decision Records baked into the graph
- SLSA Level 3 supply chain provenance, Cosign signatures, 70+ VirusTotal scans per release

**Limitations:**

- Code and IaC only — no docs, PDFs, or unstructured content
- Newer project (~35 releases as of mid-2026); some language support is in "functional" rather than "excellent" tier
- Hybrid LSP covers 10 languages; others fall back to textual resolution

**Best fit:** teams who need maximum indexing speed and minimum setup friction, work across many languages (including unusual stacks like COBOL or Zig), and want type-resolution-quality call graphs without maintaining language server processes.

---

### CodeGraph

[CodeGraph](https://colbymchenry.github.io/codegraph/) (57k+ stars, MIT) takes a deliberate simplicity position. Where the others expose 14–17 MCP tools, CodeGraph exposes one: `codegraph_explore`. The thesis is that one well-aimed tool produces better agent behavior than a menu of narrower ones — fewer mis-picks, and the response is sized to the answer rather than the file count.

**What it indexes:**

Source code in 20+ languages: TypeScript, JavaScript, Python, Go, Rust, Java, C#, VB.NET, PHP, Ruby, C, C++, Objective-C, Metal, Swift, Kotlin, Scala, Dart, Lua, Luau, R, CFML, COBOL, Svelte, Vue, Astro, Liquid, Pascal/Delphi.

Framework-aware route extraction for 17 web frameworks (Express, FastAPI, Flask, NestJS, Django, Laravel, Rails, Spring, Gin, Axum, ASP.NET, SvelteKit, Vue/Nuxt, Astro, and more). Cross-language bridging for Swift ↔ ObjC, React Native (legacy bridge + TurboModules + Fabric), and Expo Modules.

**Benchmark (7 real-world codebases, Claude Code headless, median of 4 runs):**
58% fewer tool calls, 22% faster, file reads cut to ~zero.

**Query surface:**

*CLI:*
```bash
codegraph explore "how does authentication reach the database?"
codegraph node UserService              # source + caller/callee trail
codegraph callers processPayment        # what calls this function
codegraph callees UserService.validate  # what this function calls
codegraph impact UserService --depth 3  # blast radius
codegraph query auth                    # symbol name search
```

*MCP tools:*

The primary tool is `codegraph_explore` — it accepts a natural-language question or symbol name and returns the relevant source verbatim (line-numbered, grouped by file), the call paths between symbols (including dynamic-dispatch hops grep cannot follow), and a blast-radius summary. One call typically answers the full question.

Seven additional tools (`codegraph_node`, `codegraph_search`, `codegraph_callers`, `codegraph_callees`, `codegraph_impact`, `codegraph_files`, `codegraph_status`) exist and are fully functional but unlisted by default, because their output already arrives inline in a `codegraph_explore` response.

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
codegraph init   # per project: creates .codegraph/ and builds the graph
```

**Strengths:**

- Single primary tool: simpler agent behavior, less prompt space spent on tool selection
- Framework route extraction: URL patterns linked to handler code for 17 frameworks
- Cross-language bridging: Swift ↔ ObjC, React Native bridge, Expo Modules, Fabric/Paper view components
- TypeScript-based: embeddable as a library in Node.js or Electron projects
- Zero config; auto-sync on file change using native OS events (FSEvents/inotify/ReadDirectoryChangesW)
- Affected test discovery: `codegraph affected` traces import chains to find test files impacted by a change — useful in CI

**Limitations:**

- Code only — no docs, PDFs, or unstructured content
- No Hybrid LSP or semantic vector search (structural and FTS5 only)
- No Cypher interface; graph traversal is through the provided tools and CLI
- Newer project (~25 releases as of mid-2026)

**Best fit:** TypeScript-heavy stacks, React Native and iOS projects, or anyone who prefers a clean minimal tool surface and finds the multi-tool approach noisy in their agent loops.

---

## Other Notable Alternatives

### Aider's repo map

[Aider](https://aider.chat/) builds a lightweight in-memory repo map using tree-sitter and ctags before each session. It is not a persistent graph and does not expose MCP tools — it is built into Aider's own context-construction pipeline. But it demonstrates the same principle at a smaller scale: understand structure first, send relevant fragments rather than full files. Useful as a mental model for what the richer tools are doing at larger scale.

### DeepWiki

[DeepWiki](https://deepwiki.com/) (Cognition AI) generates per-repo wiki-style documentation from public GitHub repositories. Cloud-only, closed-source, good for onboarding and architectural exploration. Not suitable for private codebases or tight agent loops that need sub-millisecond graph queries.

### llms.txt

The [llms.txt standard](https://llmstxt.org/) is a minimal alternative: place a well-structured Markdown file at the root of a repository describing the project for LLM consumers. Not a graph, not an indexer — but the lightest possible version of the LLM wiki pattern. GitNexus (`gitnexus wiki`) and Graphify (`/graphify . --wiki`) can both generate llms.txt-compatible artifacts from their richer graphs.

---

## Comparison

| | Graphify | GitNexus | codebase-memory-mcp | CodeGraph |
|---|---|---|---|---|
| Code indexing | ✓ (36 grammars) | ✓ (14+ langs) | ✓ (158 langs) | ✓ (20+ langs) |
| Docs / PDFs | ✓ | ✗ | ✗ | ✗ |
| Images / Video | ✓ | ✗ | ✗ | ✗ |
| Hybrid LSP / type resolution | ✗ | partial | ✓ (10 langs) | ✗ |
| Semantic vector search | ✗ | ✓ (HuggingFace) | ✓ (bundled, no API key) | ✗ |
| Cypher queries | ✗ | ✓ | ✓ | ✗ |
| MCP tools exposed | 7 | 17 | 14 | 1 by default (8 available) |
| CLI mirrors MCP tools | ✓ | ✓ | ✓ | ✓ |
| Multi-repo support | ✓ | ✓ | ✓ | limited |
| IaC indexing | ✗ | ✗ | ✓ | ✗ |
| Framework route extraction | ✗ | ✓ | ✓ | ✓ (17 frameworks) |
| Cross-service & channel detection | ✗ | partial (HTTP route mapping) | ✓ (REST/gRPC/GraphQL/tRPC + pub/sub) | ✗ |
| Data-flow tracing | ✗ | ✗ | ✓ | ✗ |
| Cross-language bridging | ✗ | ✗ | ✗ | ✓ (Swift↔ObjC, RN) |
| Runtime required | Python | Node.js | none (static C binary) | none (self-contained bundled runtime) |
| License | MIT | PolyForm NC | MIT | MIT |
| Stars (mid-2026) | 76k | 43k | 25k | 57k |

---

## Which Tool for Which Scenario

**You need code + docs + meetings + images in one graph:**
Graphify. The only tool that handles multi-format corpora in a single graph. Accept the LLM extraction cost for non-code content; the combined query capability — asking "which decision led to this implementation" across three PDFs, two meeting transcripts, and the code itself — is not available anywhere else.

**You need deep code intelligence for a large polyglot codebase:**
codebase-memory-mcp. 158 languages, Hybrid LSP type resolution for 10 of them, the fastest indexer in the class (Linux kernel in 3 minutes), zero infrastructure, and 120× token reduction benchmarks. The right default for any team that does not need docs in the same graph.

**You need execution flow tracing:**
GitNexus. Process detection traces entry points through full call chains and groups them as named processes, giving the agent a runtime-level view of behavior rather than just structure. The richest MCP tool surface in the class, with the deepest Claude Code integration (PreToolUse hooks that enrich Grep/Glob results with graph context before the model sees them).

**You need security-focused analysis — taint tracking, data-flow paths, source-to-sink:**
GitNexus. The `explain` tool surfaces taint findings with full source→sink flow traces. `pdg_query` exposes control and data dependence at the statement level, letting the agent ask "does user input ever reach this SQL call without sanitization" as a graph query rather than a manual audit.

**You work on infrastructure as code alongside application code:**
codebase-memory-mcp. It is the only tool in this class that indexes Dockerfiles, Kubernetes manifests, and Kustomize overlays as first-class graph nodes with the same edge types as application code. An agent can trace a service's deployment configuration back to the code it deploys, or ask which workloads are affected by a change to a shared ConfigMap.

**You are working across multiple repositories — microservices, separate frontend/backend, shared libraries:**
GitNexus and codebase-memory-mcp are the strongest fits. GitNexus includes a dedicated cross-repo contract registry that tracks API shapes and their consumers across service boundaries, detecting when a change in one repo breaks a contract in another. codebase-memory-mcp models cross-service HTTP, gRPC, GraphQL, and pub/sub dependencies as first-class graph edges, so the agent sees how services actually communicate rather than treating each repo in isolation. Graphify also supports multi-repo and can span repositories in a single graph, which is useful when architecture decisions or shared docs need to be linked alongside code.

**You need a clean, minimal surface for a full-stack or mobile project:**
CodeGraph. One smart tool that answers most questions in a single call. Framework route extraction covers both backend (Express, NestJS, FastAPI, Django, Spring, Gin, Axum…) and frontend (SvelteKit, Vue/Nuxt, Astro) frameworks, linking URL patterns to handler code across the full stack. Swift ↔ ObjC bridging and React Native support are unique to this tool. Zero config, zero overhead.

**No full graph is needed, just structure:**
Use Aider's built-in repo map, or generate an llms.txt file with any of the tools above. The LLM wiki pattern applies at any granularity.

## A Note on the CLI Path

All four tools expose their query layer through both MCP and CLI. The CLI path is worth deliberately using in agent workflows where token budget is a concern.

When an agent calls a graph query through MCP, it pays for the full JSON-RPC round-trip and the structured response in context. When it calls the same query through a shell command, the output can pass through [RTK-AI](https://www.rtk-ai.app/) (CLI-focused, rewrites specific commands) or [Headroom](https://headroom-docs.vercel.app/docs) (general-purpose, compresses any tool output via proxy or SDK, including MCP responses) before it reaches the model. Headroom's CCR store means the model can retrieve the full original when it genuinely needs more detail, so aggressive compression does not lose information.

In practice: if your agent can call shell commands, prefer the CLI interface for repeated structural queries in tight loops. Use MCP for interactive sessions where the agent needs structured data it will act on programmatically.

## Closing

None of these tools covers every scenario, and the right choice depends on what you are indexing, how much latency you can tolerate during indexing, and whether your context problem is code-only or multi-format.

These tools also **complement each other**. More than one can be active in the same project simultaneously — each accessible via its own MCP server or CLI commands, depending on what the agent needs. A common combination is Graphify for the docs and decision layer alongside codebase-memory-mcp or GitNexus for the code layer. They can index the whole repository or separate portions of it: one tool might own the application code graph while another owns the infrastructure manifests, the shared libraries, or the architecture decision records. The agent queries whichever graph has the answer.

What they share is the same principle: **build a persistent structural index, then query it instead of exploring raw files**. This reduces agent token usage, improves answer quality, and makes long-horizon multi-step runs more reliable.

The index layer is not a nice-to-have. At scale, it is the difference between an agent that navigates your codebase and one that merely searches it.
