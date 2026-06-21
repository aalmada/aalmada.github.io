---
layout: post
read_time: true
show_date: true
title: "The Architecture of Code Agents: Instructions, Skills, Agents, Hooks"
date: 2026-04-28
img_path: /assets/img/posts/20260428
image:
  path: /assets/img/posts/20260428/Merida.jpg
tags: [ai, code agents, architecture, skills, hooks, instructions]
category: ai
meta_description: "A practical guide to the four foundational building blocks of modern code agent harnesses: instructions, skills, agents, and hooks. Learn how to encode knowledge, enforce rules, and create safe, repeatable automation."
---

Most of us began our generative AI journey the same way:

- Write a prompt, get a code snippet, paste it into the project, adjust until it works.

It is useful, but it barely taps into what AI can do in real engineering environments.

The deeper issue is that we are not sharing knowledge:

- Each prompt lives only in the writer’s mind
- Every developer rediscovers the same conventions
- The model wastes tokens re-inferring rules it should already know
- Team knowledge never becomes system knowledge
- AI becomes a personal productivity trick instead of a shared engineering capability

Modern code agent harnesses fix this by giving us four foundational tools:

**Instructions, skills, custom agents, and hooks.**

These tools encode your architecture, constraints, domain knowledge, and guardrails. They turn AI from autocomplete on steroids into a repeatable, measurable, and safe engineering workflow.

---

## 1. Instructions: Project-Specific Rules the Model Cannot Infer Efficiently

Instructions are the explicit rules, patterns, and constraints that are specific to your project. A model might deduce some of them from the code, but not efficiently, reliably, or consistently across sessions.

They describe how *this* project works, not how programming works in general.

**Examples include:**

- Naming conventions
- Architectural boundaries
- Forbidden APIs
- Domain terminology
- Testing expectations
- Rules scoped to specific folders

**In short:**

> Instructions capture everything the model does not know efficiently and cannot deduce with consistency.

### AGENTS.md as the Standard, with Folder-Level Scoping

Across modern code agent harnesses, **[AGENTS.md](https://agents.md/)** has become the standard format for storing these instructions. It can be placed at the repository root for global rules or inside subfolders for domain-specific rules. This allows instructions to be contextualized so the model receives only the rules relevant to the part of the project it is working in.

#### Claude Compatibility

Claude Code uses **CLAUDE.md** for its instructions, but for compatibility, it supports delegating to the canonical file by adding the following line to `CLAUDE.md`:

``` markdown
@AGENTS.md
```

This line tells Claude to load instructions from `AGENTS.md` instead, so teams can maintain a single source of truth while still supporting Claude’s naming convention.

### The Golden Rule

> If the model can figure it out from the code, do not include it.

This rule is fundamental, not just for instructions, but for skills and agents as well. Models have a limited context window: the space where instructions, skills, agent definitions, code, and reasoning all compete for attention. Every item you add takes up part of that space. If you include rules, patterns, or knowledge that the model can easily infer from the codebase, or its part of its own knowledge, you’re wasting valuable context that could be used for more complex, project-specific, or non-obvious guidance. The result: less room for the information that actually makes a difference, and a higher risk that the model will miss critical details when generating or editing code.

Instructions, skills, and agent definitions are all loaded directly into the model’s context before it generates or edits code, so they actively shape its reasoning and output as live constraints rather than passive references. They are not meant for human readers or documentation; their only purpose is to control and configure how the model behaves during automation. Because these elements occupy part of the model’s context window, they should be as brief and focused as possible. Unnecessarily long content reduces the space available for code and reasoning, so keep them concise and essential.

### Why Instructions Matter

Without instructions, the model wastes tokens rediscovering rules, developers prompt inconsistently, and the model improvises instead of following your architecture. With instructions, behaviour becomes consistent, rules become shared and versioned, and context becomes deterministic. Instructions turn AI from a personal productivity tool into a shared, predictable engineering capability.

---

# 2. Skills: Reusable Knowledge the Model Cannot Infer Efficiently

Skills are reusable packages of knowledge that the model does not know and cannot infer efficiently. They usually are project-agnostic and can be shared across repositories, teams, and agent setups. A skill activates only when the model decides it is relevant to the current task, which keeps the context focused and efficient.

**In short:**

> Skills provide reusable knowledge that the model loads only when needed.

### How Skills Are Structured

**A skill is defined by a folder that contains a `SKILL.md` file and may include additional files or subfolders.**

The `SKILL.md` file contains a frontmatter section and regular markdown content. The frontmatter identifies the skill, describes what it provides, and gives the model the signals it needs to decide when the skill is relevant. The markdown body should remain short and focused. Any heavier material belongs in separate reference files within the same folder, which are only loaded when the model considers them useful. This keeps `SKILL.md` concise and prevents unnecessary context bloat.

### What Skills Can Contain

Skills may include scripts, instruction-like content, and reusable domain knowledge. Everything inside a skill must be information the model does not already know or cannot infer efficiently. If the content is something the model can already deduce, it does not belong in a skill.

### How Skills Are Loaded

The model always receives the descriptions of all available skills so it can evaluate which ones are relevant. The contents of a skill are loaded into the model's context only when the model determines they are relevant for the current task. This selective loading allows skills to add knowledge to the context only when needed, supporting efficient context management. The clarity and precision of the description in SKILL.md is the primary signal that guides this decision.

### Quality Requirements

Skills should be evaluated for accuracy, clarity, and structure. The content must be correct and genuinely useful. The description must clearly communicate when the skill applies. SKILL.md must remain short, with heavier material placed in reference files. This ensures skills remain predictable, reusable, and easy for the model to activate correctly.

#### Example: Anthropic's `skill-creator` Skill

Anthropic provides a [`skill-creator`](https://github.com/anthropics/skills/tree/main/skills/skill-creator) skill that includes an evaluation harness. By default, it uses Claude Code for evaluation, but it can be refactored to use other agent harnesses, such as Copilot CLI via the Copilot SDK. This flexibility allows teams to adapt the evaluation workflow to their preferred agent infrastructure.

### Where Skills Live: Global vs Repository Scoped

Skills can be defined globally or inside a repository, and the placement shapes how they evolve. Global skills act as shared organisational knowledge, reused across projects and teams. Repository-scoped skills, on the other hand, live alongside the codebase and evolve with it. Because they are versioned, reviewed, and refined through pull requests, they become part of the project’s living architecture, incrementally improved just like the instructions. This gives teams a balance between broad reuse and project-specific precision.

---

## 3. Custom Agents: Instructions That Define a Specific Execution Behaviour

Custom agents are sets of instructions that give the model a specific execution behaviour. Where instructions define the rules of the project, agents define how the model should act for a particular role, persona, or workflow. They allow teams to encode behaviours such as a reviewer, an implementer, or a documentation assistant, and ensure that these behaviours remain stable across sessions and across developers.

Each agent lives in a `.agent.md` file that contains a frontmatter section and regular markdown content. The frontmatter identifies the agent, describes its purpose, specifies which model it should use, and declares the tools it is allowed to access. Agents operate with a small, deterministic set of tools that keeps their behaviour predictable and auditable. They can read files, write files, append to files, create and delete files, list directories, inspect directory trees, search across the repository, apply patches, and execute commands through `run_command`. All higher-level operations such as running tests, formatting code, invoking linters, or generating documentation are performed through `run_command`, which keeps the tool surface simple, language-agnostic, and easy to govern through hooks.

The markdown body then provides the execution text that shapes how the model behaves when the agent is active, giving it the tone, reasoning style, and operational pattern expected for that role.

**In effect:**

> A custom agent provides the same role, the same behaviour, and the same execution pattern every time it is used.

Instead of relying on personal prompting habits, teams gain a library of well-defined, specialised agents that behave consistently for every developer and every task.

### Agents as Teams, Squads, or Fleets

In advanced setups, multiple agents can work together as a team (a.k.a. squad or fleet). Each agent operates with its own context window and can be assigned the most appropriate model for its specific task. This approach allows you to manage context usage more efficiently: instead of overloading a single agent with all instructions, skills, and code, you can delegate responsibilities to specialized agents. For example, one agent might focus on code generation, another on review, and another on deployment or compliance. By splitting work this way, each agent stays focused, context remains manageable, and the overall system can tackle more complex workflows without running into context limitations. This also enables you to leverage different models—using a lightweight, fast model for simple tasks and a more capable, larger model for complex reasoning—optimizing both cost and performance.

Modern code agents can invoke subagents either implicitly (based on the prompt and task) or explicitly (when directed by the user or workflow). This allows for flexible delegation of work and specialization. Custom agents provide more control over agent behavior, can be tailored for specific roles or workflows, and are easily shared across teams and projects for consistent automation.

### Where Agents Live: Global vs Repository Scoped

Just like skills, agents can be defined globally or inside a repository. Global agents provide consistent behaviours across many projects, while repository-scoped agents evolve with the codebase and benefit from versioning, reviews, and incremental refinement. This keeps agent behaviour aligned with the architecture and the team’s expectations as the system grows.

---

## 4. Hooks: The Safety Net, Governance Layer, and Deterministic Automation Engine

Hooks are the mechanism that lets teams supervise, constrain, and automate what code agents do.  
Where instructions, skills, and agents shape how the model thinks, hooks shape what the model is allowed to *do*.  
They intercept actions before or after they happen, giving teams a deterministic way to enforce rules, validate behaviour, and attach automation to the agent workflow.

Models are inherently non deterministic.  
Even with the same prompt, they may produce different outputs, and instructions may be partially forgotten due to context compaction or aggressive summarisation.  
Hooks solve this by providing a layer that is not probabilistic.  
They always run, they always evaluate the action, and they always enforce the rules.  
This makes hooks the only part of the system that guarantees consistent behaviour regardless of model drift or context pressure.

Hooks can run at several lifecycle points, but the most commonly used ones are `PreToolUse` and `PostToolUse`.  
These two events give teams the highest leverage because they wrap every tool call, allowing hooks to inspect the action, validate it, and decide whether it should proceed.  
Other hook types exist, but these two form the backbone of deterministic governance in agent workflows.

Hooks govern the same deterministic tool surface that agents rely on. Every tool call in the payload will be one of the core operations: reading files, writing files, appending files, creating or deleting files, listing directories, reading directory trees, searching files, applying patches, or executing commands through `run_command`. Since all complex actions flow through this small set of primitives, hooks can reliably inspect, validate, or block behaviour, and they can enforce rules even when the model forgets instructions due to non deterministic reasoning or context compaction.

Hooks also enable automation.  
Because they run synchronously around tool calls, they can trigger scripts, run linters, execute tests, update documentation, or collect telemetry.  
Synchronous execution means the agent must wait for the hook to finish before continuing, which ensures the workflow remains predictable and ordered.  
This is why hook commands must be brief: long running tasks would stall the entire agent loop and degrade the developer experience.

Hooks execute commands, and these commands can be implemented in multiple languages.  
They can run Bash scripts, PowerShell scripts, Python programs, or even file-scoped C# scripts.  
This flexibility allows teams to choose the right tool for the job while keeping hook logic simple, maintainable, and versioned inside the repository.  
Because hooks are just scripts, they integrate naturally with existing tooling and can evolve as the project grows.

**In effect:**

> Hooks give teams deterministic control over what agents can do, and a programmable way to attach automation to every action.

They are the final layer that turns code agents from helpful assistants into safe, governed, production ready engineering systems.

---

# 5. Creating These Tools: Code Generation as the Starting Point

All four tools — **instructions**, **skills**, **custom agents**, and **hooks** — can be created with code generation.  
The model can suggest them, draft them, refine them, and evolve them as the project grows.  
Instead of writing everything manually, teams can treat the model as a collaborator that proposes structure, fills in boilerplate, and adapts content based on the codebase.

The workflow is simple: describe what you want, let the model generate a first version, and then iterate.  
Because these files are plain text with frontmatter and markdown, they fit naturally into pull requests, reviews, and incremental improvement.  
The model can generate the initial shape of an AGENTS.md file, propose a new skill based on recurring patterns in the code, scaffold a custom agent for a new workflow, or draft a hook that enforces a safety rule.

Code generation is not just a convenience, it is how these tools become part of the development loop.  
The model can detect gaps, propose improvements, and keep the tools aligned with the architecture as it evolves.  
Teams still review and approve changes, but the model does the heavy lifting: drafting, rewriting, restructuring, and suggesting refinements based on real usage.

In practice, this turns the creation of these tools into a continuous, collaborative process.  
The model proposes, the team reviews, and the repository becomes the single source of truth for how the system behaves.  
Over time, the tools mature just like the codebase: versioned, reviewed, and improved through real work.

---

# 6. Conclusions

The four tools—**instructions**, **skills**, **custom agents**, and **hooks**—are the core capabilities provided by the code agent harness. They give teams a way to turn generative AI from a personal productivity trick into a shared engineering system. These tools capture the rules of the project, the reusable knowledge of the domain, the behaviours of specialised roles, and the guardrails that keep everything safe. Together, they create a predictable, versioned, and continuously improving layer of intelligence that sits alongside the codebase.

**How instructions, skills, and agents add context**

All three—**instructions**, **skills**, and **agents**—add context to the prompt being executed. The difference is in how and when they are loaded:

- **Instructions** are always added to the model's context for the relevant scope (repository or folder). They define the non-inferable rules and constraints that must always be enforced, so the model receives them every time it operates in that scope.
- **Skills** are only added to the model's context when the model determines they are relevant to the current task. This selective loading keeps the context efficient and focused, ensuring that only necessary knowledge is present for each operation.
- **Agents** add their own instructions and behavioral patterns to the context when they are invoked for a specific prompt or workflow. Activating a custom agent means its configuration and operational guidance are injected into the model's context for the duration of that task.

One principle underpins all of them: **the Golden Rule applies to instructions, skills, and agents alike**. Only include what the model cannot easily infer from the codebase. This preserves precious context space for the information that truly matters—project-specific, non-obvious, or high-value guidance. By following this rule, you ensure that your automation remains efficient, focused, and effective.

What makes this approach truly powerful is not just the tools themselves, but the way they evolve. Because they live in the repository, they are reviewed, refined, and shaped by real work. Because they can be generated and improved through code generation, they stay aligned with the architecture as it changes. And because they are shared across the team, they turn individual prompting habits into collective engineering capability.

This is how AI becomes part of the development process rather than an add-on. The model learns the project through instructions, gains expertise through skills, adopts roles through agents, and stays safe through hooks. The result is a system where AI contributes with consistency, clarity, and context, and where teams can scale their engineering practices without scaling their cognitive load.

To build truly effective and efficient code agent workflows, you need to go beyond the harness itself. For deeper strategies on context management, token usage, and adapting engineering practices to the code agent era, see these complementary posts:

- [Reducing Token Usage in Code Agents](https://aalmada.github.io/posts/Reducing-Token-Usage-in-Code-Agents/)
- [Dotnet Development in the Code Agent Era](https://aalmada.github.io/posts/Dotnet-Development-in-the-Code-Agent-Era/)
