---
layout: post
read_time: true
show_date: true
title: "Agent Governance: The Control Plane for Coding Agents"
date: 2026-06-08
img_path: /assets/img/posts/20260608
image:
  path: /assets/img/posts/20260608/Typewriter.jpg
tags: [ai, agents, copilot]
category: ai
redirect_from:
  - /posts/Hybrid-Workflows/
meta_description: "Governance is the control plane that makes coding agents safe, predictable, and operable inside real engineering systems. It defines the boundaries of what an agent can do, how it is constrained, and how its actions are audited."
---

Coding agents have reached a point where they can perform meaningful, multi‑step work across an entire codebase. They can refactor dozens of files, rewrite architectural boundaries, introduce or remove dependencies, modify infrastructure code, run shell commands, and apply patches at scale. Once an agent can do all of that, we no longer have a convenience feature. We have automation with consequences. And automation with consequences requires governance.

Governance is the control plane that makes agents safe, predictable, and operable inside real engineering systems. It is not an optional layer. It is the foundation that allows an organization to trust an agent enough to let it touch real code. Without governance, agents drift. With governance, agents become safe automation.

## Why Governance Exists

Governance exists because agents are not deterministic, but software systems must be. An agent can generate correct code, but it can also generate incorrect code with equal confidence. It can follow instructions, but it can also forget them due to context compaction. It can improve architecture, but it can also break invariants without noticing. Governance ensures that the agent’s power is constrained by the rules of the system it operates in. It answers the operational questions: what the agent is allowed to do, what it must never do, how violations are detected, how regressions are prevented, and how actions are audited.

## The Governance Stack

Governance is a layered system, with each layer constraining and shaping the one below it.

The first layer is **instruction‑level governance**, which defines the agent’s identity, scope, allowed tools, and behavioral expectations. This is where we can declare that an agent performs safe refactors, or that it migrates APIs but never touches infrastructure, or that it only writes tests. Instructions define the intent of the agent, but intent alone is not enough.

The second layer is **tool‑level governance**, which defines what the agent’s hands can touch. Tools determine whether the agent can read or write files, which directories it may operate in, which shell commands it may run, whether it can call external APIs, and how much of the system it can influence. Tools turn “the agent can do anything” into “the agent can do exactly this.”

## Execution Isolation (Sandboxes)

Some harnesses provide built‑in sandboxing, but sandboxing does not need to be tied to a specific vendor. [Docker Sandboxes](https://www.docker.com/products/docker-sandboxes/) are a harness‑independent alternative: thin, ephemeral containers that isolate filesystem and network access. They provide a predictable execution environment where the agent can run code, tests, or transformations without touching the host. A sandbox defines the physical boundary of execution, while hooks and policies define the logical boundary of behavior.

A Docker Sandbox provides a minimal container with a controlled filesystem, no outbound network, and no privileged operations. It is fast to start, cheap to run, and easy to reset. For many teams, this becomes the default execution environment for agents, even when the harness itself does not enforce isolation.

In the areas where sandboxing and hooks overlap—such as preventing dangerous shell commands or writes outside the working directory—sandboxing is often the better choice. It is faster, more reliable, and enforced at the OS level. But the overlap is small. A sandbox cannot enforce architectural boundaries, domain invariants, dependency rules, semantic constraints, migration safety, test‑before‑apply requirements, diff validation, or commit hygiene.

Sandboxes protect the system from the agent.  
Hooks protect the codebase from the agent.

## Hook‑Level Governance

Hooks are where governance becomes programmable. They intercept agent actions before execution and enforce semantic, architectural, and domain‑specific rules. Hooks execute deterministic scripts—written in Bash, Python, [file‑based C#](https://learn.microsoft.com/en-us/dotnet/core/sdk/file-based-apps), or any language the team prefers. Because hooks are synchronous, they must be efficient and fail fast. They are not designed for heavy computation; they are designed for fast, predictable enforcement.

### Examples of hook rules that matter in real systems

- Reject diffs that introduce new dependencies without approval  
- Block modifications to infrastructure directories  
- Prevent changes to public APIs without versioning  
- Enforce architectural layering rules (e.g., domain cannot depend on UI)  
- Require tests to pass before accepting a diff  
- Reject changes that violate naming or structural conventions  
- Block writes outside the allowed workspace  
- Prevent deletion of migration files or schema history  

Hooks are not limited to restriction. They can also *augment* the agent’s capabilities. One example is the integration of GitNexus directly into a hook. Instead of letting the agent depend solely on text‑based search tools, a hook can [call GitNexus to provide a semantic](/posts/From-Grep-to-Graph/), parser‑aware view of the codebase. The hook enriches the agent’s context with symbol graphs, references, definitions, and dependency information before the agent begins reasoning. This turns the hook into a semantic accelerator: the agent still uses its normal tools, but the information it receives is deeper, more structured, and far more precise than anything it could infer from raw text search alone.

These are semantic constraints and augmentations that no sandbox can express.

## Organizational Governance

The next layer is organizational governance, which no harness can automate. It defines who can run which agents, who approves agent‑generated changes, who publishes or updates agents, who owns the policies, and who audits the traces. Governance is not only technical. It is also operational.

### Examples of organizational governance policies

- Restrict which teams can use cloud‑executed agents  
- Require human approval for specific categories of changes  
- Limit access to advanced or higher‑cost models  
- Enforce that only designated maintainers can publish or update agents  
- Require audit logs for all agent‑generated diffs  
- Allow agent usage only in repositories with test coverage above a threshold  
- Disable agent execution in regulated or high‑risk repositories  

These policies define the organizational boundary of trust.

## MCP‑Level Policies and Governance

Some runtimes expose a governance layer at the protocol boundary. [GitHub’s MCP server](https://github.com/github/github-mcp-server/blob/main/docs/policies-and-governance.md) is one example: it lets teams define which tools, resources, and prompts are exposed to agents. These rules live in the MCP server’s configuration and are versioned like any other code. They are not model instructions; they are server‑side policy.

In a [previous post](/posts/2026-06-01-Copilot-Custom-Agents/), I described how Copilot Custom Agents declare their allowed tools directly in the agent file’s frontmatter. That mechanism remains the first line of governance: the harness reads the agent definition and exposes only the tools explicitly listed there.

MCP governance operates at a different layer. Instead of defining allowed tools inside the agent, an MCP server defines which tools, resources, and prompts exist at all. Whoever operates the MCP server sets these rules. The harness connects to the server, retrieves the filtered capability surface, and exposes only those capabilities to the agent. Because the agent never sees forbidden tools or resources, it cannot call them, discover them, or bypass them.

This creates a clean separation of concerns:

- **Agent‑level governance** defines what the agent is *intended* to use.  
- **MCP‑level governance** defines what the environment is *willing* to expose.  
- **The harness enforces both** by intersecting the two capability surfaces.

Multiple harnesses already support governance MCP servers, including Copilot and Claude Code, with others adopting the protocol. This makes MCP a practical, interoperable way to define repository‑ or team‑specific capability boundaries without requiring enterprise‑level permissions.

MCP policies shape the interface.  
Hooks shape the behavior.  
Sandboxes shape the environment.

Together they form a layered, deterministic boundary around an otherwise non‑deterministic model.

## Governance and Observability

Governance defines the boundaries an agent must operate within; observability reveals how the agent actually behaved inside those boundaries. We can treat them as complementary layers. Governance constrains intent. Observability validates execution. Without observability, we cannot verify whether governance is effective. Without governance, observability becomes a passive record of whatever the agent decided to do.

I’ve written an entire post dedicated to [observability for coding agents](/posts/Observability-for-Coding-Agents/), covering traces, semantic telemetry, token economics, and the feedback loop that makes agent behavior measurable and debuggable. Observability turns policies into something we can inspect, reason about, and improve over time.

## Why Governance Becomes a Competitive Advantage

Most teams will adopt agents. Few will adopt governed agents. Governance provides safer automation, consistent architecture, predictable behavior, reduced risk, higher trust, and faster onboarding. Governance is not overhead. Governance is how agents scale across an organization. It is the control plane that allows teams to delegate work to agents without losing control. It is the difference between “I have an agent that can do this” and “I have an agent that I trust to do this.”
