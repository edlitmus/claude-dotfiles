---
name: explore
description: Structured codebase exploration — discovery and deep dive.
argument-hint: "[directory or question about the code]"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Agent
model: sonnet
effort: high
context: fork
---

# Explore — Structured Codebase Exploration

Explore the codebase: `$ARGUMENTS`

## Phase 1 — Discovery (overview)

### 1. Project structure
```bash
# Directory tree (excluding node_modules, .git, etc.)
find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/__pycache__/*' | head -100
```

### 2. Stack and dependencies
- Identify: language(s), framework(s), database(s), tools
- Read: package.json, go.mod, pyproject.toml, requirements.txt, Cargo.toml
- Map the main dependencies and their versions

### 3. Entry points
- Identify the entry point(s): main, index, app, server
- Trace the initialization flow

### 4. Architectural patterns
- Organization: monolith, monorepo, microservices
- Layers: MVC, Clean Architecture, Hexagonal
- Communication: REST, GraphQL, gRPC, events

### 5. Architecture map
```
## Architecture Map

### Stack
- Language: [X]
- Framework: [Y]
- Database: [Z]
- Infra: [Docker/K8s/etc]

### Structure
[text diagram of the directory organization]

### Main flow
[entry point] → [layer 1] → [layer 2] → [data]

### Critical dependencies
- [lib]: [what it is used for]
```

## Phase 2 — Deep Dive (specific focus)

If the user asked for something specific (e.g. "how does authentication work"):

### 1. Locate
- Grep for relevant terms
- Identify the key files

### 2. Trace
- Follow the data/control flow
- Map the calls: who calls → who is called

### 3. Document
```
## Deep Dive: [topic]

### Files involved
- [path]: [responsibility]

### Flow
1. [step] — [file:line]
2. [step] — [file:line]

### Points of attention
- [relevant observation]
```

## When to use
- A new project: "how does this project work?"
- Onboarding: "explain the architecture to me"
- Investigation: "where is the logic for X?"
- Before big changes: understanding the terrain
