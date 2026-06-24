---
layout: post
read_time: true
show_date: true
title: "Profiling Coding Agents with /troubleshoot"
date: 2026-06-24
img_path: /assets/img/posts/20260624
image:
  path: /assets/img/posts/20260624/Estoril.webp
tags: [ai, agents, copilot, observability, performance]
category: ai
redirect_from:
  - /posts/Profiling-Coding-Agents-with-Troubleshoot/
meta_description: "Use GitHub Copilot for VS Code's /troubleshoot command to inspect coding agent logs, reduce token usage, improve custom agents and skills, and turn agent sessions into measurable systems."
---

Analyzing logs has always been one of the least pleasant parts of software engineering. Logs are noisy, incomplete, repetitive, and usually produced by systems that are already failing in some inconvenient way. We collect them because we need them, not because we enjoy reading them.

Coding agents make this problem more interesting. They produce the same kind of operational evidence as other software systems: requests, responses, retries, tool calls, errors, timing information, cache behavior, and resource usage. But they also add a new layer: reasoning. An agent does not merely execute a function. It chooses a path, observes the result, and updates its plan. When it finds a blocker, it usually tries another workaround, then another, repeating that loop until it succeeds, fails, or runs out of useful context.

That loop is powerful. It is also expensive.

In my post about [observability for coding agents](/posts/Observability-for-coding-agents/), I briefly mentioned the `/troubleshoot` command in GitHub Copilot for VS Code. This post is about treating that command as a profiler for agent sessions. Not a profiler in the traditional CPU sense, but in the engineering sense: a tool that helps us understand where work is being spent, why it is being spent there, and which changes will make the next run better.

Performance has always mattered to me. In [my post about performance optimizations](/posts/Performance-optimizations/), I argued why an easy 12% improvement should not be considered marginal. The same principle applies to generative AI systems. If an agent can complete the same task with fewer model calls, fewer tokens, fewer failed attempts, and less context churn, that improvement matters. It reduces cost. It reduces latency. It reduces load on infrastructure. And at scale, it reduces electricity usage, data center demand, and water consumption.

Efficiency is not only a billing concern. It is an engineering concern.

## The Problem with Agent Logs

Traditional logs are hard because they contain too much data and too little interpretation. Agent logs have the same problem, multiplied by non-deterministic behavior.

A coding agent session can contain:

- system and developer instructions;
- user prompts;
- model requests and responses;
- tool calls and tool outputs;
- file reads and edits;
- terminal commands;
- validation attempts;
- failures and retries;
- context compaction events;
- token counts;
- cache behavior;
- selected agents, modes, skills, and models.

Manually reading this data is possible, but it is rarely efficient. The interesting issue is usually not on a single line. It is in the relationship between events.

For example, the expensive part of a session may not be one large model call. It may be a sequence of smaller mistakes:

1. The agent searched too broadly.
2. The first tool result was ambiguous.
3. It read too many files.
4. The context grew.
5. The model lost focus.
6. It tried a workaround.
7. That workaround failed.
8. It repeated the same pattern with slightly different inputs.

Nothing in that sequence looks catastrophic in isolation. Together, it becomes a costly run.

This is why agent logs should not only be inspected. They should be reasoned over.

## What /troubleshoot Changes

In GitHub Copilot for VS Code, `/troubleshoot` lets you ask questions about the agent session itself. Instead of manually opening logs, scanning JSON, and reconstructing the run in your head, you can ask the agent to analyze the session log for you.

The simplest form is:

```text
/troubleshoot check the logs for how to reduce token usage and improve results!
```

That prompt changes the shape of the work. You are no longer asking the model to solve the original coding task. You are asking it to inspect the execution of the task.

If you are improving a reusable agent or skill, run the diagnostic prompt more than once. A single pass usually focuses on the most obvious problems. To keep the loop going until the major issues are gone, I use:

```text
/troubleshoot check the logs for how to reduce token usage and improve results! repeat until no major issue is found!
```

The command can look at the session evidence and identify patterns such as:

- repeated searches that could have been replaced by one precise query;
- large tool outputs that consumed unnecessary context;
- missing constraints in the original prompt;
- skills or agents that were loaded too late, skipped, or invoked unnecessarily;
- commands that failed because assumptions were not checked first;
- validation loops that could have been shorter;
- places where the agent used broad file reads instead of a targeted symbol or search operation;
- opportunities to cache, summarize, or precompute context;
- instructions that caused excessive caution, verbosity, or redundant checks.

This is observability as conversation. You do not need to know the exact log schema before you begin. You can ask a natural language question and get an analysis that maps raw events back to engineering decisions.

## Profiling, Not Blaming

It is useful to think of `/troubleshoot` as a profiling tool, not a blame tool.

When we profile a program, we do not ask why the CPU was foolish enough to spend 40% of its time in one function. We ask why the program structure causes that work to dominate. The same mindset applies to coding agents. If a run was expensive, slow, or messy, the question is not whether the model was bad. The question is what in the workflow caused the agent to spend resources in the wrong places.

Sometimes the cause is the prompt. Sometimes it is an incomplete skill. Sometimes it is a missing tool. Sometimes it is a repository structure that makes the right path hard to discover. Sometimes it is simply that the task needs a better validation command.

The session log gives us evidence. `/troubleshoot` helps turn that evidence into hypotheses.

## Use the Default Agent and a Strong Reasoning Model

For the diagnostic pass, I prefer using the default agent with a high-reasoning model.

That sounds contradictory in an article about saving cost, because stronger reasoning models are more expensive. But the economics are different. The diagnostic run is not part of the production workflow. It is an investment in improving the production workflow.

A weaker model may summarize the logs but miss the deeper pattern. A stronger reasoning model is better at connecting events across the session:

- a vague user prompt caused broad exploration;
- broad exploration produced large tool outputs;
- large outputs polluted context;
- polluted context caused the agent to lose the original constraint;
- the agent then spent extra turns rediscovering the task.

That is the kind of causal chain worth finding. It may cost more once, but it can save much more every time the agent or skill runs afterward.

Use expensive reasoning where it reduces repeated waste. Avoid expensive reasoning where it merely decorates a one-off answer.

## Conclusion

Coding agents are becoming part of the development pipeline, and development pipelines need observability. We should not accept agent runs as mysterious sequences of prompts, tool calls, retries, and bills. We should inspect them, profile them, and ask why they behaved the way they did.

`/troubleshoot` gives us a practical way to do that inside GitHub Copilot for VS Code. It turns session logs into something we can reason about using natural language. That matters because the expensive part of an agent run is often not a single obvious mistake. It is the accumulation of broad searches, repeated workarounds, unstable context, poor cache usage, and late validation.

The goal is simple: make the next run better than the last one. Fewer wasted tokens, fewer failed detours, better cache reuse, clearer prompts, and more reliable results. That is not only cheaper. It is better engineering.
