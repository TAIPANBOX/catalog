#!/usr/bin/env bash
# Enforces invariant 1 of CLAUDE.md: no executable ships from this repo.
#
# The moment this repo runs something, it stops being a catalog and becomes an
# undocumented agent in somebody's estate. That distinction is the whole
# product, and it is the kind that erodes one convenience at a time: a helper
# script to apply the templates, then a wrapper to fetch them, then something
# that runs on a schedule.
#
# scripts/ is exempt: these are this repo's own gates, they are not shipped, and
# nothing in a release or a template copy carries them.
#
# This file is the ONE copy of this check.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

problems=0

while IFS= read -r f; do
	case "$f" in
	scripts/*) continue ;;
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

echo "OK: $(git ls-files | grep -cv '^scripts/') tracked files, none executable, none with a shebang."
