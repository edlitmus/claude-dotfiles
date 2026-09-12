---
name: dispatch
description: Orchestration protocol for dispatching sub-agents with complete context.
argument-hint: "[task to dispatch]"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Agent
model: sonnet
effort: high
context: fork
---

# Dispatch — Sub-Agent Orchestration

Dispatch the task to the right agent: `$ARGUMENTS`

## When to dispatch (mandatory)

### Semantic auto-triggers
If the user uses these phrases, dispatching is MANDATORY:

| User phrase | Agent | Rationale |
|---|---|---|
| "find where", "search for", "locate" | Explore | Searching requires a broad sweep |
| "fix issues", "fix remaining" | Backend/Frontend | A fix requires implementation focus |
| "how does X work", "explain the flow" | Explore | Understanding requires analysis |
| "refactor", "update across", "rename" | Backend/Frontend | Refactors touch multiple files |
| "review this", "check quality" | /review or /review-deep | Review is a dedicated skill |
| "design architecture", "propose solution" | Architect | Architectural decision |
| "check security", "audit" | Security | Security analysis |
| "optimize query", "fix migration" | Database | Data specialist |
| "deploy", "configure CI", "docker" | DevOps | Infrastructure |

### The 3-file rule
If the task involves >3 files → dispatching is MANDATORY.

## Dispatch protocol (5 steps)

### Step 1 — Assess the task
- What is the concrete goal?
- How many files will be affected?
- Which knowledge domain is required?

### Step 2 — Select the agent
- Consult the auto-trigger table
- When torn between 2 agents, pick the more specific one
- If it spans domains, dispatch multiple agents in parallel

### Step 3 — Assemble the prompt
The prompt MUST contain:
1. **Context**: what the project does, stack, current state
2. **Task**: what needs to be done (specific, not vague)
3. **Scope**: which files/directories are relevant
4. **Acceptance criteria**: how to know it is done
5. **Constraints**: what NOT to do (if applicable)

### Step 4 — Dispatch
- Use the `Agent` tool with the right `subagent_type`
- For independent tasks, dispatch in parallel
- Never dispatch without acceptance criteria

### Step 5 — Consolidate
- Review the sub-agent's output
- Check whether the acceptance criteria were met
- If not met, re-dispatch with specific feedback
- Present a consolidated result to the user

## Anti-patterns (FORBIDDEN)

| Anti-pattern | Correct |
|---|---|
| Dispatching without context | Include complete context in the prompt |
| "Do whatever is needed" | Define a specific task and criteria |
| Doing directly what should be dispatched | The 3-file rule is inviolable |
| Dispatching to the wrong agent | Consult the domain table |
| Ignoring the sub-agent's output | Always review and consolidate |
