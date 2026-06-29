---
layout: post
read_time: true
show_date: true
title: "From Hero Prompts to Shared AI Infrastructure"
date: 2026-06-29
img_path: /assets/img/posts/20260629
image:
  path: /assets/img/posts/20260629/SlideRule.jpg
tags: [ai, copilot, agents, cli, workflow, automation]
category: ai
meta_description: "Why AI agent workflows need versioned guardrails, shared repository knowledge, custom agents, hooks, and repeatable validation."
---

I use generative AI because I want to automate work.

That may sound obvious, but it changes the argument about coding agents.

The goal is not to sit beside an AI assistant and manually control every step. If I wanted to do that, I would just do the work myself. The useful promise of agentic development is that I can delegate exploration, planning, implementation, review, validation, and follow-up work to a system that can move faster than one person typing prompts into a chat box.

But software engineering has a non-negotiable requirement: we need repeatability.

Generative AI is useful precisely because it is flexible, adaptive, and capable of handling messy context. It is also nondeterministic. The same task may be decomposed differently tomorrow. The same model may choose a different file, a different command, a different validation path, or a different stopping point. That is not a reason to avoid automation. It is a reason to put deterministic safeguards around it.

That is the real problem with hero prompts.

A hero prompt is the long, carefully tuned instruction one developer writes to make an agent behave well in a specific session. It can make that developer look very effective for one task. It can encode taste, workflow, architectural memory, tool preferences, and validation habits. But if that knowledge lives only in one person's head, terminal history, chat history, or local setup, the team has not built an engineering system. It has built a dependency on a person and a moment.

The useful parts of an AI workflow need to be explicit, versioned, reviewed, and committed with the repository.

## Personal Prompting Is Not Infrastructure

Experienced developers usually write better prompts.

That is fine. It is also not enough.

The problem is not that prompt writing requires skill. Many engineering practices require skill. The problem is that personal prompting often hides the parts that should become shared infrastructure.

There is a useful parallel with low-code. Low-code is valuable up to the point where the workflow needs to scale beyond the person who assembled it. The first version is fast because the platform hides complexity. The later version becomes hard because the hidden complexity is exactly what the team needs to review, test, version, debug, and reuse. Personal agent workflows have the same failure mode when prompts become the place where architecture, validation, permissions, and operational knowledge quietly accumulate.

The same pattern appears again and again:

- one developer learns which validation command catches the real regression;
- another learns which directories the agent should inspect before editing;
- another learns which files must never be changed by an implementation worker;
- another learns that review agents should be read-only;
- another learns that parallel workers need a consistent output format before their results can be reconciled.

If that knowledge stays in private prompts, it decays.

Worse, every session pays for it again. The prompt gets longer. The context gets noisier. The agent spends tokens rediscovering rules that should already be encoded in the project.

The prompt should be short and high impact. It should express the task, not re-teach the operating model.

That only works when the durable knowledge moves out of the prompt and into versioned project assets.

## Automation Still Needs Control

The important feature of a coding harness is not where it runs. It is whether it exposes enough control surface to make automation governable.

As I described in [Custom Agents in GitHub Copilot: VS Code, CLI & Cloud](/posts/Copilot-Custom-Agents/), custom agents are not interesting only because they let me write another prompt. They are interesting because they turn agent behavior into something I can shape with explicit configuration.

With custom agents, I can control things like:

- which model an agent should use;
- which model fallback chain should apply when the preferred model is unavailable, too expensive, or the wrong fit for the moment;
- which tools that agent can access;
- whether the agent is visible to users;
- whether the model may invoke it automatically;
- which other agents may call it;
- whether a handoff should create a human checkpoint;
- whether an agent should be read-only, implementation-capable, or validation-focused.

That is not manual micromanagement. That is engineering control.

I do not want to manually decide every file read, every tool call, every branch of a plan, or every small implementation step. I want the harness to automate those decisions where automation is appropriate. But I want deterministic boundaries around the nondeterministic work.

That distinction matters.

Manual control says: "Ask me before you do anything."

Engineering control says: "Work autonomously inside these explicit constraints, then prove what you did."

The second model is the one I want.

## Version the Safeguards

Once you accept that AI usage should become part of the development workflow, the next step is straightforward: the safeguards belong in source control.

That includes:

- repository instructions in `AGENTS.md` or `.github/copilot-instructions.md`;
- reusable task knowledge in skills;
- custom agent definitions that encode role, model, tool access, visibility, and invocation behavior;
- hooks that run deterministic checks at known lifecycle points;
- MCP configuration that defines which external tools are available;
- repository-backed memory that carries durable context with the code;
- plugins that bundle agents, skills, hooks, and MCP servers into distributable packages.

These are not isolated features. Together, they form the AI infrastructure of the repository.

The repository becomes the source of truth for how AI work should happen in that codebase. Not because every action is predetermined, but because the boundaries, permissions, validation steps, and reusable knowledge are inspectable.

For example, a reviewer agent should not have the same tool surface as an implementer. That should not depend on remembering the right phrase in a prompt. It should be encoded in the agent definition.

```markdown
---
name: app-reviewer
description: Reviews proposed changes for correctness, maintainability, and policy violations.
model: Claude Sonnet 4.6 (copilot)
target: vscode
tools: ['search', 'read']
user-invocable: false
disable-model-invocation: true
---

Review the implementation plan, changed files, and validation output.
Do not edit files. Report only blocking issues, missing validation, and residual risk.
```

That file is not just a prompt. It is a boundary.

The same idea applies to hooks. A prompt can ask an agent to run tests. A hook can make the check part of the workflow.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "python3 .github/hooks/scripts/guardrails.py",
        "timeout": 5
      }
    ]
  }
}
```

The exact hook may differ by repository. The point is the same: deterministic safeguards should not live as folklore.

## Squads Are Better Than Hero Prompts

My preferred pattern is a squad.

One orchestrator coordinates specialized members. Some agents are visible to the user. Some are intentionally hidden. Each has a narrow role, a narrow tool surface, and a model strategy aligned with the job.

That looks more like engineering than prompting.

The important part is not the exact shape of the squad. The important part is that the squad definition can be reviewed and improved like any other workflow asset.

For example, an orchestrator might be allowed to read, search, delegate, and write session memory, but not edit files directly.

```markdown
---
name: app-orchestrator
description: Coordinates feature implementation across planning, coding, review, and validation agents.
target: vscode
model:
  - GPT-5.4 (copilot)            # 250/1,500 AIC per 1M — pipeline coordination, extended 24h cache retention
  - Claude Sonnet 4.6 (copilot)  # 300/1,500 AIC per 1M — cross-family fallback
  - Claude Sonnet 4.5 (copilot)  # 300/1,500 AIC per 1M — within-family fallback
tools: ['search', 'read', 'agent', 'vscode/memory']
agents: ['app-planner', 'app-implementer', 'app-reviewer', 'app-verifier']
user-invocable: true
---

Coordinate the squad. Do not edit files directly.
Write the task brief to `/memories/session/app-brief.md`, invoke the right specialists,
and return a concise outcome with validation status and residual risk.
```

An implementer can have write access. A reviewer can be read-only. A verifier can run commands but avoid changing source files. Each agent can also define a model fallback chain: start with the model that best fits coordination, then fall back across model families or versions when cost, latency, capacity, or quality trade-offs change. That is another form of control. The repository does not just say "use a smart model"; it records the preferred order of execution.

The orchestrator decides the sequence, but the repository defines the operating envelope.

That is where deterministic control belongs. The squad pattern defines the roles and boundaries. The next question is what happens when the harness has a different philosophy about creating those squads.

## Copilot CLI Is a Different Harness

This is where [Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli) exposes a different tradeoff.

It is still Copilot, but it is not just VS Code Copilot without the editor. It is a different coding harness with a different philosophy about custom agents, delegation, and control.

In VS Code, the model I described above is explicit. I can define an orchestrator. I can define subagents. I can decide which tools each agent receives. I can hide internal agents from the user. I can decide whether another agent may invoke them automatically. I can put a human checkpoint between planning and implementation. The system gives me a lot of surface area for turning agent behavior into project infrastructure.

Copilot CLI leans in a different direction. It tries to automate more of the coordination work for me. Instead of asking me to design every handoff, it focuses on creating and dispatching subagents automatically. That can be valuable. It lowers the amount of harness knowledge a developer needs before they can use multi-agent execution.

The clearest example is the built-in [Rubber Duck agent](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/rubber-duck). In VS Code, I might define an explicit `app-reviewer` agent, give it read-only tools, hide it from users, pin it to a model from a different family than the specialist agents it reviews, and let the orchestrator invoke it at the right checkpoint. That makes adversarial review a repository-defined control instead of a hope that the same model will notice its own blind spots. In the CLI, Rubber Duck covers much of that reviewer role as a built-in critic. Copilot can ask it for a second opinion on a plan, implementation, or test strategy, and the critic is designed to report substantive issues rather than edit files itself.

That is a useful abstraction. It also shows the philosophical difference. The CLI replaces some explicit squad wiring with built-in delegation behavior.

But there is a tradeoff.

When the harness delegates the complexity of orchestration, it also asks me to hand over part of the control model.

The CLI currently gives me two practical ways to build a multi-agent squad.

The first is to define the squad as a single custom orchestrator agent. That agent contains the workflow and the specification of the specialists it should create or invoke. This is close to the pattern I described in [the custom agents post](/posts/Copilot-Custom-Agents/): one entry point coordinates planning, implementation, review, and validation.

That shape is convenient because the workflow is committed as one file. A teammate can inspect it. A pull request can improve it. The agent can describe the sequence, the evidence each worker should return, and the conditions under which work should stop.

But the file becomes long quickly. It has to carry both orchestration logic and subagent specifications. The more specialized the squad becomes, the more the orchestrator turns into a compressed operating manual.

The bigger problem is tool control. If the subagents are described inside the orchestrator prompt rather than as independent agent definitions with their own tool surfaces, I cannot reliably say that the reviewer is read-only, the verifier can run commands but not edit files, and the implementer can write source code. The prompt can request those boundaries, but the harness is not enforcing them as separate capability envelopes for each worker.

That matters because the entire guardrails argument depends on the difference between asking and constraining.

A prompt says:

```markdown
Use a review subagent. It should only inspect the diff and report issues.
```

A capability boundary says:

```markdown
---
name: app-reviewer
tools: ['search', 'read']
user-invocable: false
---

Review proposed changes. Do not edit files.
```

Those are not equivalent. One is an instruction. The other is an enforceable shape of work.

The second option is to use [`/fleet`](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet).

`/fleet` is appealing because it pushes the automation further. It can take a task or plan, decompose it into independent pieces, and run those pieces through parallel subagents. It may use existing custom agents when they match the work, or it may use built-in agents when they are enough.

That is useful. It is also a very different control model.

With `/fleet`, I am not defining the orchestrator. The orchestrator is implicit. The harness decides how to split the work, which workers to use, what context each worker should receive, and how the results should be recombined. The command gives me parallel delegation without asking me to write the orchestration layer.

That is the point of the feature. It is also the source of tension.

If the orchestration logic is implicit, it is harder for a team to review. If the worker selection is implicit, it is harder to guarantee that the same kinds of work will be routed the same way tomorrow. If the output contract is implicit, it is harder to enforce consistent evidence across workers. And if `/fleet` uses defined custom agents as possible workers, those agents have to exist in the visible agent surface even when I do not want users to call them directly.

That last part is more than cosmetic.

In a squad, many agents are implementation details. I may want a public orchestrator called `app-builder`, but I do not want users to manually invoke `app-reviewer`, `app-verifier`, `app-migration-reader`, or `app-test-fixture-writer`. Those agents exist so the orchestrator can compose work safely. Listing all of them to the user makes the workflow noisier and weakens the idea that the repository exposes a small number of supported entry points.

So the CLI gives me a real tradeoff:

- the single-orchestrator pattern is shareable, but it tends to become a large prompt and cannot define strong per-subagent tool boundaries;
- `/fleet` gives me automatic parallel delegation, but the orchestrator is implicit and the team cannot review or version the decomposition strategy directly;
- custom agents can help `/fleet`, but they may also become visible user-facing choices even when they were meant to be private squad members.

That does not make Copilot CLI bad. In many cases, it is exactly the right abstraction. A developer who does not want to learn the details of VS Code custom-agent orchestration can still get useful parallel work from the CLI. The harness absorbs complexity and turns a broad task into multiple worker contexts.

But the cost is important: less harness knowledge is required up front, while some of the shared workflow knowledge becomes harder to capture, review, and reuse as team infrastructure.

That is the opposite side of the guardrails argument.

## The CLI Needs Repository Knowledge Too

The answer is not to make the CLI more manual.

The answer is to make sure the durable parts of the workflow still land in the repository.

Copilot CLI already has useful bridges. Session history can be searched, resumed, summarized, exported, or shared. [`/chronicle improve`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/chronicle) can mine past sessions for recurring mistakes and suggest updates to `.github/copilot-instructions.md`. In VS Code, [`/troubleshoot`](/posts/Profiling-Coding-Agents-with-Troubleshoot/) can serve a similar purpose by turning the current agent session into inspectable evidence: tool calls, retries, errors, context churn, validation attempts, and places where the workflow spent unnecessary effort. Those tools matter because they create a path from lived agent work back into durable project knowledge.

But the end state should still be committed files.

If a fleet run reveals that test workers need a specific validation command, that belongs in instructions or a skill. If review workers need a different output format from implementation workers, that belongs in a reusable agent or workflow description. If every worker must report changed files, risks, and validation evidence before the parent accepts the result, that belongs in instructions, hooks, or a committed squad specification.

This is the feedback loop I want:

1. Use Copilot CLI or `/fleet` to automate parallel work.
2. Observe where workers succeed, fail, duplicate effort, expose too many entry points, or need steering.
3. Use session history, exported transcripts, `/chronicle improve`, and human review to identify recurring lessons.
4. Promote those lessons into committed instructions, skills, agents, hooks, memory, or plugins.
5. Let the next automated run inherit better safeguards.

That makes Copilot CLI a useful pressure test for repository AI infrastructure. It shows where automation is easy because the repository already carries the operating model, and where the harness has to infer too much because the safeguards are still trapped in one person's prompt or one transient fleet run.

## Repository Knowledge Makes Delegation Practical

This is why repository-backed knowledge matters beyond any single command.

If the knowledge lives in the repository, a long-running task does not depend on one developer's local chat history or on a prompt they forgot to save. A clone or worktree gives a local agent, remote machine, cloud agent, or background runner both the codebase and the AI infrastructure around it.

That is a stronger operational model.

The behavior travels with the repository. The agent receives not only the source code, but also the rules, context, vocabulary, workflow knowledge, and deterministic checks that make the source code understandable.

That makes remote execution easier to trust, easier to reproduce, and easier to share across the team.

The same idea applies to memory. Many memory approaches, including ones inspired by Andrej Karpathy's LLM wiki style of knowledge organization, make it possible to keep durable agent knowledge directly in the repository as Markdown files instead of hiding it behind a vector database. Markdown is inspectable, reviewable, diffable, and easy to evolve in pull requests.

Google's [Open Knowledge Format (OKF)](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing) points in a similar direction: simple knowledge stored as Markdown, structured with YAML frontmatter, optional indexes, optional logs, and ordinary links between concepts. I like that because it keeps the canonical knowledge human-readable while still being structured enough for agents to traverse.

Repository memory should not be reduced to "poor man's RAG." Its value is broader. It can describe architecture, workflows, domain vocabulary, operational playbooks, validation rules, and historical decisions. A vector database may still have a role, but the canonical memory should survive tooling changes and remain useful without a specific retrieval backend.

## The Real Win Is Shared Engineering Capacity

The biggest benefit is not that the model behaves better for me.

It is that the whole team benefits from the same accumulated knowledge.

That includes junior engineers, new joiners, occasional contributors, and senior engineers who should not have to remember every bit of harness-specific ceremony before asking for help.

Strong engineers will still write better prompts. They should. But they should spend that effort where it matters most: on the task itself, on architecture, on trade-offs, and on review. They should not spend it repeatedly restating the same repository rules, tool constraints, and execution choreography.

When the harness is designed well, short prompts become possible because the long knowledge already exists in the system.

That is the outcome I want:

- automation instead of constant manual steering;
- explicit agent roles;
- constrained tool access;
- deterministic hooks and validation gates;
- reusable skills and custom agents;
- repository-backed memory;
- human checkpoints where risk is high;
- repository history for continuous improvement.

That is not less control.

It is better control.

## Conclusion

The point of all this is not to slow agents down with ceremony.

The point is to let them do more.

Copilot CLI makes that direction clear in a slightly uncomfortable way. It is powerful because it automates delegation. It can create worker contexts, run parallel work, and reduce the amount of harness-specific knowledge a developer needs before getting useful results.

But automation is not the same thing as shareable engineering control.

If the squad is hidden inside one large orchestrator prompt, the team can version the file but cannot strongly constrain each subagent's tools. If the squad is created through `/fleet`, the team gets parallel execution but not a reviewable orchestrator. If all custom agents must be visible so the CLI can use them, implementation details leak into the user-facing agent list.

Those tradeoffs are manageable, but they should be named.

The repository should become the control plane for agentic work. Instructions, skills, hooks, custom agents, MCP configuration, plugins, repository memory, and `/chronicle improve` are useful when they make agent behavior inspectable, repeatable, and improvable. Some parts automate execution. Some parts inspect what happened. Some parts promote the lessons back into committed project assets.

Together, they create a loop where the next run can inherit more knowledge and better safeguards than the last one.

That is the standard I care about.

An AI workflow should be able to automate meaningful work, delegate across specialized agents, run with constrained tool access, produce evidence, pass deterministic checks, and leave behind improvements that the whole team can review. If it cannot do that, the workflow may still be useful, but it is still too personal.

The goal is not to create better hero prompts. The goal is to automate more work while keeping engineering discipline in the repository, where the team can inspect it, change it, and trust it.
