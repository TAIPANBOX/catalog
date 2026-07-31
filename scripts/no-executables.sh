#!/usr/bin/env bash
# Enforces invariant 1 of CLAUDE.md: no executable ships from this repo.
#
# The moment this repo runs something, it stops being a catalog and becomes an
# undocumented agent in somebody's estate. That distinction is the whole
# product, and it is the kind that erodes one convenience at a time: a helper
# script to apply the templates, then a wrapper to fetch them, then something
# that runs on a schedule.
#
# scripts/ and .githooks/ are exempt: these are this repo's own tooling, they
# are not shipped, and nothing in a release or a template copy carries them.
#
# The .githooks/ exemption was added because this check blocked the very commit
# that installed the hook, the hook being an executable file with a shebang.
# That is the check working: it saw a new executable and refused. The exemption
# is the right fix rather than a workaround, because a pre-push hook is no more
# "shipped" than a gate script is, but it is worth recording that the gate found
# it rather than a reviewer.
#
# This file is the ONE copy of this check.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

problems=0

while IFS= read -r f; do
	case "$f" in
	scripts/* | .githooks/*) continue ;;
	esac
	mode=$(git ls-files -s "$f" | awk '{print $1}')
	if [ "$mode" = "100755" ]; then
		echo "FAIL: $f is executable"
		problems=$((problems + 1))
	fi
	if head -c 2 "$f" 2>/dev/null | grep -q '#!'; then
		echo "FAIL: $f carries a shebang"
		problems=$((problems + 1))
	fi
done < <(git ls-files)

if [ "$problems" -ne 0 ]; then
	echo
	echo "This repo ships templates, not runtime. The moment it runs something it"
	echo "becomes an undocumented agent in somebody's estate."
	echo "See CLAUDE.md invariant 1."
	exit 1
fi

echo "OK: $(git ls-files | grep -cvE '^(scripts|\.githooks)/') shipped files, none executable, none with a shebang."
