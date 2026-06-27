---
layout: post
read_time: true
show_date: true
title: "Prompt Caching in Coding Harnesses"
date: 2026-06-27
img_path: /assets/img/posts/20260627
image:
  path: /assets/img/posts/20260627/Baixa.jpg
tags: [ai, agents, copilot, llm, prompt caching, token usage]
category: ai
math: true
meta_description: "How prompt caching works in coding agents, why cache hit rate drives cost, and what workflow habits preserve or destroy it."
---

Usage-based billing changed the economics of coding agents. It is no longer enough to ask whether an agent can solve a task. We also need to ask how many tokens it burns while doing it.

In [Reducing Token Usage in Code Agents](/posts/Reducing-Token-Usage-in-Code-Agents/), the focus was context engineering: reduce noise, retrieve less, send better inputs. This post covers the other major lever: **prompt caching** — what it is, how it works, and what you can do to keep it effective.

## How Prompt Caching Works

Large language models are stateless. Each API call sends the full prompt from scratch. The model has no built-in memory of what it processed five seconds ago.

That sounds wasteful, and it is. Prompt caching exists to fix it.

The idea is simple. When a provider receives a request, it checks whether the beginning of the prompt matches something it has already processed recently. If it does, the provider can skip the expensive computation for that matching prefix and only process the new tokens at the end.

Think of it like a compiled header in C++. The compiler does not reparse `<vector>` and `<string>` on every build. It caches the result and only compiles the new code you added. Prompt caching does the same thing for token processing.

Here is the important part: the matching must start at the beginning. If the first token differs, the entire cache is invalidated. The prefix must be identical, byte for byte, for the cached computation to apply.

```text
Turn 1:  [system prompt] [instructions] [user message A]
Turn 2:  [system prompt] [instructions] [user message A] [assistant reply] [user message B]
                                                          ─────────────────────────────────
                         ▲ cached prefix (reused) ▲       ▲ new tokens (computed fresh) ▲
```

When a cache hit occurs, two things improve simultaneously:

- **Latency drops.** The provider skips recomputation for the cached prefix.
- **Cost drops.** Cached input tokens are billed at a fraction of the price of fresh tokens — often 50–90% cheaper depending on the provider.

This makes cache hit rate one of the most important cost metrics in agentic systems.

## Why It Matters For Coding Agents

Coding agents are expensive because their prompts are large. A typical agentic turn includes a system prompt, tool definitions, instruction files, conversation history, retrieved code snippets, and the user's latest message. This can easily reach tens of thousands of tokens per call.

If those tokens get recomputed from scratch on every turn, cost accumulates fast. If most of them hit the cache, the same session costs a fraction of the price.

The harness — the software that orchestrates the agent, such as VS Code's Copilot Chat or the GitHub Copilot CLI — decides how prompts are assembled and how provider APIs are called. But the user still controls the task shape, the cadence of interaction, and often the model provider. Those choices determine whether caching works or fails.

If you want the broader harness picture, including instructions, skills, agents, and hooks, see [The Architecture of Code Agents: Instructions, Skills, Agents, Hooks](/posts/The-Architecture-of-Code-Agents-Instructions-Skills-Agents-Hooks/).

## The Prefix Stability Principle

The fundamental rule of prompt caching is this: **stable prefixes get cached; unstable prefixes do not.**

Everything that changes between turns forces a cache miss from that point forward. Everything that stays the same gets reused. This creates a clear design principle for both harness builders and users: put stable content at the beginning, variable content at the end.

Harnesses already follow this principle internally. The system prompt, tool definitions, and instruction files are placed first because they rarely change mid-conversation. User messages and tool results come last because they change every turn.

But users can still break the principle from outside:

- Restarting a conversation forces the harness to rebuild the entire prompt from scratch — including the conversation history that was building up as a reusable prefix.
- Switching providers mid-workflow invalidates all cached state, since caches are provider-specific.
- Injecting large volatile payloads early in the context (like full log dumps) can push variable content into the prefix zone.

## What The User Controls

The harness manages the mechanics. The user controls the conditions that make caching work.

The key factors are:

- **Thread continuity.** Staying in one thread lets the prefix grow incrementally. Restarting forces a cold start.
- **Task focus.** A focused task keeps the same context relevant across turns. A wandering task forces context to be rebuilt.
- **Provider stability.** Each provider maintains its own cache. Switching mid-workflow means starting cold on the new provider.
- **Workflow cadence.** Caches expire. Long pauses between turns can cause misses even with a stable prefix.
- **Input quality.** Large noisy payloads (full build logs, entire files when only a snippet is needed) waste prefix space and reduce the likelihood of hits on subsequent turns.

The key insight: you do not need direct control over cache internals. You need to stop forcing the harness to rebuild expensive context.

## Practical Guidelines

For most users, the actionable advice is:

1. **Keep one task in one thread.** Each new thread starts with a cold cache.
2. **Prefer incremental follow-ups.** Saying "now fix the error on line 12" reuses the existing prefix. Restating the entire task from scratch does not.
3. **Keep provider and model stable within a workflow.** Switching from Claude to GPT mid-conversation means zero cache reuse.
4. **Keep tasks narrow.** A narrow task means the same context remains useful across turns instead of being displaced by new, unrelated material.
5. **Send targeted excerpts, not raw dumps.** The agent does not need 500 lines of build output when the relevant error is three lines.

When you use [custom agents in GitHub Copilot](/posts/Copilot-Custom-Agents/), apply the same rule at a smaller scale: keep each agent's scope narrow enough that its local context stays clean and reusable.

These habits matter most on long-running tasks. In a short edit-fix-validate loop, a single cache miss is cheap. In a long debugging session, a multi-step refactor, or an orchestrated workflow that waits on builds, repeated misses compound quickly.

## Cache Lifetimes and Provider Differences

All major providers support prompt caching, but they differ in one critical parameter: **how long they keep cached prefixes alive.**

| Provider  | Mechanism | Typical retention |
|-----------|-----------|-------------------|
| OpenAI    | Automatic prefix caching | Longer windows on supported models |
| Anthropic | Explicit cache breakpoints | Shorter default lifetime |
| Gemini    | Implicit + explicit modes | Explicit caching gives finer control |

The practical consequence: if your workflow is dense and continuous (turns every few seconds), short cache windows work fine. If your workflow pauses — waiting for builds, human review, or external processes — longer retention becomes critical.

This matters especially for **orchestrator agents**. An orchestrator's job is to coordinate: dispatch workers, wait for results, decide what comes next. That pattern is inherently stop-and-go. An orchestrator that waits three minutes for a build result needs a cache that survives three minutes of silence.

This is why provider choice often matters more for orchestrators than for fast local loops. In multi-agent workflows like those described in [Custom Agents in GitHub Copilot: VS Code, CLI & Cloud](/posts/Copilot-Custom-Agents/), the orchestrator's provider should match the timing of the workflow, not just the quality of the model.

## Squads: The Cache Tradeoff

Agent squads — multiple specialized agents working on a shared task — introduce a tension between two goals that can pull in opposite directions.

**Goal 1: Clean context.** Give each agent only the context it needs. This improves output quality by eliminating noise.

**Goal 2: Cache reuse.** Reuse prefixes across turns. This reduces cost by avoiding recomputation.

A squad helps caching when each agent keeps a narrow, stable role:

```text
Orchestrator:  [shared brief] [coordination state]
Planner:       [shared brief] [design context]
Editor:        [shared brief] [code context]
Validator:     [shared brief] [test context]
```

Each agent reuses its own smaller prefix turn after turn. The shared brief is common but compact. The task-local state is different per agent but stable within each agent's scope.

A squad hurts caching when it duplicates the full context across every agent:

```text
Agent A:  [full conversation] [full brief] [full code] [task A]
Agent B:  [full conversation] [full brief] [full code] [task B]
Agent C:  [full conversation] [full brief] [full code] [task C]
```

Here the system is not reusing context — it is multiplying prompt reconstruction. Each agent pays the full cost of ingesting everything, and none benefits from the other's cached state (since caches are per-session, not shared across agents).

The number of agents also matters. Each new agent starts cold. At some point, the cost of cold starts and inter-agent handoffs exceeds the benefit of cleaner separation.

The rule: **squads help when they create context locality. They hurt when they create context duplication.**

## Balancing Quality, Context, and Cache Efficiency

When designing multi-agent workflows, the right priority order is:

1. **Task quality first.** A perfectly cached but badly scoped workflow is still a bad workflow.
2. **Keep each agent's context clean.** Clean context produces better outputs and fewer hallucinations.
3. **Maximize cache reuse within that structure.** Stable roles with stable prefixes.
4. **Minimize squad size.** Use the fewest agents that still give clear separation of concerns.

What works in practice:

- Split work into stable roles, not disposable micro-agents.
- Keep one provider-model pair stable within each role.
- Pass summaries and decisions between agents — not full transcripts.
- Keep the orchestrator's shared brief short and stable.

This creates two layers:

- A **shared layer** (system prompt, brief, tool definitions) that many agents reuse.
- A **task-local layer** (working state, code excerpts, tool results) that stays clean per agent.

Share the minimum common prefix. Isolate the rest.

## Verifying Your Cache Hit Rate

Knowing that caching exists is not the same as knowing it works for your workflow. Most harnesses now expose token breakdowns that distinguish cached input tokens from fresh ones. If you are not checking these numbers, you are optimizing blind.

The observability surfaces covered in [Observability for Coding Agents: From Black Boxes to Measurable Systems](/posts/Observability-for-Coding-Agents/) show how to extract and interpret these metrics. The key ratio to watch is:

$$\text{cache hit rate} = \frac{\text{cached input tokens}}{\text{total input tokens}}$$

A high ratio means the workflow is reusing context efficiently. A low ratio means prompts are being rebuilt from scratch on most turns — and you are paying full price for work the provider already did.

## Summary

Prompt caching is not a feature you toggle on. It is an emergent property of how you work with coding agents. The harness handles the mechanics, but the user shapes the workload.

The questions that matter:

- Am I staying in the same thread or restarting?
- Is my task focused enough that context remains useful across turns?
- Does my provider's cache lifetime match the pauses in this workflow?
- If I use a squad, am I sharing only the common prefix and keeping the rest task-local?
- Do I have more agents than the workflow actually needs?

Keep tasks coherent. Keep follow-ups incremental. Choose providers that fit the timing of the workflow. If you use squads, let each agent preserve clean task-local context, keep the shared prefix small and stable, and resist adding more agents than the task justifies.

That is how you balance quality with cache efficiency.
