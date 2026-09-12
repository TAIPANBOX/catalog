# Security Policy

catalog is copy-paste governance templates (Wardryx policies, Mockryx
drills, Agent Passports, Terraform) for an agent stack an operator already
runs, and it ships no runtime of its own, so its trust boundary is the
correctness of the text an operator copies, edits and loads into their own
tools.

## Reporting a vulnerability

Please report security issues privately, not in public issues or pull
requests: open a GitHub private security advisory at
<https://github.com/TAIPANBOX/catalog/security/advisories/new>. Include the
affected version or commit, a description and a minimal reproduction. We aim
to acknowledge within a few days and to fix high-severity issues before any
public disclosure, with coordinated disclosure within 90 days of the report.
There is no bug-bounty programme; reporters are credited in the advisory
unless they prefer otherwise.

## Supported versions

Before this repository's 1.0, only `main` is supported: fixes land on `main`
and are not backported. From its 1.0 tag, the newest minor gets every fix and
the previous minor gets security-relevant fixes for 90 days after the newer
one is tagged.

## Verifying a build

Every change passes the repository's gates before merge: `scripts/templates-load.sh`
(every template loads with its consumer's own code), `scripts/no-executables.sh`
and `scripts/gates-have-teeth.sh`.
