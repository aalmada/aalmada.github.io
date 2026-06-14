---
layout: post
read_time: true
show_date: true
title: "Public Skills, Agents, and the New Supply‑Chain Problem"
date: 2026-06-14
img_path: /assets/img/posts/20260614
image:
  path: /assets/img/posts/20260614/Dial.jpg
tags: [ai, agents, copilot]
category: ai
redirect_from:
  - /posts/Public-Skills-Agents/
meta_description: "Public skills and agents introduce a new supply‑chain risk for AI systems. They’re easy to adopt but can hide malicious intent inside prompts. This post explains why deterministic tools like APM aren’t enough, how Skillspector adds reasoning‑based security, and why sandboxing remains essential for safe agent execution."
---

Publicly shared skills and agents are becoming part of the everyday workflow for anyone building coding agents. They’re open, composable, and easy to adopt. That openness is exactly what makes them useful — and exactly what makes them dangerous. Skills and agents contain prompts, and prompts are executable instructions. When a coding agent reads a prompt, it doesn’t interpret it the way a developer interprets code; it executes the intent behind it. If that intent is malicious, the agent will follow it with the same confidence it follows everything else. This creates a new class of supply‑chain risk where the payload is linguistic rather than binary.

The first rule when working with public skills and agents is simple: **only use them from well‑known, reputable sources**. It’s the most effective way to reduce the attack surface. Unfortunately, it also limits innovation. New ideas appear everywhere — often from individuals or small teams experimenting in the open — and restricting ourselves only to established publishers means missing out on the most creative and fast‑moving parts of the ecosystem. Because of that tension, the following layers become essential.

## The Transparency Trap

Skills look safe because they’re plain text. I can open a file, read the prompt, and convince myself I understand what it does. But LLMs operate on a different layer. They see characters I don’t. Invisible Unicode, zero‑width joiners, homoglyphs, and prompt‑splitting tricks can hide instructions that never appear in my editor.

A skill can look clean while containing a second, invisible instruction path.  
A human sees a helper; the agent sees “run this payload when invoked.”

Visual inspection is not a security strategy.

## APM: Deterministic Surfaces and Hidden Content Warnings

This is where [APM](https://microsoft.github.io/apm/) becomes relevant. APM’s security model is built around determinism, provenance, and supply‑chain integrity. It gives me reproducible installs, deterministic dependency resolution, and verifiable origins through Git‑based sources and signed commits. It also [warns about hidden content](https://microsoft.github.io/apm/enterprise/security/#content-scanning) — an important layer because invisible characters are one of the easiest ways to smuggle malicious instructions into an otherwise harmless‑looking skill.

But APM’s determinism is also its limitation. It can tell me exactly what is in the file, but it cannot tell me why it’s there or what it intends to do. It cannot reason about malicious prompts or unsafe code paths. And that’s by design. APM is a supply‑chain tool, not a security scanner. It ensures the file I install is exactly the file in the source repository, but it cannot evaluate whether the file is something I should trust.

> For more on how APM fits into agent development, see my previous post: [**APM Package Management for AI Agent Configuration**](https://antaoalmada.dev/posts/APM-Package-Management-for-AI-Agent-Configuration/)

## Skillspector: Reasoning-Based Security for Skills

This is where NVIDIA's [Skillspector](https://github.com/nvidia/skillspector) becomes important. Skillspector treats skills and agents as a new class of software artifact — one where the attack surface is linguistic and behavioral rather than structural. Instead of hashing files or validating provenance, it evaluates the intent of the skill.

Skillspector performs semantic analysis of prompts and scripts. It identifies high‑risk or malicious patterns, detects privilege‑escalation behaviors embedded in natural language, and flags unsafe tool usage that could lead to code execution or data exfiltration. It reasons about what the skill is trying to achieve, not just how it is written.

This is the key distinction: **Skillspector uses reasoning**, which allows it to detect intent, hidden behaviors, and unsafe patterns that deterministic tools simply cannot see. APM can guarantee that a file is exactly what was published, but only a reasoning system can determine whether that file is trying to do something harmful.

This is a fundamentally different layer of protection.  
APM ensures the file is exactly what I installed.  
Skillspector evaluates whether the file is something I should trust.

Determinism is necessary, but it’s not sufficient. Finding malicious prompts or unsafe code paths requires reasoning, not hashing. Skillspector is the first tool that approaches this problem directly.

## Sandboxing: The Runtime Boundary

Even with deterministic installs and semantic inspection, I still need runtime isolation. Some coding agents already provide sandboxing. When they don’t, I fall back to Docker sandboxes — the same approach I described in my Agent Governance work.

If an agent can execute code, it must run inside a boundary. Sandboxing protects me from unexpected behavior, filesystem access, network exfiltration, and privilege escalation. It’s the last line of defense when everything else fails.

> For more on execution isolation, see: [**Agent Governance — Execution Isolation (Sandboxes)**](/posts/Agent-Governance/#execution-isolation-sandboxes)

## Innovation Outpaces Trust

The ecosystem is moving fast. New skills appear constantly, new agents show up every month, and better ideas emerge every week. The pace is good for innovation but terrible for trust.

To work safely in this environment, we should rely on three layers:

- deterministic package management through APM  
- semantic security analysis through Skillspector  
- runtime isolation through sandboxes  

This is the minimum viable security posture for coding agents today.

## Where We Need to Go

If we want this ecosystem to mature, we need shared standards that treat skills and agents as first‑class software artifacts. That means signed skills, transparent provenance, automated prompt‑level scanning, sandbox‑first execution harnesses, and reproducible environments backed by reasoning‑based security layers. Deterministic tools like APM give us integrity, but integrity alone is not trust. Reasoning‑based analysis, runtime isolation, and verifiable origins must work together.

Until we have these standards, every public skill remains a potential supply‑chain risk — not because the ecosystem is hostile, but because it is moving faster than our ability to secure it. The only safe approach today is layered defense: provenance, reasoning, and isolation. That’s how we keep the pace of innovation without inheriting its vulnerabilities.
