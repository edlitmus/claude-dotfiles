---
name: perf
description: Analyzes code performance and suggests concrete optimizations.
argument-hint: "[optional file or directory]"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Agent
model: sonnet
effort: high
context: fork
---

# Performance Analysis

Run a complete performance analysis over the given scope.

## Scope

### If an argument was provided
Analyze the file or directory: `$ARGUMENTS`

### If no argument was provided
Analyze the current project's root directory. Use `Glob` and `Bash` to map the structure and identify the most relevant files (entry points, services, routes, main components).

Before starting, identify the project's stack (language, framework, ORM, UI library) -- this determines which patterns to look for. For projects with many relevant files, use `Agent` to parallelize the analysis by category.

## Analysis Categories (ALL mandatory)

### 1. Queries and Data Access

Look for:
- **N+1 queries**: loops running individual queries instead of fetching in batch (e.g. `for item in items: db.query(...)`)
- **Missing indexes**: columns used in `WHERE`, `JOIN`, or `ORDER BY` without a matching index in the schema
- **SELECT \***: queries returning every column when only a few are used
- **Unnecessary eager loading**: relations loaded that are never accessed in the code

Use `Grep` for ORM patterns (`.query(`, `.find(`, `.filter(`, `SELECT`, `JOIN`) and `Read` for migration schemas.

### 2. Loops and Algorithms

Look for:
- **O(n²) or worse complexity**: nested loops over the same collection where O(n) is feasible
- **Repeated computation inside a loop**: calls that produce the same result on every iteration and could be memoized before the loop
- **Linear search in collections**: `Array.includes`, `list.index()`, `.find()` inside loops -- candidates for a `Set` or `Map` for O(1) lookup
- **Unnecessary sorting**: data sorted repeatedly without changing between sorts

### 3. Memory and Allocations

Look for:
- **Large objects in hot paths**: heavy allocations inside frequently called functions
- **String concatenation in a loop**: building via `+=` in a loop (use array + join or a StringBuilder)
- **Unbounded caches or growing lists**: structures that grow indefinitely with no eviction policy
- **Memory leaks**: event listeners without a matching removal, `setInterval`/`setTimeout` without `clear*`, uncancelled subscriptions

### 4. I/O and Network

Look for:
- **Sequential async calls that could be parallel**: `await a(); await b()` when `a` and `b` are independent -- use `Promise.all` or equivalent
- **Missing cache for stable data**: data fetched repeatedly that rarely changes (configuration, reference lists, results of slow queries)
- **Payloads without pagination**: endpoints returning full collections without limit/offset or a cursor
- **Synchronous I/O with an async alternative available**: `fs.readFileSync` where `fs.readFile` would work, `time.sleep` where an async sleep exists

### 5. Frontend (when applicable)

Look for:
- **Unnecessary re-renders**: React/Vue/Svelte components without memoization receiving frequently changing props; inline functions in JSX that recreate references on every render
- **Bundle without code splitting**: static imports of heavy modules that could be loaded on demand via dynamic `import()`
- **Unoptimized images**: `<img>` without `loading="lazy"`, without explicit `width`/`height`, unoptimized formats (JPEG/PNG where WebP would be appropriate)
- **Layout thrashing**: interleaved DOM property reads and writes in a loop (e.g. reading `offsetHeight` and writing `style` repeatedly)

## Analysis Rules

- Report only problems with evidence of real impact: hot paths, loops over production data, high-frequency endpoints.
- Do not suggest premature optimizations -- if there is no data showing the snippet is a bottleneck, classify it as a Suggestion or omit it.
- Provide concrete code snippets in the fix, not just generic descriptions.
- Estimate the impact specifically: "eliminates a re-render of the Table component on every keystroke", not "improves performance".
- If the scope is too large for manual analysis, use `Agent` to distribute the categories in parallel and aggregate the results.

## Output Format

```
## Summary
[1-2 sentences on the overall performance state of the analyzed code.]

## Findings

### Critical (high impact)
- **[/path/file.ext:line]** Clear description of the problem
  - Impact: [e.g. "runs N queries to list N items -- reduces to 1 query with eager loading"]
  - Fix:
    ```language
    // before
    [problematic snippet]

    // after
    [fixed snippet]
    ```

### Important (medium impact)
- **[/path/file.ext:line]** Clear description of the problem
  - Impact: [specific qualitative estimate]
  - Fix: [concrete suggestion, with a snippet if needed]

### Suggestion (low impact)
- **[/path/file.ext:line]** Description
  - Impact: [qualitative estimate]
  - Fix: [suggestion]

## Recommended Metrics
- [What to measure to validate that the optimizations took effect]
- [e.g. "average response time of the /api/items endpoint", "heap size after 1000 requests"]
```
