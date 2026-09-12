---
name: security-audit
description: Code security audit — analyzes vulnerabilities, dependencies, and configuration.
argument-hint: "[file, directory, or 'full' for the whole project]"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Agent
model: opus
effort: high
context: fork
agent: security
---

# Security Audit

Run a security audit on: `$ARGUMENTS`

If the argument is "full" or empty, audit the whole project.

## Audit scope

### 1. Secrets & Credentials
```bash
# Look for suspicious patterns
grep -rn "password\|secret\|api_key\|token\|private_key" --include="*.py" --include="*.ts" --include="*.js" --include="*.go" --include="*.env" .
```
- Check .gitignore for .env and credential files
- Check for hardcoded secrets

### 2. Code vulnerabilities
- SQL injection (concatenated queries)
- XSS (unescaped output)
- Command injection (shell commands with user input)
- Path traversal (file paths with user input)
- SSRF (URLs built from user input)
- Insecure deserialization

### 3. Dependencies
```bash
# Python
pip audit 2>/dev/null || echo "pip-audit not installed"
# Node
npm audit 2>/dev/null || echo "npm not found"
# Go
govulncheck ./... 2>/dev/null || echo "govulncheck not installed"
```

### 4. Configuration
- Is CORS configured correctly?
- Is HTTPS enforced?
- Security headers (CSP, HSTS, X-Frame-Options)?
- Rate limiting?
- Logging free of PII?

## Report format
```
# 🔒 Security Report
Date: [date]
Scope: [files analyzed]

## Summary
- Critical: X
- High: X
- Medium: X
- Low: X
- Info: X

## Vulnerabilities
### 🔴 [CRITICAL] Title
**File**: path:line
**Impact**: ...
**Fix**: ...

[repeat for each finding]

## General recommendations
1. ...
2. ...
```
