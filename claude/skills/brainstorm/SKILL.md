---
name: brainstorm
description: Structured creative ideation — generates, evaluates, and prioritizes ideas.
argument-hint: "<problem or topic>"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
model: opus
effort: high
context: fork
---

# Brainstorm — Creative Ideation

Explore creative solutions for: `$ARGUMENTS`

## Process

### Phase 1 — Understand the problem
1. Restate the problem in 1 clear sentence
2. Identify known constraints (time, tech, team, budget)
3. Define success criteria: how will we know the solution works?

### Phase 2 — Generate ideas (unfiltered)
Generate **at least 5 ideas** without judging feasibility:
- Include both conservative AND bold approaches
- Consider: existing solutions, analogies from other domains, inverting the problem
- Each idea in 1-2 sentences

### Phase 3 — Evaluate
For each idea, score 3 dimensions:

| Idea | Feasibility (1-5) | Impact (1-5) | Effort (1-5) | Score |
|------|-------------------|--------------|--------------|-------|
| ... | ... | ... | ... | F×I/E |

- **Feasibility**: is it technically possible within the constraints?
- **Impact**: does it really solve the problem?
- **Effort**: how much work? (1=a lot, 5=a little)
- **Score**: Feasibility × Impact / Effort

### Phase 4 — Recommend
1. Top 3 ideas by score
2. For each: concrete next steps (1-3 actions)
3. Main risks and mitigations

## Output format

```
## Brainstorm: [topic]

### Problem
[1 clear sentence]

### Constraints
- [constraint 1]
- [constraint 2]

### Ideas
1. **[Name]** — [description]
2. **[Name]** — [description]
...

### Evaluation
[table with scores]

### Recommendation
**Top pick**: [idea] — Score X.X
- Next step 1: [action]
- Next step 2: [action]
- Risk: [risk] → Mitigation: [how]

**Alternative**: [idea 2]
- ...
```

## Rules
- Quantity before quality in Phase 2
- Honest evaluation — do not inflate scores for your favorite idea
- If the problem is technical, consider non-technical solutions too
- If the problem is about process, consider automation
