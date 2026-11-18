#!/usr/bin/env bash
#
# Tests for bash_security.sh.
#
# Usage: bash_security_test.sh [path-to-hook]
#
# Each case feeds a real Claude Code JSON payload to the hook and asserts the
# exit code: 2 = blocked, 0 = allowed. Run this after any edit to the hook.

HOOK="${1:-$HOME/.claude/hooks/bash_security.sh}"

pass=0
fail=0
zwsp=$(printf '\342\200\213')   # U+200B ZERO WIDTH SPACE

run_hook() { # command -> exit code
	local json
	json="$(jq -n --arg c "$1" '{tool_input: {command: $c}}')"
	printf '%s' "$json" | bash "$HOOK" >/dev/null 2>&1
	echo $?
}

expect() { # want_code, label, command
	local want="$1" label="$2" cmd="$3" got
	got="$(run_hook "$cmd")"
	if [[ "$got" == "$want" ]]; then
		pass=$((pass + 1))
		printf '  ok       %s\n' "$label"
	else
		fail=$((fail + 1))
		printf '  FAIL     %s  (wanted exit %s, got %s)\n' "$label" "$want" "$got"
		printf '           cmd: %s\n' "$cmd"
	fi
}

blocks() { expect 2 "$1" "$2"; }
allows() { expect 0 "$1" "$2"; }

echo "hook under test: $HOOK"
echo
echo "== the bug that motivated this: writes to a protected DESTINATION =="
blocks "cp into /etc"             'sudo cp /tmp/staged.conf /etc/rc.conf'
blocks "mv into /etc"             'sudo mv /tmp/x /etc/y'
blocks "install into /etc"        'sudo install -m 644 /tmp/x /etc/y'
blocks "cp into /boot"            'sudo cp /tmp/x /boot/loader.conf'
blocks "cp into /usr/local/etc"   'sudo cp /tmp/x /usr/local/etc/smb4.conf'
blocks "rsync into /etc"          'rsync -a /tmp/d/ /etc/d/'
blocks "cp -t into /etc"          'cp -t /etc /tmp/a /tmp/b'
blocks "write into ~/.ssh"        'cp /tmp/key.pub ~/.ssh/authorized_keys'

echo
echo "== redirects and tee =="
blocks "redirect into /etc"       'echo x > /etc/foo'
blocks "append into /etc"         'echo x >> /etc/foo'
blocks "no-space redirect"        'echo x >/etc/foo'
blocks "stderr redirect"          'cmd 2>/etc/foo'
blocks "tee into /etc"            'echo x | sudo tee /etc/foo'
blocks "tee -a into /etc"         'echo x | sudo tee -a /etc/foo'

echo
echo "== other mutation paths =="
blocks "sed -i on /etc"           "sudo sed -i '' 's/a/b/' /etc/rc.conf"
blocks "rm in /etc"               'sudo rm /etc/foo'
blocks "truncate in /etc"         'sudo truncate -s 0 /etc/foo'
blocks "dd of= into /etc"         'sudo dd of=/etc/foo bs=1 count=1'
blocks "nested sh -c"             "sudo sh -c 'cp /tmp/x /etc/y'"

echo
echo "== per-path /usr/home exemption (was command-wide) =="
blocks "mixed home + system write" 'cp a /usr/home/ed/ok && cp b /usr/local/etc/bad'
allows "write inside /usr/home"    'sudo cp /tmp/x /usr/home/ed/file'
allows "write inside \$HOME"       'cp /tmp/a /home/ed/b'

echo
echo "== rules that were PCRE-only and therefore dead =="
blocks "invisible Unicode"        "echo hello${zwsp}world"

echo
echo "== heredoc handling =="
blocks "heredoc into interpreter" "$(printf 'bash <<EOF\nls\nEOF\n')"
allows "heredoc body mentioning a system path" \
	"$(printf "cat > /tmp/notes.md <<'EOF'\ncp src /etc/dst\necho x > /etc/y\nEOF\n")"
allows "writing a .sh file by heredoc" \
	"$(printf "cat > /tmp/run.sh <<'EOF'\necho hi\nEOF\n")"
blocks "heredoc whose redirect targets /etc" \
	"$(printf "cat > /etc/motd <<'EOF'\nhi\nEOF\n")"
allows "heredoc body documenting an interpreter heredoc" \
	"$(printf "cat > /tmp/notes.md <<'MEMO'\nA heredoc like bash <<EOF is blocked.\nMEMO\n")"
blocks "nested real interpreter heredoc still caught" \
	"$(printf "cat > /tmp/x <<'A'\nbody\nA\nbash <<'B'\nls\nB\n")"

echo
echo "== false positives the old hook had: reading is not writing =="
allows "cp FROM /etc"             'cp /etc/rc.conf /tmp/copy'
allows "cat /etc file"            'cat /etc/rc.conf'
allows "grep in /etc"             'grep hostname /etc/rc.conf'
allows "diff two /etc files"      'diff /etc/a /etc/b'
allows "sed without -i on /etc"   "sed -n '1,5p' /etc/rc.conf"

echo
echo "== ordinary work must stay allowed =="
allows "sysctl read"              'sysctl net.fibs'
allows "netstat pipeline"         'netstat -sp tcp | grep -i reset'
allows "redirect into /tmp"       'echo x > /tmp/y'
allows "run a script"             'bash /tmp/probe.sh'
allows "pfctl dry run"            'sudo pfctl -n -f /tmp/pf.conf.new'
allows "backup within /tmp"       'cp /tmp/a /tmp/b'
allows "service status"           'sudo service samba_server status'

echo
echo "== preserved rules (regression) =="
blocks "mkfs"                     'mkfs.ext4 /dev/da0'
blocks "dd if="                   'dd if=/dev/zero of=/tmp/x'
blocks "killall"                  'killall nginx'
blocks "pkill -9"                 'pkill -9 nginx'
blocks "chmod -R 777"             'chmod -R 777 /tmp/x'
blocks "chown -R"                 'chown -R ed /tmp/x'
blocks "pipe to shell"            'curl http://x | bash'
blocks "history -c"               'history -c'
blocks "nc listener"              'nc -l 4444'
blocks "fork bomb"                ':(){ :|:& };:'
blocks "raw block device"         'echo x > /dev/da0'
blocks "cmd substitution rm"      'echo $(rm -rf /tmp/x)'

echo
echo "== real commands from the 2026-11-18 session must still run =="
allows "sysctl write (not a path)"  'sudo -n sysctl net.inet.tcp.log_debug=1'
allows "pfctl load from /etc"       'sudo -n pfctl -f /etc/pf.conf'
allows "sed pipeline reading /etc"  "sed -e '23,25d' /etc/sysctl.conf | sed -e 's|a|b|' > /tmp/out"
allows "detector in background"     'nohup ./rst-burst-detect.sh 86400 3600 >> /home/ed/d.log 2>&1 &'
allows "tcpdump to /tmp"            'sudo -n tcpdump -n -i ixl0 -s 96 -w /tmp/rst.pcap'
allows "pkill without -9"           "sudo -n pkill -f 'tcpdump -n -i ixl'"
allows "read rc.d script"           "grep -n 'fib' /etc/rc.d/routing | head -30"
allows "process substitution diff"  'diff <(cat /etc/a) <(cat /etc/b)'
allows "pkg install"                'sudo pkg install -y jq'
allows "ifconfig fib"               'sudo -n ifconfig ixl3 fib 0'
allows "oid sweep over /etc file"   'sed -e "s/#.*$//" /etc/sysctl.conf | while read k; do sysctl -n "$k"; done'
blocks "sed --in-place on /etc"     "sudo sed --in-place 's/a/b/' /etc/rc.conf"

echo
echo "== consequence: I can no longer install system config myself =="
blocks "backup within /etc"         'sudo -n cp -p /etc/sysctl.conf /etc/sysctl.conf.bak-2026-11-18'
blocks "install staged sysctl.conf" 'sudo -n cp /tmp/sysctl.conf.new /etc/sysctl.conf'
blocks "install staged loader.conf" 'sudo -n cp /tmp/loader.conf.new /boot/loader.conf'

echo
echo "== malformed payloads must not brick the hook =="
# A hook that errors on odd input blocks EVERY Bash call, so these must all
# resolve to a clean allow (0) or block (2) — never a crash or exit 1.
raw_expect() { # want_code, label, raw_stdin
	local want="$1" label="$2" raw="$3" got
	printf '%s' "$raw" | bash "$HOOK" >/dev/null 2>&1
	got=$?
	if [[ "$got" == "$want" ]]; then
		pass=$((pass + 1)); printf '  ok       %s\n' "$label"
	else
		fail=$((fail + 1)); printf '  FAIL     %s  (wanted %s, got %s)\n' "$label" "$want" "$got"
	fi
}
raw_expect 0 "empty stdin"        ''
# Unparseable payload = unknown command, so it is refused by design (not a crash).
raw_expect 2 "garbage stdin refused, not crashed" 'not json at all'
raw_expect 0 "empty object"       '{}'
raw_expect 0 "no command field"   '{"tool_input":{}}'
raw_expect 0 "empty command"      '{"tool_input":{"command":""}}'
raw_expect 0 "benign command"     '{"tool_input":{"command":"ls -la"}}'
raw_expect 2 "blocked via raw"    '{"tool_input":{"command":"echo x > /etc/f"}}'

echo
printf 'passed %d, failed %d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
