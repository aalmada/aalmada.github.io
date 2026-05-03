---
layout: post
read_time: true
show_date: true
title: "APM: Package Management for AI Agent Configuration"
date: 2026-05-03
img_path: /assets/img/posts/20260503
image: Candelária.jpg
tags: [ai, code agents, apm, package management, instructions, skills, hooks, productivity, github copilot, claude code]
category: ai
meta_description: "APM applies npm-style package management to AI agent configuration, making your team's instructions, skills, agents, and hooks versioned and reproducible."
---

Building agent configuration is the easy part. Keeping it consistent is not.

You write a useful set of instructions. You craft a skill that encodes how your team handles a specific workflow. It works. Then a teammate sets up a new repository, and things start to diverge:

- They copy the files manually, or start from scratch
- A hook gets fixed in one place but never propagates to others
- An AGENTS.md references a convention the team abandoned months ago
- Nobody knows which repository is running which version of what

This is the copy-paste problem. And it is the same problem npm solved for JavaScript.

---

## APM: The npm for Agent Configuration

[APM](https://microsoft.github.io/apm/) (Agent Package Manager) is a package manager for AI agent configuration. It applies the same dependency management discipline that npm or NuGet brought to software libraries to the configuration layer of code agent harnesses.

With APM, you declare your agent configuration dependencies in a manifest file, lock exact versions in a lockfile, and run a single command to get a reproducible, up-to-date setup on any machine.

```yaml
# apm.yml
name: my-project
version: 1.0.0
dependencies:
  apm:
    - your-org/team-standards
    - your-org/security-baseline
  mcp:
    - io.github.github/github-mcp-server
```

Every collaborator, every CI run, every new repository clone gets exactly the same configuration.

---

## What APM Manages

APM manages what it calls **primitives**: the foundational building blocks of a code agent setup. These map directly to the tools covered in [The Architecture of Code Agents](https://aalmada.github.io/posts/The-Architecture-of-Code-Agents-Instructions-Skills-Agents-Hooks/):

- **Instructions** (`.instructions.md`) — project-specific rules scoped to files or folders
- **Prompts** (`.prompt.md`) — executable AI workflows with parameters
- **Agents** (`.agent.md`) — custom agent personalities and execution behaviours
- **Skills** (`SKILL.md`) — reusable knowledge packages loaded on demand
- **Hooks** (`.json`) — lifecycle event handlers for `PreToolUse`, `PostToolUse`, and similar events
- **MCP servers** — Model Context Protocol server registrations wired to each configured client

Each package is a git repository. Dependencies are resolved directly from GitHub, Azure DevOps, GitLab, or any git host. There is no central registry — a package is just a URL.

### Installing Individual Skills

Not every repository is a full APM package. Many repositories follow the [agentskills.io](https://agentskills.io/) convention, where skills are organised as individual folders under a `skills/` directory, each with its own `SKILL.md`. APM handles these natively.

You can install a single skill from a bundle repository and persist the selection to your manifest:

```bash
# Install one skill from a bundle
apm install vercel-labs/agent-skills/skills/deploy-to-vercel

# Install all skills in the bundle
apm install vercel-labs/agent-skills
```

The selection is written to `apm.yml` and recorded in the lockfile, so the exact subset is reproducible on every machine and in CI. This is equivalent to what `npx skills add` does, with the addition of a manifest and lockfile.

### Installing from Marketplaces

APM also supports plugin marketplaces: curated indexes of packages maintained by organisations or communities. Once you register a marketplace, you can browse and install from it by name rather than by repository URL:

```bash
# Register a marketplace
apm marketplace add acme/plugin-marketplace --name acme-plugins

# Browse what is available
apm marketplace browse acme-plugins

# Install a plugin from the marketplace
apm install code-review@acme-plugins

# Install a specific version
apm install code-review@acme-plugins#v2.0.0
```

Marketplace installs are tracked in the lockfile the same way as direct git dependencies. The exact version and content hash are recorded, so updates are explicit and auditable.

---

## One Configuration, Every Agent

Not everyone on a project uses the same coding agent. In a closed team this is already common — one developer prefers GitHub Copilot, another uses Claude Code, a third runs Cursor. In open-source projects it is the norm: contributors bring whatever tool they work with, and you have no control over that. Each of these tools reads configuration from a different directory, in a slightly different format.

Without tooling, that means maintaining separate copies of essentially the same rules and skills for each client — or picking one agent and ignoring the rest.

APM solves this at the source. Primitives are authored once in `.apm/` and deployed to every configured client directory on `apm install`:

- `.github/` — GitHub Copilot
- `.claude/` — Claude Code
- `.cursor/` — Cursor
- `.opencode/` — OpenCode
- `.gemini/` — Gemini CLI

APM auto-detects which directories exist in the project and deploys to all of them. Each client receives the appropriate format for its native primitives. You write once; every agent on the team gets the same configuration.

---

## Compilation and Context Optimization

For most teams using GitHub Copilot, Claude Code, or Cursor, `apm install` is all you need. It deploys primitives in each client's native format and nothing else is required.

Some agents, however, do not read deployed primitives directly. Codex and Gemini expect a single compiled instructions file — `AGENTS.md` or `GEMINI.md` respectively. For those, you run `apm compile` after install.

```bash
apm compile
```

APM auto-detects which client directories exist and generates the appropriate output. But compilation does more than just merge files together.

As a project grows, a single monolithic `AGENTS.md` at the root becomes a problem: every agent working anywhere in the repository inherits the full set of instructions, most of which are irrelevant to what they are doing at that moment. This is context pollution, and it degrades both performance and accuracy.

APM's compiler treats instruction placement as an optimisation problem. It analyses which instructions apply to which parts of the directory tree, then distributes them across hierarchical `AGENTS.md` files — one at the root for global rules, others placed closer to the code they govern. A file inside `src/components/` inherits instructions from `src/components/AGENTS.md`, `src/AGENTS.md`, and the root `AGENTS.md` in order of proximity, picking up only what is relevant.

The result is that every file gets the instructions it needs, and nothing it does not. Coverage is mathematically guaranteed — no instruction is ever dropped. The output is also deterministic: the same input always produces the same files, which makes it safe to verify in CI.

```bash
# Check for drift after any primitive changes
apm compile
if [ -n "$(git status --porcelain -- AGENTS.md GEMINI.md)" ]; then
  echo "Compiled output is out of date. Run 'apm compile' and commit."
  exit 1
fi
```

---

## How It Works in Practice

### Authoring in `.apm/`, Deploying to Clients

Primitives are authored in a `.apm/` directory at the project root. When you run `apm install`, APM resolves all declared dependencies, downloads them at the exact commit recorded in the lockfile, and deploys the resulting files to each configured client directory.

### Pinning to a Specific Ref

APM dependencies can be anchored to any git ref by appending a `#ref` suffix to the package path:

```bash
# Pin to a tag
apm install your-org/team-standards#v2.1.0

# Pin to a specific commit SHA
apm install your-org/team-standards#a1b2c3d4

# Track a branch (resolves to the tip at install time)
apm install your-org/team-standards#main
```

Tags are the most stable choice when the package maintainer uses them: they are immutable, clearly versioned, and easy to reason about in code review. In practice, many skill and agent repositories do not publish tags at all. For those, a branch pin is perfectly reasonable — APM resolves it to the exact commit SHA at install time and records that SHA in the lockfile, so reproducibility is preserved even without an explicit version. Commit SHAs give you maximum precision at the cost of legibility, and are most useful when you want to lock to a specific point in history regardless of what the branch does next.

Regardless of how you express the ref in `apm.yml`, the lockfile always records the resolved commit SHA.

### Reproducibility via the Lockfile

Like `package-lock.json` or `packages.lock.json`, APM generates an `apm.lock.yaml` that records the exact commit SHA and a content hash for every resolved dependency.

```yaml
dependencies:
  - repo_url: your-org/team-standards
    resolved_commit: a1b2c3d4e5f6...
    content_hash: "sha256:9f86d081884c7d659a2feaa0c55ad015..."
```

This means two things. First, every machine gets exactly the same files. Second, post-download tampering is detectable — if the on-disk content no longer matches the recorded hash, APM warns before doing anything.

Committing the lockfile to version control is the right move. It gives you a complete audit trail of what every repository is using, and it makes CI runs deterministic.

### Updating is Explicit

Dependencies do not update silently. You run `apm install --update` or `apm deps update` when you want to pull in newer versions. APM then re-resolves each dependency to its latest commit, re-downloads, re-deploys, and updates the lockfile. The diff in your pull request is the record of what changed.

---

## Adding APM to an Existing Project

APM is additive. It never overwrites files it did not place there. Existing `.github/copilot-instructions.md`, `AGENTS.md`, or `.claude/` configuration is left untouched.

Adding it to an existing repository takes three steps:

```bash
# 1. Initialise
apm init

# 2. Add dependencies
apm install your-org/team-standards

# 3. Commit the manifest and lockfile
git add apm.yml apm.lock.yaml
git commit -m "Add APM manifest"
```

Teammates run `apm install` and get the same setup. If APM turns out not to be the right fit, you delete `apm.yml` and `apm.lock.yaml`. Nothing else changes.

---

## CI/CD Integration

The official [apm-action](https://github.com/microsoft/apm-action) makes GitHub Actions integration a single step:

```yaml
- name: Install APM packages
  uses: microsoft/apm-action@v1
```

This installs APM and runs `apm install` using the lockfile from the repository. For drift detection — ensuring deployed primitives stay in sync with what is declared in `apm.yml` — you can add a check that fails the build if `apm install` produces uncommitted changes:

```yaml
- name: Check APM integration drift
  run: |
    apm install
    if [ -n "$(git status --porcelain -- .github/ .claude/ .cursor/)" ]; then
      echo "APM integration files are out of date. Run 'apm install' and commit."
      exit 1
    fi
```

For security auditing, `apm audit --ci` runs seven baseline consistency checks against the lockfile and exits with code 1 if any fail. Add `--policy org` to enforce organisational policy rules on top of the baseline.

---

## Security by Default

One thing that sets APM apart from a simple file-sync approach is its pre-deployment security model.

When `apm install` downloads a package, it scans every file for hidden Unicode characters before deploying them to client directories. Tag characters, bidirectional overrides, and similar sequences that could embed invisible instructions into prompt files are flagged as critical findings. Critical findings block deployment. The package is cached for inspection, but nothing reaches the directories that agents read.

**File presence is execution.** The moment a skill or instruction file lands in `.github/prompts/` or `.claude/`, an IDE agent watching the filesystem may begin ingesting it. APM treats package deployment as a pre-deployment gate: scan first, deploy only if clean.

This matters especially in team environments where package authors are not the same people as the developers running `apm install`.

---

## Distributing Your Own Packages

The same mechanism that makes consumption easy makes authoring straightforward. An APM package is just a git repository with an `apm.yml` at its root and primitives organised under `.apm/`.

For teams that want to distribute a fully self-contained bundle — for air-gapped environments, controlled deployments, or Claude Code plugin distribution — `apm pack` builds either a directory bundle or a `.tar.gz` archive that can be deployed without a network connection.

```bash
# Build a Claude Code plugin (default format)
apm pack

# Build an APM bundle archive for distribution
apm pack --format apm --archive
```

The bundle includes an enriched lockfile so consumers get the same content integrity guarantees as a live install.

---

## The Broader Picture

APM is the infrastructure layer that makes the primitives described in [The Architecture of Code Agents](https://aalmada.github.io/posts/The-Architecture-of-Code-Agents-Instructions-Skills-Agents-Hooks/) manageable at scale.

Instructions, skills, agents, and hooks are valuable only if teams actually use them, keep them updated, and trust that what is running in any given repository is the version they think it is. Without tooling to manage that lifecycle, the natural outcome is drift, duplication, and eventually abandonment.

APM gives those primitives the same lifecycle guarantees we already expect from software libraries:

- Declared in a manifest
- Pinned in a lockfile
- Reproducible on any machine
- Updated explicitly with an auditable diff
- Distributed as versioned packages

**In effect:**

> APM turns your agent configuration from a folder of files into a managed, versioned, reproducible dependency — and gives your team the infrastructure to scale that configuration across every project.

For deeper context on what APM manages and how it fits into the code agent workflow:

- [The Architecture of Code Agents: Instructions, Skills, Agents, Hooks](https://aalmada.github.io/posts/The-Architecture-of-Code-Agents-Instructions-Skills-Agents-Hooks/)
- [Reducing Token Usage in Code Agents](https://aalmada.github.io/posts/Reducing-Token-Usage-in-Code-Agents/)
- [.NET/C# Development in the Code Agents Era](https://aalmada.github.io/posts/Dotnet-Development-in-the-Code-Agent-Era/)
