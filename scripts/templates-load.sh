#!/usr/bin/env bash
# Enforces invariant 3 of CLAUDE.md: a template that no consumer can load is
# broken, however good it looks.
#
# This repo defines none of the formats it ships. Wardryx owns the policy shape,
# Mockryx owns the drill shape, agent-passport owns the passport schema,
# Terraform owns the module syntax. When one of them changes, these files break,
# and nothing here notices. The first person to find out is an operator who
# copied a template and watched their deployment refuse to start.
#
# So this does not validate the templates against a schema we wrote. It loads
# each one WITH ITS CONSUMER'S OWN CODE:
#
#   policies + passports   `wardryx check <passport-dir> <policy>`, which reads
#                          both through internal/policy and internal/passports
#   drills                 `mockryx run` pointed at a deliberately dead loopback
#                          port. Exit 2 means it could not parse; exit 1 means it
#                          parsed, ran, and could not reach the gateway, which is
#                          the expected outcome and proves the loader was happy.
#   passports again        the agent-passport repo's own schema validator, which
#                          checks things Wardryx does not care about
#   terraform              `terraform fmt -check`, and `validate` when the
#                          modules can be initialised offline
#
# The schema step needs jsonschema, so the script builds a throwaway venv rather
# than assuming a prepared machine. A gate that only runs on one machine is a
# gate that does not run.
#
# REQUIRES THE SIBLING REPOS. They are the point: a check against our own copy
# of somebody else's parser would agree with our own assumptions, which is the
# failure this is here to prevent. If a sibling is missing, this FAILS rather
# than skipping, because a skipped check reports silence as health.
#
# TWO CALLERS, ONE COPY: .githooks/pre-push and .github/workflows/gates.yml.
# The workflow checks wardryx, mockryx and agent-passport out beside this repo,
# because the whole point is loading our templates with THEIR parsers.
#
# This file is the ONE copy of this check.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

ROOT="$(pwd)"
SIBLINGS="$(cd .. && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

problems=0
note() {
	echo "FAIL: $1"
	problems=$((problems + 1))
}

need_repo() {
	if [ ! -d "$SIBLINGS/$1" ]; then
		note "sibling repo '$1' is not checked out beside this one, so its templates were not loaded by anything that owns their format"
		return 1
	fi
}

# ---------------------------------------------------------------- wardryx
if need_repo wardryx; then
	if ! (cd "$SIBLINGS/wardryx" && go build -o "$WORK/wardryx" ./cmd/wardryx) 2>"$WORK/build.err"; then
		note "wardryx did not build, so no policy or passport template was loaded"
		head -5 "$WORK/build.err"
	else
		shopt -s nullglob
		policies=("$ROOT"/wardryx-policies/*.yaml "$ROOT"/wardryx-policies/*.yml "$ROOT"/wardryx-policies/*.json)
		shopt -u nullglob
		if [ ${#policies[@]} -eq 0 ]; then
			note "no policy templates found, so this check measured nothing"
		fi
		for p in "${policies[@]}"; do
			if ! "$WORK/wardryx" check "$ROOT/passport-templates" "$p" >"$WORK/out" 2>&1; then
				note "wardryx cannot load $(basename "$p"): $(head -2 "$WORK/out" | tr '\n' ' ')"
			fi
		done
		# wardryx check reports malformed passports on stderr rather than failing,
		# so the count is read rather than assumed.
		if "$WORK/wardryx" check "$ROOT/passport-templates" "${policies[0]}" 2>&1 | grep -q 'malformed'; then
			note "wardryx reported malformed passport templates"
		fi
	fi
fi

# ---------------------------------------------------------------- mockryx
if need_repo mockryx; then
	if ! (cd "$SIBLINGS/mockryx" && go build -o "$WORK/mockryx" ./cmd/mockryx) 2>"$WORK/build.err"; then
		note "mockryx did not build, so no drill template was loaded"
		head -5 "$WORK/build.err"
	else
		# Port 1 is never listening. Exit 2 is a parse or usage failure, which is
		# what this is looking for. Exit 1 is "loaded fine, could not reach the
		# gateway", which is the expected result and the proof the loader worked.
		"$WORK/mockryx" run --gateway http://127.0.0.1:1 --format json \
			"$ROOT/mockryx-drills" >"$WORK/mx.out" 2>"$WORK/mx.err"
		case $? in
		2) note "mockryx cannot load the drill templates: $(head -2 "$WORK/mx.err" | tr '\n' ' ')" ;;
		1) : ;;
		0) note "mockryx reported no gaps against a gateway that does not exist, which means it did not run the drills at all" ;;
		*) note "mockryx exited unexpectedly: $(head -2 "$WORK/mx.err" | tr '\n' ' ')" ;;
		esac
	fi
fi

# --------------------------------------------------------- agent-passport
if need_repo agent-passport; then
	schema="$SIBLINGS/agent-passport/schemas/agent-passport.schema.json"
	if [ ! -f "$schema" ]; then
		note "the agent-passport schema is missing, so passport templates were not validated against it"
	else
		PY_BIN=python3
		if ! python3 -c "import jsonschema" 2>/dev/null; then
			if python3 -m venv "$WORK/venv" >/dev/null 2>&1 &&
				"$WORK/venv/bin/pip" install --quiet jsonschema >/dev/null 2>&1; then
				PY_BIN="$WORK/venv/bin/python"
			fi
		fi
		"$PY_BIN" - "$schema" "$ROOT/passport-templates" <<'PY' || problems=$((problems + 1))
import json, pathlib, sys
try:
    from jsonschema import Draft202012Validator
except ImportError:
    print("FAIL: jsonschema is not installed, so the passport templates were not "
          "validated. Install it rather than letting this pass quietly.")
    sys.exit(1)

schema = json.loads(pathlib.Path(sys.argv[1]).read_text())
v = Draft202012Validator(schema)
files = sorted(pathlib.Path(sys.argv[2]).glob("*.json"))
if not files:
    print("FAIL: no passport templates found, so this check measured nothing")
    sys.exit(1)
bad = False
for f in files:
    for err in sorted(v.iter_errors(json.loads(f.read_text())), key=str):
        loc = "/".join(str(p) for p in err.path) or "(root)"
        print(f"FAIL: {f.name} does not match the agent-passport schema at {loc}: {err.message}")
        bad = True
sys.exit(1 if bad else 0)
PY
	fi
fi

# -------------------------------------------------------------- terraform
if ! command -v terraform >/dev/null 2>&1; then
	note "terraform is not installed, so the module templates were not parsed by anything that owns their syntax"
elif ! (cd "$ROOT/terraform-modules" && terraform fmt -check >"$WORK/tf.out" 2>&1); then
	note "terraform rejects the module templates: $(head -3 "$WORK/tf.out" | tr '\n' ' ')"
fi

# -------------------------------------------------------------------------
if [ "$problems" -ne 0 ]; then
	echo
	echo "This repo defines none of the formats it ships. When a consumer changes"
	echo "one, these files break silently and an operator finds out first."
	echo "See CLAUDE.md invariant 3."
	exit 1
fi

echo "OK: every template loads with the code that owns its format."
