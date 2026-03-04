# P4_Multi-Agent_AI_Orchestration_DSL

## Setup
1. Build: `dune build`
2. Run: `dune exec multi-agent_orchestration -- test.ma`
---
A Domain-Specific Language for structured and controlled multi-agent AI systems.

---

## Overview

As AI systems evolve, they increasingly rely on multiple agents collaborating to solve tasks. One agent may plan, another execute, another verify, and others may interact with tools or external data sources. In practice, this coordination is often implemented using general-purpose code, resulting in orchestration logic that is difficult to maintain, reason about, or debug.

This project introduces a dedicated DSL for defining and executing multi-agent collaboration in a structured and predictable way.

---

## Core Concept

The central idea is simple:
**coordination should be explicit, constrained, and analyzable.**

Instead of allowing agents to interact freely, this DSL enforces:

* Clearly defined roles and responsibilities
* Predefined orchestration patterns
* Controlled tool permissions
* Explicit termination conditions

By restricting how agents collaborate, the system becomes easier to understand, test, and extend.

---

## Supported Patterns

To balance expressiveness with structural guarantees, the language focuses on three coordination strategies:

* **Pipeline**
* **Supervisor–Worker**
* **Debate with Judge**

These patterns capture common real-world collaboration structures while maintaining bounded interaction and predictable execution.

---

## Architecture

The DSL describes agents, roles, tools, and coordination rules.
It is parsed into an internal representation and executed by a runtime engine that enforces:

* Permission constraints
* Stop conditions
* Structured interaction flow
* Complete execution logging

Agent roles are decoupled from specific models, allowing model replacement without modifying orchestration logic.

---

## Purpose

This is not a chatbot wrapper or prompt management tool.

It is a structured orchestration layer designed to make multi-agent AI systems more predictable, modular, and formally defined.
