#!/usr/bin/env bash
#
# Regression tests for secret_scan.sh, session_start.sh and the inline
# sensitive-file guard in settings.json.
#
# Usage: hooks_regression_test.sh [hooks-dir] [settings.json]
#
# Credential fixtures are generated at runtime so this file contains no literal
# token shapes and therefore does not trip the scanner it is testing.

R="${1:-$HOME/.claude/hooks}"
S="${2:-$HOME/.claude/settings.json}"

pass=0; fail=0
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

ok()   { pass=$((pass + 1)); printf '  ok       %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL     %s\n' "$1"; }

rep() { printf "$1%.0s" $(seq "$2"); }   # repeat char $1, $2 times

scan() { # file -> hook output
	printf '{"tool_input":{"file_path":"%s"}}' "$1" | bash "$R"/secret_scan.sh 2>&1
}

# --- A. every configured pattern must actually fire -------------------------
echo "== secret_scan.sh: all 13 patterns must be reachable =="

detect() { # label, expected-pattern-name, file-content
	local label="$1" want="$2" body="$3" f out
	f="$W/$(echo "$label" | tr -cd 'a-z0-9').txt"
	printf '%s\n' "$body" > "$f"
	out="$(scan "$f")"
	if printf '%s' "$out" | grep -qF "Pattern: $want"; then
		ok "$label"
	else
		bad "$label  (expected \"Pattern: $want\"; got: ${out:-<silence>})"
	fi
}

detect "aws access key"   "AWS Access Key"            "key=AKIA$(rep A 16)"
detect "aws secret key"   "AWS Secret Key"            "aws_secret_key = \"$(rep b 40)\""
detect "anthropic key"    "Anthropic API Key"         "k=sk-ant-api$(rep c 24)"
detect "github pat"       "GitHub PAT"                "k=ghp_$(rep d 36)"
detect "github oauth"     "GitHub OAuth Token"        "k=gho_$(rep e 36)"
detect "openai key"       "OpenAI API Key"            "k=sk-$(rep f 48)"
detect "slack bot"        "Slack Bot Token"           "k=xoxb-$(rep 1 12)"
detect "slack user"       "Slack User Token"          "k=xoxp-$(rep 2 12)"
detect "stripe secret"    "Stripe Live Secret"        "k=sk_live_$(rep g 26)"
detect "stripe publish"   "Stripe Live Publishable"   "k=pk_live_$(rep h 26)"
# This is the one that silently never matched: the pattern starts with "-----",
# so without "grep -e" it was parsed as command-line options.
detect "private key"      "Private Key Block"         "-----BEGIN RSA PRIVATE KEY-----"
detect "db connection"    "DB Connection String"      "u=postgres://user:pw@localhost/db"
detect "generic token"    "Generic Auth Token"         "api_key = \"$(rep i 24)\""

echo
echo "== secret_scan.sh: no false alarms, no crashes =="
printf 'just some ordinary prose\nconst timeout = 30\n' > "$W"/clean.txt
[ -z "$(scan "$W"/clean.txt)" ] && ok "clean file stays silent" || bad "clean file flagged"
[ -z "$(scan "$W"/missing-file.txt)" ] && ok "missing file handled" || bad "missing file not handled"
printf '\177ELF\002\001\ardware' > "$W"/blob.bin
[ -z "$(scan "$W"/blob.bin)" ] && ok "binary skipped" || bad "binary not skipped"

# Guard against a future pattern that starts with a dash slipping in unnoticed.
echo
echo "== secret_scan.sh: dash-leading patterns are invoked safely =="
if grep -qE 'grep -q \$GP -e' "$R"/secret_scan.sh; then
	ok "pattern passed via -e"
else
	bad "pattern NOT passed via -e — dash-leading patterns will be read as options"
fi

# --- B. session_start.sh must emit well-formed, uninjectable JSON -----------
echo
echo "== session_start.sh: JSON is built safely from repo-controlled input =="
cd "$W" || exit 1

emit() { bash "$R"/session_start.sh; }

out="$(emit)"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 && ok "clean dir: valid JSON" || bad "clean dir: invalid JSON"

printf 'module "evil\n' > go.mod
out="$(emit)"
if printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
	ok "quote in go.mod: still valid JSON"
else
	bad "quote in go.mod: invalid JSON (context would be silently dropped)"
fi

printf 'module x","injected":"PWNED\n' > go.mod
out="$(emit)"
keys="$(printf '%s' "$out" | jq -r '.hookSpecificOutput | keys | join(",")' 2>/dev/null)"
if [ "$keys" = "additionalContext,hookEventName" ]; then
	ok "injection attempt adds no keys (keys: $keys)"
else
	bad "unexpected keys in hookSpecificOutput: $keys"
fi
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)"
case "$ctx" in
	"Active hooks:"*) ok "additionalContext not overwritten" ;;
	*) bad "additionalContext was overwritten: $ctx" ;;
esac
rm -f go.mod
cd / || exit 1

# --- C. the inline guard, read from the live settings.json ------------------
echo
echo "== inline sensitive-file guard (replayed from settings.json) =="
jq -r '.hooks.PreToolUse[0].hooks[0].command' "$S" > "$W"/guard.sh 2>/dev/null

verdict() {
	local out reason
	out="$(printf '{"tool_input":{"file_path":"%s"}}' "$1" | bash "$W"/guard.sh 2>&1)"
	[ -z "$out" ] && { echo allow; return; }
	reason="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason' 2>/dev/null)"
	case "$reason" in
		*Sensitive*) echo sensitive ;;
		*Configuration*) echo config ;;
		*) echo other ;;
	esac
}

g() { # expected, path
	local got; got="$(verdict "$2")"
	[ "$got" = "$1" ] && ok "$2 -> $got" || bad "$2 -> got '$got', wanted '$1'"
}

# Hook sources are code, not credential stores; exempted so the scanner's own
# file (whose name matches *secret*) stays maintainable.
g allow     /home/ed/claude-dotfiles/claude/hooks/secret_scan.sh
g allow     /home/ed/.claude/hooks/secret_scan.sh
# Config protection needs BOTH spellings: a "*/claude/..." glob requires a
# literal slash before "claude", so it does not match "/.claude/".
g config    /home/ed/.claude/settings.json
g config    /usr/home/ed/claude-dotfiles/claude/settings.json
g config    /home/ed/project/.git/config
g config    /home/ed/project/.git/hooks/pre-commit
g sensitive /home/ed/project/.env
g sensitive /home/ed/project/.env.production
g sensitive /home/ed/project/config/credentials.yml
g sensitive /home/ed/project/server.pem
g sensitive /home/ed/project/tls.key
g sensitive /home/ed/.ssh/id_rsa
g allow     /home/ed/project/src/main.go
g allow     /home/ed/project/README.md

echo
printf 'passed %d, failed %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
