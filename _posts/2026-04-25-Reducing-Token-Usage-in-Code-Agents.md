---
layout: post
read_time: true
show_date: true
title: "Reducing Token Usage in Code Agents with RTK-AI, Graphify, Caveman, and LSP"
date: 2026-04-25
img_path: /assets/img/posts/20260425
image: Alverca.jpg
tags: [ai, llm, code agents, context engineering, lsp, productivity, claude code, github copilot]
category: ai
meta_description: "Why token usage explodes in long code-agent sessions and how context engineering with RTK-AI, Graphify, Caveman, and LSP helps reduce cost and stay within model limits."
---

When people first use code agents, the experience feels magical. You ask for a feature, the agent scans your code, edits files, runs tests, and keeps going.

Then reality shows up: context grows, token usage spikes, and sessions become expensive and fragile.

## The Core Problem

Most models do **not** maintain full persistent state across calls. In practice, that means the system has to resend relevant information at every new request:

- instructions
- conversation history
- tool outputs
- code snippets and files
- error logs and diagnostics

A hidden but expensive detail is that most CLI tools were designed for humans, not for LLM context efficiency. Their output is often verbose by design: banners, progress bars, repeated lines, boilerplate headers, and long "success" logs.

If an agent executes those commands, the model still needs to ingest that output to reason about next steps. So the verbosity gets paid for twice: once in context-window pressure and again in token cost.

As the session gets longer, and as the codebase gets larger, more context is usually sent on each turn.

That context size is measured in **tokens**.

A token is a small unit of text that the model processes. It is not exactly a word and not exactly a character. For English text, a rough mental model is that one token is often about 3-4 characters, but this varies by language and by content (code, JSON, stack traces, and minified output tokenize differently).

Every model has a **token limit** (context window). If your full prompt plus expected output exceeds that limit, something has to be dropped, compressed, summarized, or split.

There is also a cost angle. Many code-agent services bill by token usage. GitHub Copilot has historically framed usage around **premium requests**, but it now also applies token quotas in its plans and policies, which brings token budgeting to the front even for Copilot users too ([announcement](https://github.blog/news-insights/company-news/changes-to-github-copilot-individual-plans/)).

## What Code Agent Platforms Already Do

Modern code-agent services already include built-in controls such as:

- skills
- subagents
- scoped tool calls
- selective retrieval of files and logs

These features help, but they are often not enough on their own for very large repos or long-running workflows.

## Context Engineering

This is where **context engineering** comes in.

Context engineering is the discipline of deciding **what** to send to the model, **when** to send it, and **in what form** so the model stays accurate while using fewer tokens.

It combines:

- retrieval strategy (fetch only relevant evidence)
- compression strategy (summaries, deduplication, distilled memory)
- orchestration strategy (break tasks into smaller focused calls)
- semantic navigation (use symbols and references, not entire files)

Good prompt writing helps. Good context engineering is what keeps systems scalable.

## Tools That Push This Further

Beyond built-in platform features, open-source tools can reduce token usage further.

## 1) RTK-AI

[RTK-AI](https://www.rtk-ai.app/) is a high-performance CLI proxy focused on one thing: filtering command output before it enters model context.

Why this matters? Standard shell commands are often human-friendly but token-heavy, and code agents still need that output in context to make decisions. RTK rewrites or wraps those commands and returns a compact, decision-oriented version.

RTK's approach combines four strategies:

- smart filtering (remove noise and boilerplate)
- grouping (aggregate similar items)
- truncation (keep relevant context, cut repetition)
- deduplication (collapse repeated lines with counts)

It is particularly useful for high-noise commands like:

- `git status`, `git diff`, `git log`
- test runners (`pytest`, `cargo test`, `go test`, `npm test`, `dotnet test`)
- linters/builds (`ruff check`, `tsc`, `cargo build`, `dotnet build`, `dotnet format`)
- container and infra logs (`docker`, `kubectl`)

Operationally, one of RTK's biggest wins is the auto-rewrite hook (`rtk init -g`) that transparently maps shell commands to RTK equivalents. One practical caveat: this works for Bash tool calls; built-in IDE tools like `Read`/`Grep`/`Glob` are not auto-rewritten, so explicit shell/RTK commands are still important there.

In short, RTK reduces tokens by turning verbose human output into compact model-ready signal, without dropping the information needed for correct agent decisions.

## 2) Graphify

[Graphify](https://graphifylabs.ai/) is especially useful for the hardest part of large-agent workflows: **code search and navigation**.

In big repositories, agents spend many calls just trying to find the right files, symbols, and relationships. Each extra `grep`, `glob`, `read`, and follow-up search adds more output to context, which increases both token usage and total call count.

Graphify tackles this by indexing the codebase as a queryable knowledge graph, using structural extraction (AST-level code understanding) plus semantic relationship extraction. This gives the model a map first, so it can ask targeted questions against graph structure instead of repeatedly scanning raw files.

This approach is similar to the Karpathy-style "LLM wiki" pattern: build a persistent, navigable representation of the project, then query that representation instead of re-reading everything on every turn. In practice, Graphify produces reusable artifacts like `GRAPH_REPORT.md` and `graph.json`, so future sessions start from structure, not from zero.

The payoff is straightforward: fewer exploratory calls, smaller context payloads per step, and better navigation accuracy in large codebases.

## 3) Caveman

[Caveman](https://getcaveman.dev/) addresses a different source of waste: models are optimized to communicate with humans, which usually means grammatically complete sentences, polite framing, hedging, and stylistic mannerisms.

That is often useful for human readers, but in agent-to-agent or agent-to-tool workflows, much of that phrasing is not required for decision-making. If the technical substance is preserved, a lot of wording can be removed.

This is exactly what Caveman does. It compresses language while keeping technical meaning, with selectable intensity levels (lite/full/ultra) depending on how aggressive you want the reduction to be. In practice, this can cut output-token usage substantially (often around the ~75% range in its examples and benchmarks).

An important detail: the biggest gains come from output compression (what the model says), not from changing reasoning depth. Caveman reduces verbal overhead, not technical correctness.

It also includes a compression workflow for instruction/context files (for example, long agent memory files), so recurring session input can be shortened while preserving commands, paths, code blocks, and other technical artifacts.

## 4) LSP (Language Server Protocol)

LSP is one of the highest-leverage tools for reducing code-search cost.

Most modern IDEs show things like "N references" next to methods. That signal comes from language tooling (compiler/analyzer + language server), not from text search. These tools understand grammar, types, symbols, and project structure, and often maintain an indexed tree-like model of the codebase that can be queried efficiently.

For code agents, that matters a lot. Instead of repeatedly grepping files and reading large chunks, the agent can ask precise operations such as go-to-definition, find-references, hover/type info, symbol search, rename, and call hierarchy. The result is fewer exploratory calls and smaller context per step.

Both Claude Code and GitHub Copilot CLI can connect to LSP-backed code intelligence:

- Claude Code code intelligence plugins: [code.claude.com/docs/en/discover-plugins#code-intelligence](https://code.claude.com/docs/en/discover-plugins#code-intelligence)
- Copilot CLI LSP servers: [docs.github.com/en/copilot/concepts/agents/copilot-cli/lsp-servers](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/lsp-servers)

As of this writing, Copilot CLI is explicitly documented for configurable LSP server integration. I have not seen equivalent first-party documentation for VS Code Copilot Chat exposing the same user-configurable LSP server pipeline in the same way, so treat that support as unclear and version-dependent.

## A Practical Pattern

A useful pattern for large code-agent sessions is:

1. Use LSP to locate the exact symbols involved.
2. Use RTK-AI-style retrieval to assemble minimal supporting snippets.
3. Use Graphify to pull related architectural context (contracts, dependencies, design constraints).
4. Use Caveman-style compression to keep long-horizon memory compact between turns.

In short: use structure first, then summarize what remains.

## Final Thoughts

Token reduction is not just a cost optimization. It is also a quality optimization.

Smaller, cleaner, better-targeted context usually means:

- fewer hallucinations
- fewer irrelevant edits
- more stable multi-step runs
- better performance under model limits
- lower operating costs

Together, these approaches are complementary, not competing. Graphify and LSP overlap in code navigation, but they solve different layers of the problem: LSP is best for compiler-precise symbol operations inside a language, while Graphify is best for cross-artifact and cross-file conceptual navigation (code, docs, design rationale, and broader project structure). RTK reduces noisy command output, Caveman compresses linguistic overhead, LSP sharpens symbol-level lookup, and Graphify provides long-range structural memory.

Code agents are getting better quickly. But at scale, the winning teams are not just good at prompts; they are good at **context engineering**.
