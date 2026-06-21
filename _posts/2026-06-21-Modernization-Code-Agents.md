---
layout: post
read_time: true
show_date: true
title: "Code Modernization Agents: making impossible projects finishable"
date: 2026-06-14
img_path: /assets/img/posts/20260621
image:
  path: /assets/img/posts/20260621/Expo.jpg
tags: [ai, agents, copilot]
category: ai
redirect_from:
  - /posts/Code-Modernization-Agents/
meta_description: "Code modernization agents make impossible projects finishable by combining indexing, reasoning, and deterministic tooling. This post explains how to safely plan, transform, and verify large-scale migrations."
---

Modernization is the project that dies on the altar of cost and risk. Big monoliths, ancient frameworks, 40k‑line files, missing docs and tribal knowledge that left with the last engineer make these efforts expensive, slow and unpredictable. Teams cancel them not because they aren’t needed, but because they are economically impossible.

The real challenge is to make agents analyze and transfer the **full business logic** — without omissions or hallucinations — so the modernized system behaves exactly like the legacy one. Indexing turns a codebase from a pile of text files into a navigable semantic system; agents use that index to reason about symbols, call graphs, types and data flows; deterministic tools then apply and verify the changes. Dependencies in those graphs are measurable, so you can quantify coverage gaps and iteratively improve test and transformation coverage. Only when the agent can both **understand** the business semantics and **prove** the transformation (tests, static checks, contract validators) can you safely plan, transform and verify at scale — and turn cancelled projects into finishable work.

## Core idea

**Indexing + agents + deterministic tooling = modernization that is affordable, predictable and finishable.**

Indexing gives you a global, semantic view of the codebase — ASTs, symbol tables, call graphs and dependency clusters — and that view is what lets agents reason about code as code rather than as text. Agents orchestrate and plan across that index, and deterministic tooling (codemods, refactors, linters, analyzers, test templates) applies changes safely and reproducibly. This hybrid pattern is what makes large migrations tractable.

Read more about the indexing mindset in **[From Grep to Graph](https://antaoalmada.dev/posts/From-Grep-to-Graph/)** and about hybrid workflows in **[Hybrid Workflows](https://antaoalmada.dev/posts/Hybrid-workflows/)** and **[Beyond Text](https://antaoalmada.dev/posts/Beyond-Text/)**. The tooling I use is currently **[codebase‑memory‑mcp](https://deusdata.github.io/codebase-memory-mcp/)**.

## What codebase‑memory‑mcp brings to the table

`codebase‑memory‑mcp` is the practical piece that turns the indexing idea into something you can run inside a repo. It converts a repository into a persistent, queryable knowledge graph so agents and pipelines can ask precise questions and get precise answers. That shift — from reading files to asking the graph — changes how you plan, test and execute a migration.

A few capabilities make the difference between “LLM guesses” and “agentic correctness,” and they’re worth calling out explicitly:

- **Tree‑sitter parsing for structural fidelity.** The index is built on Tree‑sitter parses, so every file is converted into a real AST rather than treated as plain text. That gives you accurate node locations, token types, and language‑level structure across hundreds of languages.  
- **Hybrid LSP resolution for semantic context.** Where Tree‑sitter gives structure, hybrid LSP resolution fills in the semantic gaps: symbol resolution, type hints, and cross‑file references. Together they let agents follow symbols and types across the repo instead of guessing from names.  
- **Semantic query primitives and graph exports.** The engine exposes symbol queries, call‑graph traversals, data‑flow lookups and dependency cluster exports. Agents ask for the exact semantic slice they need — a function’s callers, a module’s public surface, or the transitive closure of a service boundary — and get structured results suitable for deterministic tooling.  
- **Dependency clustering and module signals.** The index computes clusters (implementation modules) from the call graph and dependency topology. Those clusters are the natural units for planning, parallelization and risk assessment.  
- **Cross‑boundary dependency reporting.** The index reports dependencies **across communication boundaries** — HTTP APIs, message queues, RPCs, event streams and other integration points — so you can see how services interact at runtime, which modules produce or consume events, and where contract or protocol risks live. This signal is essential for safe extractions, API migrations and contract‑first modernization.  
- **Persistent, incremental index and fast reindexing.** The knowledge graph persists across sessions and updates incrementally, so repeated agent runs are fast and reproducible. That persistence turns one‑off explorations into long‑lived programmatic signals.  
- **CLI and MCP parity.** The same semantic primitives are available via a CLI and via an MCP‑compatible server.  
- **Tooling integration for deterministic edits.** The index is designed to feed codemods, refactors and AST patches: structured edits (AST patches, codemod scripts, transformation manifests) are generated and applied deterministically, keeping diffs small and auditable.  
- **Enterprise deployment model.** The tool runs locally and fits air‑gapped environments; it keeps code inside your perimeter and supports reproducible, signed binaries for secure installs.

Together, Tree‑sitter + hybrid LSP + the graph API is what actually *makes AI understand the codebase*. Tree‑sitter gives the shape, LSP gives the meaning, and the graph API gives the agent the exact slice it needs to reason, plan and produce deterministic edits — now including visibility into cross‑service communication so modernization plans reflect both code structure and runtime interactions.

## Why naive LLM approaches fail — and what indexing buys you

Pasting files into a model and asking it to “modernize” fails for three reasons:

- **Context limits** — real monoliths are far larger than any context window.  
- **Lack of semantics** — plain text hides symbols, types and call relationships.  
- **Non‑determinism** — freeform generation yields inconsistent style, duplicated logic and unpredictable diffs.

Indexing changes the game by building a semantic graph of the system — symbols, call edges, data flows and module boundaries — and letting agents operate on **semantic slices** instead of blobs of text. From that graph you can:

- resolve symbols across modules and follow call graphs;  
- extract precise semantic slices for the agent to reason about, saving tokens and avoiding hallucinations;  
- compute **dependency clustering** to discover the real implementation modules (not just folder names);  
- measure dependencies and map tests onto the graph to quantify coverage gaps.

Dependency clusters become the planning units: they reveal the practical modules you can modernize, prioritize and parallelize. Once dependencies and coverage are measurable, modernization stops being guesswork and becomes a program you can plan, budget and execute.

## CLI parity, token savings and enterprise constraints

`codebase‑memory‑mcp` exposes the same capabilities as an MCP server and as CLI commands, and that parity matters.

- **Token and credit efficiency** — switching from an MCP server to CLI commands reduced documentation generation runs in my experience from **5k → 3k AI credits**.
- **Enterprise practicality** — many enterprises disable MCP servers for security reasons. A CLI‑first workflow runs inside the enterprise perimeter, on air‑gapped environments or behind strict controls, making the tooling usable where it’s needed most.

The CLI option is not just an optimization; it’s the difference between a tool that works in the lab and a tool that works in production environments with strict security policies.

## Tests are the documentation — and TDD when tests are missing

In real modernization scenarios the **code is the documentation**: comments are sparse, architecture docs are stale, and the business rules live in the implementation. Tests are the single best form of documentation and the canonical oracle for correctness.

- **If legacy tests exist**: treat them as the acceptance criteria. The ideal workflow is to run the legacy test suite against the modernized code; passing the same tests is the strongest evidence the business logic was transferred correctly.  
- **If tests do not exist**: adopt agent‑driven TDD. Agents observe legacy behavior, generate deterministic tests that capture that behavior, and then implement the modernized code against those tests. The cycle is: extract behavior → generate tests → modernize → validate.  
- **Measure coverage with graphs**: map tests to dependency clusters and call graphs to quantify which modules, APIs and flows are covered and which are blind spots; use that signal to prioritize test generation and transformation work.

Without tests you cannot prove the migration preserved business semantics. Agent‑driven TDD is the practical way to create that proof when tests are missing.

## Deterministic tooling and quality gates

Quality of generated code is the linchpin. Agents can propose transformations, but deterministic tools must apply and verify them. Make these primitives non‑optional.

**Essential deterministic components**

- Formatters and linters for consistent style and small diffs.  
- Static analyzers and type checkers to catch regressions early.  
- Refactoring engines and codemods for safe, repeatable edits.  
- Complexity and duplication detectors to avoid increasing technical debt.  
- Deterministic test scaffolding and property tests for repeatable coverage.  
- Contract validators for OpenAPI, protobuf and JSON Schema migrations.  
- CI gating and reproducible builds as non‑bypassable gates.

**Quality gates to enforce**

- All tests pass and coverage does not drop.  
- Legacy tests run against modernized code and pass when available.  
- No new critical static analysis issues.  
- Cyclomatic complexity per function within limits.  
- Duplication ratio does not increase.  
- API contract compatibility validated or explicit migration plan provided.  
- Performance regressions within acceptable bounds.  
- Deterministic formatting to keep diffs reviewable.

Deterministic tools make diffs auditable, rollbacks trivial and agent output replayable.

## Practical modernization pipeline

A compact, repeatable pipeline I use and recommend:

1. **Index the codebase** with codebase‑memory‑mcp: build ASTs, symbol tables, call graphs, dependency maps and dependency clusters.  
2. **Generate a modernization plan** from the index: identify clusters, compute dependency order and prioritize low‑risk modules.  
3. **Capture behavior**: if tests exist, use them as the oracle; if not, have agents generate deterministic tests (TDD).  
4. **Translate the plan into deterministic edits**: codemods, refactor calls, structured AST patches or compiler‑level transforms.  
5. **Run CI gates**: formatters, static analyzers, complexity checks, unit/integration tests, contract validators and benchmarks.  
6. **Open small, focused PRs** per cluster or bounded context with deterministic diffs.  
7. **Re‑index** and repeat until migration is complete.

Module clustering makes the work parallelizable and measurable; tests mapped to clusters make coverage actionable.

## What modernization agents can do today

Practical migrations that are tractable now include:

- **Legacy Java → modern Java**: replace deprecated APIs, adopt streams, modernize concurrency and split modules.  
- **.NET Framework → .NET Core**: hosting, DI, middleware, configuration and runtime changes.  
- **COBOL → Java or C#**: extract business rules, map data structures and generate modern equivalents.  
- **Legacy JS → TypeScript and modern frameworks**: infer types, modularize and migrate DOM logic to components.  
- **Monolith → modular monolith or bounded modules**: extract contexts and enforce contracts.  
- **SQL‑heavy logic → ORM or CQRS**: extract queries, map schemas and generate repositories or handlers.

All of these require global reasoning about the codebase and deterministic application of changes.

## The economic argument

Modernization is expensive because humans must read, reason, rewrite and verify everything. Agents change the cost model:

- **Understanding becomes indexed** — a one‑time cost that is reused.  
- **Rewriting becomes automated** — systematic and repeatable.  
- **Verification becomes deterministic** — tests, static checks and complexity metrics.  
- **Cost becomes predictable** — fewer surprises, smaller PRs and measurable gates.

When modernization becomes predictable and auditable, not modernizing becomes the risky choice.

Modernization agents are not a magic wand. They are an engineering pattern: **index, plan, apply deterministically, verify**. Do that and projects that used to be impossible become measurable, auditable and finishable.

A final, practical note: a modernized codebase should not be a one‑time artifact. After you complete the migration, **re‑index the modernized codebase** with the same class of tools — Tree‑sitter parses, hybrid LSP signals, dependency clustering and transformation manifests — so the repository itself becomes an AI‑ready, living knowledge graph. That freshly indexed modern codebase then powers continuous maintenance: automated impact analysis, incremental refactors, agent‑driven tests, contract validation and reproducible transformations. In short, modernize the code and then index the result — the repo becomes the ongoing foundation for future AI‑assisted work and continuous modernization.
