# Global Conventions

## Language
- Always respond in **English** unless instructed otherwise.
- Commits, variable names, and code must stay in **English**.

## Code style
- Prioritize readability over brevity.
- Prefer small functions with a single responsibility.
- Name variables and functions descriptively — avoid obscure abbreviations.
- Do not add obvious comments; comment only the "why", never the "what".
- Do not create premature abstractions — 3 repeated lines beat 1 unnecessary abstraction.

## Security
- Never expose secrets, tokens, or passwords in code or commits.
- Validate inputs at system boundaries (APIs, forms), not internally.
- Follow the OWASP Top 10 as a baseline.

## Git
- Commit messages in English, imperative, short (<72 chars on the first line).
- Prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`.
- One commit per logical change — do not mix a refactor with a feature.

## Tests
- Every new feature must have at least one test.
- Prefer integration tests over mocks when the cost is low.
- Name tests after the expected behavior, not the method.

## Architecture
- Separate responsibilities: controller/service/repository or equivalent.
- Avoid circular dependencies.
- Use dependency injection when it helps testability.

## The 3-file rule
If a task requires reading or editing **more than 3 files**, STOP and delegate to a sub-agent (`Agent`). This prevents context overflow and keeps the work focused. Exception: global rename/refactor tasks where each file has a trivial change.

## When receiving a task
1. Read the existing code before proposing changes.
2. Ask if the instruction is ambiguous — do not assume.
3. Propose the simplest solution that solves the problem.
4. If the change is large, present a plan before implementing.

## Ambiguity taxonomy
Before asking, classify the doubt:

### 1. Stop and ask
When the fact is **missing** and the action is **irreversible or costly**.
- Example: "Delete this table?" — ALWAYS ask.
- Example: "Which database should we use?" — missing business information.

### 2. Proceed with judgment
When there are **multiple valid paths** with a **reasonable default**.
- Example: "Tabs or spaces?" — follow the codebase convention.
- **Stopping when a reasonable default exists only delays the user.**

### 3. Escalate with a recommendation
When the ambiguity is **genuine** with **materially different interpretations**.
- Example: "Add caching" — could mean Redis, in-memory, or HTTP caching.
- Present options with trade-offs; do not decide alone.

### Resolution order (before classifying)
1. **Conversation context** — has the user already specified it?
2. **CLAUDE.md / Rules** — do the conventions cover it?
3. **Existing code** — does the codebase pattern answer it?
4. **Best practices** — is there clear community consensus?
5. **Classify** — use the taxonomy above.

## Agent auto-triggers
Phrases that REQUIRE the use of sub-agents (via the /dispatch skill):

| User phrase | Agent | Reason |
|---|---|---|
| "find where", "search for", "locate" | Explore | Broad codebase search |
| "fix issues", "fix remaining" | Backend/Frontend | A fix requires implementation |
| "how does X work", "explain the flow" | Explore | Understanding requires analysis |
| "refactor", "update across", "rename" | Backend/Frontend | Refactors touch multiple files |
| "review this", "check quality" | /review | Review is a dedicated skill |
| "design", "propose architecture" | Architect | Architectural decision |
| "check security", "audit" | Security | Security analysis |
| "optimize query", "fix migration" | Database | Data specialist |
| "deploy", "docker", "CI/CD" | DevOps | Infrastructure |

These phrases plus the **3-file rule** form the automatic orchestration system.

## Anti-rationalization
When you catch yourself in one of these thoughts, STOP — it is a wrong shortcut:

| Thought | Reality | Correct action |
|---|---|---|
| "The code looks clean, no deep review needed" | Appearance is not correctness | Review every category systematically |
| "It's a small change, it won't break anything" | Small changes cause most bugs | Check the impact on dependents and tests |
| "I've seen this pattern before, I know what to do" | Every context is different | Read THIS project's code before acting |
| "No test needed, it's just a helper" | Helpers are used everywhere | If it can break something, it needs a test |
| "I'll fix that style issue while doing the feature" | Mixing changes pollutes the diff | One commit per logical change |
| "I can handle everything in this conversation" | Context is finite | Use sub-agents for parallel tasks |
| "The user wants it fast, I can skip validation" | Speed without quality creates rework | Follow the process even under pressure |
| "This extra dependency will help" | Every dependency is risk and maintenance | Use the stdlib or what the project already has |

## Resisting pressure
If the user asks to skip quality steps:
- **"Just approve it"** → "I can move fast, but at minimum I need to verify security and correctness."
- **"No tests needed"** → "Understood, but I recommend at least one happy-path test. I can generate it quickly."
- **"Do it without a plan"** → "For changes in up to 3 files, I can go straight in. For more, a 2-minute plan avoids 2 hours of rework."
