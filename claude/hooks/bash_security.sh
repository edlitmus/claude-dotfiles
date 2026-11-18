#!/usr/bin/env bash
#
# bash_security.sh — Claude Code PreToolUse hook
#
# Intercepts Bash tool calls before execution and blocks commands that match
# dangerous patterns. Reads the Claude Code JSON payload from stdin, extracts
# the command string, and exits 2 (block) with a message when a threat is found.
#
# Triggered by: PreToolUse / Bash
# Exit codes:
#   0 — command is safe, allow execution
#   2 — command is dangerous, block execution
#
# Tests: claude/hooks/tests/bash_security_test.sh — run them after any edit:
#   bash claude/hooks/tests/bash_security_test.sh ~/.claude/hooks/bash_security.sh
#
# ---------------------------------------------------------------------------
# Platform notes (measured on FreeBSD 15.1, BSD grep 2.6.0-FreeBSD)
#
# This platform's grep has NO -P, so every PCRE-only rule was a silent no-op.
# BSD grep IS "GNU compatible", so \s, \b and \< \> work under -E; all rules
# here are plain ERE for that reason.
#
# Failure policy: fail CLOSED. An unexpected internal error blocks the command
# rather than waving it through — a hook that errors open is worse than one
# that is occasionally inconvenient.
# ---------------------------------------------------------------------------

set -Eeuo pipefail

on_internal_error() {
	echo "BLOCKED: bash_security.sh internal error at line $1 — command not run" >&2
	exit 2
}
trap 'on_internal_error $LINENO' ERR

block() {
	echo "BLOCKED: $1" >&2
	exit 2
}

# Strip one layer of surrounding quotes left over from whitespace tokenizing.
unquote() {
	local s="$1"
	s="${s#[\"\']}"
	s="${s%[\"\']}"
	printf '%s' "$s"
}

# ---------------------------------------------------------------------------
# Directories we refuse to let a command write into. Echoes a label and returns
# 0 when the path is protected.
#
# /usr/home/ is exempt: it is the FreeBSD-style home prefix (this machine's
# $HOME), so writes there are normal user activity, not a system write. The
# exemption is applied PER PATH — previously any command that mentioned
# /usr/home/ anywhere also exempted its other /usr/ writes.
# ---------------------------------------------------------------------------
protected_label() {
	local path
	path="$(unquote "$1")"
	[[ -z "$path" ]] && return 1

	# Credential stores are protected wherever they live, including inside the
	# home directory that the /usr/home/ exemption below would otherwise clear.
	case "$path" in
		*/.ssh|*/.ssh/*|'~/.ssh'|'~/.ssh/'*)         echo "~/.ssh/";   return 0 ;;
		*/.gnupg|*/.gnupg/*|'~/.gnupg'|'~/.gnupg/'*) echo "~/.gnupg/"; return 0 ;;
	esac

	case "$path" in
		/usr/home|/usr/home/*)  return 1 ;;
		/etc|/etc/*)            echo "/etc/";  return 0 ;;
		/boot|/boot/*)          echo "/boot/"; return 0 ;;
		/usr|/usr/*)            echo "/usr/";  return 0 ;;
	esac

	return 1
}

# ---------------------------------------------------------------------------
# Read the JSON payload and extract the command string.
# ---------------------------------------------------------------------------
raw_input="$(cat)"

# An unparseable payload means we cannot know what command is about to run, so
# it is refused rather than waved through. Assignments inside an "if" condition
# are exempt from set -e, which keeps this out of the ERR trap and lets the
# message say what actually went wrong.
command_text=""
if command -v jq >/dev/null 2>&1; then
	if ! command_text="$(printf '%s' "$raw_input" | jq -r '.tool_input.command // empty' 2>/dev/null)"; then
		block "cannot parse the hook payload as JSON — refusing to run an unscanned command"
	fi
else
	# jq-less fallback. The old one used "grep -oP", which does not exist on
	# this platform, so it always yielded an empty string and the hook then
	# checked NOTHING at all.
	if ! command_text="$(printf '%s' "$raw_input" \
		| sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(\([^"\\]\|\\.\)*\)".*/\1/p' \
		| sed -e 's/\\n/\
/g' -e 's/\\t/	/g' -e 's/\\"/"/g' -e 's/\\\\/\\/g')"; then
		block "cannot read the hook payload — refusing to run an unscanned command"
	fi
fi

# ---------------------------------------------------------------------------
# Remove heredoc BODIES before pattern matching.
#
# The hook matches the whole command string, so a heredoc body that merely
# *mentions* a protected path (writing documentation, or generating an install
# script) used to trip the rules. Bodies are data, not commands.
#
# Stripping does NOT weaken the interpreter-heredoc rule below: stripping drops
# heredoc BODIES but keeps the opening line, so "bash <<EOF" is still caught
# after stripping, while a body that merely quotes that phrase is not.
# ---------------------------------------------------------------------------
strip_heredoc_bodies() {
	awk '
	BEGIN { in_body = 0; delim = "" }
	{
		if (in_body) {
			line = $0
			sub(/^[ \t]+/, "", line)        # <<- permits leading tabs
			if (line == delim || $0 == delim) { in_body = 0; delim = "" }
			next
		}
		print
		rest = $0
		# A delimiter may be bare, or single/double quoted. "<<<" is a
		# herestring, not a heredoc: "<" appears in no branch below, so it
		# cannot match. \047 is a single quote.
		while (match(rest, /<<-?[ \t]*(\047[^\047]+\047|"[^"]+"|[A-Za-z_][A-Za-z0-9_]*)/)) {
			tok = substr(rest, RSTART, RLENGTH)
			rest = substr(rest, RSTART + RLENGTH)
			sub(/^<<-?[ \t]*/, "", tok)
			gsub(/[\047"]/, "", tok)
			delim = tok
			in_body = 1
		}
	}
	'
}

# Drop redirection operators and their targets, leaving the real arguments.
# Redirection targets are checked separately, by check_segment.
strip_redirections() {
	local -a kept=()
	local skip_next=0 tok
	for tok in "$@"; do
		if (( skip_next )); then skip_next=0; continue; fi
		case "$tok" in
			'>'|'>>'|'>|'|'<'|'2>'|'2>>'|'&>'|'&>>'|'1>'|'1>>') skip_next=1; continue ;;
			*'>'*|'<'*) continue ;;
		esac
		kept+=("$tok")
	done
	(( ${#kept[@]} )) && printf '%s\n' "${kept[@]}"
	return 0
}

# Drop leading tokens that are not the utility itself (sudo, env, VAR=val, …).
drop_command_prefixes() {
	local -a rest=("$@")
	while (( ${#rest[@]} )); do
		case "$(unquote "${rest[0]}")" in
			sudo|doas|env|nohup|time|command|exec|builtin) ;;
			-*) ;;
			*=*) ;;
			*) break ;;
		esac
		rest=("${rest[@]:1}")
	done
	(( ${#rest[@]} )) && printf '%s\n' "${rest[@]}"
	return 0
}

[[ -z "$command_text" ]] && exit 0

# Invisible Unicode is checked on the RAW text: a zero-width character hidden in
# a heredoc body is still worth refusing. This rule was PCRE-only and therefore
# entirely dead; matching raw UTF-8 bytes under LC_ALL=C works here.
if LC_ALL=C grep -qE $'\xe2\x80\x8b|\xe2\x80\x8c|\xe2\x80\x8d|\xef\xbb\xbf|\xc2\xad|\xe2\x80\xa8|\xe2\x80\xa9' <<< "$command_text"; then
	block "invisible Unicode characters detected in command"
fi

scan_text="$(printf '%s' "$command_text" | strip_heredoc_bodies)"

# ---------------------------------------------------------------------------
# 0. Interpreter heredocs. Checked AFTER body stripping: the opening line
#    survives stripping, so a real "bash <<EOF" is still caught, while a
#    heredoc body that merely documents the phrase is not a false positive.
# ---------------------------------------------------------------------------
if grep -qE '(^|[^[:alnum:]_/.-])((ba|z|k|da)?sh|python3?|perl|ruby|node)[[:space:]]+[^|;&]*<<' <<< "$scan_text"; then
	block "heredoc fed into an interpreter — write a script file and run that instead"
fi

# ---------------------------------------------------------------------------
# 1. Command substitution in dangerous contexts
# ---------------------------------------------------------------------------
if grep -qE '\$\((rm|mkfs|dd )[^)]*\)' <<< "$scan_text"; then
	block "command substitution with destructive command (\$(rm / \$(mkfs / \$(dd))"
fi

# ---------------------------------------------------------------------------
# 2. Pipes to shell interpreters
# ---------------------------------------------------------------------------
if grep -qE '\|\s*(bash|sh|zsh)\b' <<< "$scan_text"; then
	block "piping output into a shell interpreter (| bash / | sh / | zsh)"
fi

# ---------------------------------------------------------------------------
# 3. Writing to protected directories
#
# The old rules were (>>?|tee |cp |mv |install )\s*/etc/ and friends, which
# matched only when the protected path was the token IMMEDIATELY AFTER the
# command word. For cp/mv/install that token is the SOURCE, so the rule was
# inverted:
#   blocked   cp /etc/rc.conf /tmp/copy     (a harmless read)
#   permitted cp /tmp/staged  /etc/rc.conf  (the actual system write)
# Destinations are now resolved by tokenizing each command segment.
# ---------------------------------------------------------------------------
check_segment() {
	local segment="$1"
	local depth="${2:-0}"
	local -a tokens=() args=() real=() inner=()
	local tok label target utility dest i
	local want_next=0

	(( depth > 3 )) && return 0

	read -ra tokens <<< "$segment" || true
	(( ${#tokens[@]} )) || return 0

	# --- redirection targets, whatever the utility ---
	for tok in "${tokens[@]}"; do
		if (( want_next )); then
			want_next=0
			if label="$(protected_label "$tok")"; then
				block "writing to $label (redirect into $tok)"
			fi
			continue
		fi
		case "$tok" in
			'>'|'>>'|'>|'|'2>'|'2>>'|'&>'|'&>>'|'1>'|'1>>') want_next=1 ;;
			*'>'*)
				target="${tok##*>}"
				if [[ -n "$target" ]] && label="$(protected_label "$target")"; then
					block "writing to $label (redirect into $target)"
				fi ;;
		esac
	done

	# --- utility-specific destinations ---
	mapfile -t args < <(drop_command_prefixes "${tokens[@]}") || true
	(( ${#args[@]} )) || return 0
	utility="$(basename -- "$(unquote "${args[0]}")")"

	if (( ${#args[@]} > 1 )); then
		mapfile -t real < <(strip_redirections "${args[@]:1}") || true
	else
		real=()
	fi

	case "$utility" in
		cp|mv|install|rsync|ln)
			(( ${#real[@]} )) || return 0
			# Explicit target-directory form, when present, wins over last-arg.
			for (( i = 0; i < ${#real[@]}; i++ )); do
				if [[ "$(unquote "${real[i]}")" == "-t" || "$(unquote "${real[i]}")" == "--target-directory" ]]; then
					dest="${real[i+1]:-}"
					if [[ -n "$dest" ]] && label="$(protected_label "$dest")"; then
						block "writing to $label ($utility target $dest)"
					fi
					return 0
				fi
			done
			dest="${real[-1]}"
			if label="$(protected_label "$dest")"; then
				block "writing to $label ($utility destination $dest)"
			fi ;;
		tee)
			# Every non-option argument to tee is a file it writes.
			for tok in "${real[@]+"${real[@]}"}"; do
				[[ "$tok" == -* ]] && continue
				if label="$(protected_label "$tok")"; then
					block "writing to $label (tee $tok)"
				fi
			done ;;
		dd)
			for tok in "${real[@]+"${real[@]}"}"; do
				if [[ "$(unquote "$tok")" == of=* ]] \
					&& label="$(protected_label "${tok#*of=}")"; then
					block "writing to $label (dd $tok)"
				fi
			done ;;
		sed)
			# In-place editing rewrites the file it is pointed at.
			if printf '%s\n' "${real[@]+"${real[@]}"}" | grep -qE '^(-[a-zA-Z]*i|--in-place)'; then
				for tok in "${real[@]+"${real[@]}"}"; do
					[[ "$tok" == -* ]] && continue
					if label="$(protected_label "$tok")"; then
						block "writing to $label (in-place edit of $tok)"
					fi
				done
			fi ;;
		rm|truncate)
			for tok in "${real[@]+"${real[@]}"}"; do
				[[ "$tok" == -* ]] && continue
				if label="$(protected_label "$tok")"; then
					block "modifying $label ($utility $tok)"
				fi
			done ;;
		sh|bash|zsh|ksh|dash)
			# "sh -c '<cmd>'" hides the real utility one level down.
			for (( i = 0; i < ${#real[@]}; i++ )); do
				if [[ "$(unquote "${real[i]}")" == "-c" ]]; then
					inner=("${real[@]:i+1}")
					break
				fi
			done
			if (( ${#inner[@]} )); then
				check_segment "$(printf '%s ' "${inner[@]}")" "$(( depth + 1 ))"
			fi ;;
	esac
	return 0
}

# Split into command segments. Two-character operators first, so they are not
# shredded into single ones.
segments="$(printf '%s' "$scan_text" \
	| sed -e 's/&&/\
/g' -e 's/||/\
/g' -e 's/|/\
/g' -e 's/;/\
/g' -e 's/&/\
/g')"

while IFS= read -r segment; do
	[[ -z "${segment//[[:space:]]/}" ]] && continue
	check_segment "$segment" 0
done <<< "$segments"

# ---------------------------------------------------------------------------
# 4. Mass permission changes
# ---------------------------------------------------------------------------
if grep -qE 'chmod\s+-R\s+(777|666)\b' <<< "$scan_text"; then
	block "mass permission change (chmod -R 777 / chmod -R 666)"
fi

if grep -qE 'chown\s+-R\b' <<< "$scan_text"; then
	block "recursive ownership change (chown -R)"
fi

# ---------------------------------------------------------------------------
# 5. Disk-destructive commands
# ---------------------------------------------------------------------------
if grep -qE '\bmkfs\b' <<< "$scan_text"; then
	block "disk format command (mkfs)"
fi

if grep -qE '\bdd\s+if=' <<< "$scan_text"; then
	block "disk-dump/overwrite command (dd if=)"
fi

# FreeBSD disk device names added alongside the Linux ones.
if grep -qE '>\s*/dev/(sd[a-z]|da[0-9]|ada[0-9]|nvme[0-9]|vtbd[0-9]|mfid[0-9])' <<< "$scan_text"; then
	block "redirecting output to a raw block device"
fi

# ---------------------------------------------------------------------------
# 6. Fork bombs
# ---------------------------------------------------------------------------
if grep -qE ':\(\)\s*\{' <<< "$scan_text" \
	|| grep -qE '\(\s*\)\s*\{[^}]*\|\s*&' <<< "$scan_text" \
	|| grep -qF ':|:&' <<< "$scan_text"; then
	block "fork bomb pattern detected"
fi

# ---------------------------------------------------------------------------
# 7. Process kill-all commands
# ---------------------------------------------------------------------------
if grep -qE '\bkillall\b' <<< "$scan_text"; then
	block "process kill-all command (killall)"
fi

if grep -qE '\bpkill\s+-9\b' <<< "$scan_text"; then
	block "force kill-all processes (pkill -9)"
fi

# ---------------------------------------------------------------------------
# 8. Shell history manipulation
# ---------------------------------------------------------------------------
if grep -qE '\bhistory\s+-(c|w)\b' <<< "$scan_text"; then
	block "shell history manipulation (history -c / history -w)"
fi

# ---------------------------------------------------------------------------
# 9. Network backdoor setup
# ---------------------------------------------------------------------------
if grep -qE '\b(nc|ncat)\s+.*-l\b' <<< "$scan_text"; then
	block "network listener / potential backdoor (nc -l / ncat -l)"
fi

exit 0
