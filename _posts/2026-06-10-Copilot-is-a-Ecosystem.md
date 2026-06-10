---
layout: post
read_time: true
show_date: true
title: "Copilot Is an Ecosystem, Not a Feature"
date: 2026-06-10
img_path: /assets/img/posts/20260610
image:
  path: /assets/img/posts/20260610/Copilot.jpg
tags: [ai, agents, copilot]
category: ai
redirect_from:
  - /posts/Copilot-is-an-Ecosystem/
meta_description: "GitHub Copilot is an ecosystem of integrated Copilots — the VS Code Copilot, the CLI Copilot, the SDK Copilot, the Cloud Copilot, and the GitHub Copilot App — each designed for different workflows but all connected through shared history, seamless handoffs, and unified interfaces."
---

For a long time, “using GitHub Copilot” meant typing a prompt in VS Code. That was the Copilot we knew: the one embedded in the editor, the one that completed code, the one that felt like a natural extension of the IDE. But that Copilot is only one of several. GitHub Copilot appears in multiple places, with different capabilities, different interaction models, and different agents behind them, as I explored in [Copilot Custom Agents](/posts/copilot-custom-agents/).

> Note: This post is about GitHub Copilot’s coding agent — not Microsoft 365 Copilot, Windows Copilot, Teams Copilot, or any other Microsoft Copilot.

These Copilots are not isolated tools. They are **integrated surfaces** of the same ecosystem. They share history. They hand off work. They can run inside each other. And VS Code has quietly become the place where they all meet.

## The VS Code Copilot: the interactive one

The VS Code Copilot is the Copilot most people meet first. It’s embedded in the editor, it understands open files, and it provides inline chat, inline code actions, autocompletion, diff previews, drag‑and‑drop context, model switching, tool toggles, and all the UI affordances that make it feel native to the IDE.

But VS Code is no longer just a Copilot surface — it’s the **integration hub** for all the others.

The **Copilot CLI** can be opened as a window inside VS Code, turning the terminal Copilot into a first‑class panel. Prompts can be routed to the **CLI**, to the **Cloud Copilot**, or even to **Claude**, directly from the chat box. VS Code and the CLI **share the same session history**, so the conversation continues seamlessly across surfaces. And VS Code now includes the **Agents Window** — an agentic‑centric UI where all Copilots appear side by side, each with its own capabilities, context, and controls.

This Copilot is built for interactive development, but it’s also the place where the other Copilots plug in and become part of a unified workflow.

## The Copilot CLI: the one for long‑running workflows and CI/CD

The Copilot CLI is a different Copilot entirely. It lives in the terminal, but it’s fully integrated with VS Code — it can run as a panel, receive delegated prompts, and share history with the editor.

This Copilot is designed for **long‑running, structured workflows**. It handles multi‑step tasks, guided flows, patch application, and repeatable processes. The structure around the model is deterministic; the reasoning itself is not, but the workflow is explicit. That’s exactly what I want when I’m dealing with migrations, large‑scale changes, or anything that doesn’t fit into a quick “fix this file” interaction.

Because the CLI is scriptable and independent of the editor, it’s the natural Copilot for **CI/CD**. It runs unattended, integrates into pipelines, and becomes part of the delivery process rather than something I only use manually.

And when a workflow needs GitHub‑side reasoning, the CLI can **delegate to the Cloud Copilot** using the [`/delegate`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/delegate-tasks-to-cca) command — a seamless handoff between Copilots.

And the CLI Copilot is no longer limited to the machine where it’s running. With the new [Remote Control CLI Sessions](https://github.blog/changelog/2026-04-13-remote-control-cli-sessions-on-web-and-mobile-in-public-preview/) feature, you can start a long‑running workflow locally and then control it from GitHub.com or the GitHub Mobile app. The web and mobile interfaces act as remote consoles for the CLI session — you can monitor progress, send follow‑up instructions, and continue the workflow even when you’re away from your laptop. This turns the CLI into a distributed Copilot surface, one that follows you across devices and keeps the workflow alive wherever you are.

If the VS Code Copilot is the interactive one, the CLI Copilot is the **procedural one**, and it’s fully integrated with the editor.

## The Copilot SDK: the one you embed into apps and automation

The Copilot SDK is where I stop “using Copilot” and start **building with Copilot**. In [Hybrid Workflows](/posts/Hybrid-workflows/) I describe how the SDK lets me orchestrate reasoning inside my own systems — not as a UI, but as a component.

This Copilot is ideal when I want to **integrate reasoning into applications or automation workflows**. Internal developer portals, automation services, CI/CD orchestrators, migration tools, review bots — all of these can call Copilot through the SDK and make it part of their logic.

The SDK Copilot is not a UI surface. It’s the embeddable Copilot. It’s the Copilot for platform teams who want to build workflows that span tools, systems, and environments.

And because the SDK and CLI share the same underlying execution model, workflows can move between them naturally.

## The Cloud Copilot: the one that lives in GitHub

The Cloud Copilot is the Copilot that lives inside GitHub. It works with pull requests, understands repository‑level patterns, and proposes multi‑file changes directly in GitHub’s UI.

This Copilot is the one I reach for when I want **GitHub‑side reasoning and PR‑centric workflows**. It’s good at proposing improvements across a codebase, running long‑running suggestions, and operating at the level of pull requests and repository history.

And because the CLI can delegate to the Cloud Copilot, and VS Code can route prompts to it, the Cloud Copilot becomes part of the same integrated workflow. I can start locally, escalate to GitHub, and return to the editor to review the results.

## The GitHub Copilot App: the desktop, agent‑native Copilot

And now there’s a fifth Copilot — the [**GitHub Copilot App**](https://github.blog/news-insights/product-news/github-copilot-app-the-agent-native-desktop-experience/), the agent‑native desktop experience. This Copilot doesn’t live in an editor, a terminal, or [GitHub.com](https://github.com/). It lives on your machine as a standalone environment designed for **agent‑centric workflows**.

It provides a persistent Copilot window, multi‑agent support, OS‑level integration, and the ability to work across applications instead of being tied to a single tool. It’s the Copilot I can summon anywhere, not just inside a development environment.

The most interesting part is the [**Canvas Extensions**](https://docs.github.com/en/copilot/how-tos/github-copilot-app/working-with-canvas-extensions) system. Through Canvas Extensions, the Copilot App can load specialized capabilities — extensions that add new tools, new workflows, new integrations — all inside the App’s agent‑native UI.

This Copilot is the one that ties everything together at the desktop level. It’s the Copilot that doesn’t require me to “be in VS Code” or “be in the terminal.” It’s the Copilot that’s always available.

# How the Five Copilots Change Your Workflow

When you only know the VS Code Copilot, everything looks like an inline prompt.
Once you understand there are multiple Copilots — all integrated, all connected, all sharing history — your workflows start to stretch across them.

You might explore and iterate in VS Code, then move to the CLI Copilot when the task becomes a long‑running workflow. You might use the SDK Copilot to embed that workflow into an internal tool or a pipeline, so it stops being a one‑off and becomes part of how your team works. You might rely on the Cloud Copilot to propose PR‑level changes or improvements that you then refine locally. And you might use the Copilot App as the persistent, desktop‑native Copilot that ties everything together.

The important part is this:
**You’re not dealing with one Copilot in different skins.**
**You’re dealing with multiple Copilots that are integrated into a single system.**

Exactly the distinction I laid out in [Copilot Custom Agents](/posts/copilot-custom-agents).

## Why this matters

If the only Copilot someone ever uses is the VS Code Copilot, they’re leaving a lot on the table. There’s a Copilot for long‑running workflows and CI/CD. There’s a Copilot for embedding reasoning into apps and automation. There’s a Copilot that works at the GitHub and PR level. There’s a Copilot that runs as a desktop‑native agent environment.

And they’re all connected — VS Code can open the CLI, route prompts to any Copilot, share history across them, and expose them through the **Agents Window**, while the Copilot App extends the ecosystem with Canvas Extensions and OS‑level workflows.

Once that becomes clear, the question stops being “What can Copilot do in my editor” and becomes “Which Copilot fits the work I’m doing right now.”

That’s the shift this post is meant to trigger.
