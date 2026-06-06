---
layout: post
read_time: true
show_date: true
title: ".NET/C# Development in the Code Agents Era"
date: 2026-04-26
img_path: /assets/img/posts/20260426
image:
  path: /assets/img/posts/20260426/Robots.jpg
tags: [ai, llm, code agents, dotnet, csharp, aspire, analyzers, hooks, productivity, github copilot, claude code]
category: ai
meta_description: "How deterministic .NET tools like analyzers, tests, Aspire, and hooks create a stable foundation for high-quality automation in the code agents era."
---

Code agents are changing how we build software. No longer by simply producing isolated snippets or filling in boilerplate, but by participating directly in the development workflow. They read entire solutions, propose changes, refactor code, and interact with distributed systems. To work effectively with them, our codebases must be structured in a way that both humans and agents can understand and evolve.

Code agents introduce a new layer of automation, but automation alone does not guarantee quality. What actually guarantees quality are the tools and constraints that already exist in the .NET and C# ecosystem. These tools were originally designed to help human developers write consistent and maintainable code. In the code agents era, they become essential. Conventions, analyzers, tests, and orchestration frameworks give agents the structure they need to operate safely. While instruction files, skills, agents, and hooks define how automation behaves, the .NET toolchain defines what high quality code looks like.

A key reason is determinism. Code agents, like any LLM based system, are inherently non-deterministic. The same prompt can produce different outputs depending on context, temperature, or subtle changes in surrounding code. The .NET toolchain, on the other hand, is deterministic by design. Tools like analyzers, formatters, compilers, and test runners always produce the same result given the same input. This determinism stabilizes the workflow. It gives agents a fixed reference point and prevents small variations in agent behavior from accumulating into architectural drift.

This post focuses on the deterministic tools already present in the .NET development cycle, the ones that help human developers today and become essential when code agents start contributing to your codebase.

---

## 1. Conventions as Contracts: .editorconfig, dotnet format, and Instructions

Agents operate best in environments with clear and deterministic rules. A strict [.editorconfig](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/code-style-rule-options) file removes ambiguity from formatting and naming. It defines indentation, spacing, naming conventions, import ordering, and other style rules in a way that editors and IDEs can apply automatically. This ensures that every contributor, human or agent, works within the same constraints.

The [`dotnet format`](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-format) CLI command builds on this by applying those rules consistently across the entire solution. It follows the rules defined in `.editorconfig`. The tool fixes formatting issues, normalizes imports, and enforces style rules. Anything it cannot fix automatically becomes a clear signal that the remaining issues must be resolved manually. When `dotnet format` exits with code 0, the codebase is fully compliant with the conventions defined by the project.

This is where determinism matters. Agents may generate slightly different formatting or whitespace depending on context. `dotnet format` removes that variability. It ensures that the final result is stable, predictable, and aligned with the project’s standards.

These conventions should also be reflected in your agent instructions, for example in an **[AGENTS.md](https://agents.md/) or CLAUDE.md** file. Instructions remove ambiguity and define what “done” means in operational terms. Sentences like:

> Run `dotnet format` to ensure code style compliance. Issues not automatically fixed must be resolved manually.  
> A feature is not complete until `dotnet format` exits with code 0.

give agents explicit rules to follow. They also give human developers the same rules, which keeps the workflow aligned. Instructions become part of the contract. They define expectations in a way that both humans and agents can follow without interpretation.

---

## 2. Warnings as Errors

Enabling [warnings as errors](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/errors-warnings#treatwarningsaserrors) is another deterministic safeguard. This setting tells the compiler to treat all warnings as build failures. It is a project-level configuration, and in solutions with many projects, it is best to define it once in a shared [`Directory.Build.props`](https://learn.microsoft.com/en-us/visualstudio/msbuild/customize-by-directory?view=visualstudio#directorybuildprops-and-directorybuildtargets) file.

To enable it, add the following to your `.csproj` or to `Directory.Build.props`:

```xml
<PropertyGroup>
  <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
</PropertyGroup>
```

`Directory.Build.props` centralizes configuration for all projects under a directory tree. Instead of repeating the same settings across dozens of `.csproj` files, you define them once and every project automatically inherits them. This ensures consistency and prevents individual projects from drifting away from the expected configuration.

Agents depend on compiler feedback to understand what is acceptable and what is not. A permissive compiler leaves too much room for interpretation. A strict compiler provides a clear boundary. Nullability, unreachable code, unused variables, and API misuse become explicit constraints. Because the compiler is deterministic, these constraints are always reported the same way. This stability improves both agent generated code and human written code.

---

## 3. Roslyn Analyzers as Architecture Enforcement

[Roslyn analyzers](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview?tabs=net-10) provide compile time checks that enforce coding standards, architectural rules, and domain constraints. An analyzer inspects your code during compilation and reports diagnostics when rules are violated. This makes analyzers a deterministic way to encode expectations directly into the build.

The .NET SDK includes a set of built-in analyzers that cover common correctness, performance, and style issues. NuGet also offers many analyzer packages that address specific frameworks or concerns, such as ASP.NET Core, Entity Framework Core, or security-related rules. When these are not enough, teams can create project-specific analyzers to enforce rules that do not exist in the available analyzer sets and that reflect constraints unique to the project’s architecture or domain model.

To add custom analyzers to a solution, you typically create a separate analyzer project. This is a standard C# class library that references the Roslyn SDK and implements rules by analyzing syntax trees or semantic models. After implementing the rules, you reference the analyzer project from the projects you want to analyze by adding a `ProjectReference` with analyzer semantics:

```xml
<ProjectReference Include="..\BookStore.ApiService.Analyzers\BookStore.ApiService.Analyzers.csproj"
OutputItemType="Analyzer"
ReferenceOutputAssembly="false" />
```

This tells MSBuild to load the analyzer during compilation without referencing its assembly at runtime.

Analyzers are fully deterministic. Given the same code, they always produce the same diagnostics. This determinism is important for agent driven development. If an agent introduces code that violates a rule, the analyzer will fail the build every time until the issue is fixed. This forces agents to correct misbehavior and keeps the architecture consistent over time.

### Agents can help develop analyzer rules

Modern code agents can also assist in the creation and evolution of analyzer rules. They can:

- propose rule definitions based on recurring patterns in the codebase  
- generate the initial analyzer and code fix scaffolding  
- refine rules based on failing diagnostics  
- update analyzers as the architecture evolves  

This creates a feedback loop where analyzers guide agents, and agents help maintain and evolve the analyzers. The result is a system where architectural rules remain explicit, enforced, and continuously improved.

---

## 4. Testing as the Behavioral Contract

In the context of agents, testing becomes even more important than in traditional development. Tests are the most reliable and deterministic way to validate behavior. They also provide a clear signal to agents about whether a feature is complete.

Your instructions should explicitly tell agents to run the full test suite before finishing any feature. This is the testing equivalent of running dotnet format. It defines what “done” means in a way that is unambiguous and machine enforceable.

When a test fails, there are only three possible reasons:

- The implementation is wrong
- The test is outdated
- The behavior intentionally changed

Agents infer which case applies by analyzing surrounding code, naming patterns, domain rules, and the consistency of behavior across the solution. This makes tests a powerful feedback loop. They guide agents toward correct behavior and prevent regressions. Because test execution is deterministic, the same failure always produces the same signal, which stabilizes the workflow.

- Unit tests describe domain rules.  
- Integration tests describe how components interact.  
- End to end tests, for example using [Playwright](https://playwright.dev/), describe user flows.

Agents rely on these tests to validate changes. Without a solid test suite, agents cannot safely refactor or extend the system. With one, they can operate confidently and autonomously.

---

## 5. Aspire as the Agent Native Application Model

[Aspire](https://aspire.dev/) introduces a new model for building distributed applications, and it aligns naturally with agent driven development. Although Aspire began as a .NET focused application model, it now supports additional technology stacks. This allows teams to orchestrate polyglot systems with a single, consistent toolset. For code agents, this is important because it gives them a unified view of the entire system, not just the .NET parts.

Aspire provides several capabilities that are especially valuable for code agents.

### Service orchestration

Aspire defines and runs multi service applications in a consistent and predictable way. Agents benefit from this because they can rely on a stable environment where services are always started, configured, and wired together the same way.

### Service discovery and connection management

Aspire automatically wires connection strings, URLs, ports, and credentials between services. This removes a large class of errors that agents might introduce when modifying configuration manually. It also gives agents a clear and deterministic map of how services communicate.

### Unified configuration

Aspire centralizes configuration across the solution. Agents can read and update configuration in a structured and deterministic way, without guessing where values come from. This reduces the number of model calls needed to understand the system.

### Observability and telemetry access

Aspire provides logs, metrics, traces, and dependency maps out of the box. This is one of the most important features for code agents. Instead of asking the model to infer system behavior from code alone, the agent can:

- inspect traces  
- analyze logs  
- view dependency graphs  
- check metrics  
- detect failures  
- understand performance patterns  

directly from Aspire’s telemetry.

This reduces the number of model calls required to reason about the system. It also reduces token usage because the agent does not need to load large amounts of source code or context into the model. Telemetry gives the agent a precise and low cost view of what is happening in the system.

### Local first development

Aspire allows the entire distributed system to run locally with full fidelity. This is ideal for agents because they can:

- run the system  
- observe behavior  
- run tests  
- inspect logs  
- validate changes  

all without requiring cloud infrastructure. Local determinism is especially important for agents because it ensures that every run produces the same signals.

### Agent integration

Aspire now treats agents as first class services. They appear in the dependency graph, receive configuration, participate in observability, and interact with other services. This makes Aspire a natural runtime for agent based systems. Agents can call APIs, interact with databases, and participate in workflows with the same visibility and governance as any other service.

Aspire’s deterministic orchestration stabilizes agent behavior. The environment behaves the same way every time, which gives agents a reliable foundation for reasoning and execution.

---

## 6. Hooks as the Governance Layer

[Hooks](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks) extend **code agents** with a programmable governance layer. They allow **engineering workflows** to intercept agent actions, enforce rules, and collect telemetry.

 Hooks can enforce deterministic guardrails and automation. They can run scripts that validate behavior, enforce conventions, or perform checks before allowing an agent to continue. These scripts can be implemented using [**file-based C#**](https://learn.microsoft.com/en-us/dotnet/core/sdk/file-based-apps), which is a lightweight and modern way to write C# code without project scaffolding. File-based C# makes hook scripts easy to maintain, version, and evolve.  

### Agents can help develop hook scripts

Modern code agents can also assist in creating and improving hook scripts. They can:

- propose hook logic based on patterns in the codebase  
- generate initial file-based C# script implementations  
- refine scripts when hooks detect recurring issues  
- evolve hook behavior as architecture and conventions change  

This creates a feedback loop where hooks guide agents, and agents help maintain and extend the hooks. The result is a governance layer that stays aligned with the system as it grows.

Governance hooks ensure that generated code respects conventions, analyzers, and architectural boundaries. Telemetry hooks provide insight into how agents are used and where they struggle. Security hooks prevent unsafe patterns or accidental leaks. Workflow hooks integrate agents into formatting, testing, documentation, and other automated steps. Domain-specific hooks inject business vocabulary and invariants into the agent’s reasoning.

Hooks provide deterministic enforcement at development time. Aspire provides deterministic orchestration at runtime. Together, they create a controlled environment where agents can operate safely.

---

## 7. A New Development Workflow

The workflow in the code agents era looks different.

- Developers express intent.  
- Agents generate or modify code.  
- Hooks enforce governance.  
- Analyzers enforce architecture.  
- Tests validate behavior.  
- Aspire orchestrates the system.  

The deterministic tools in this chain stabilize the non-deterministic behavior of agents. This is not about replacing developers. It is about creating a codebase that both humans and agents can evolve together.

---

## Practical Example: BookStore

Most of these practices, including conventions, analyzers, tests, Aspire, and hooks, are applied in my open-source project BookStore.

You can explore the implementation here: [https://aalmada.github.io/BookStore/](https://aalmada.github.io/BookStore/)

It serves as a concrete example of how a .NET solution can be structured to support both human development and agent driven automation.

---

## Conclusion

When conventions, analyzers, tests, hooks, and Aspire all work together, .NET becomes a platform that supports agents naturally. The goal is not to write more code, but to design systems that remain coherent as both humans and agents contribute to them. Deterministic tools provide the stability that non-deterministic agents need. That combination is what makes high quality automation possible.
