Unsigned commits: detection and remediation

Purpose
- Provide a clear, auditable process to detect unsigned or bad-signed commits and options to remediate while avoiding dangerous history rewrites.

Detection
- Use `scripts/list_unsigned_commits.sh <count>` to list recent commits that are not GPG-verified. Outputs `/tmp/unsigned_commits.txt` when bad commits are found.

Remediation options (pick one)
1) Allowlist documented exceptions (recommended when commits are historical and approved):
   - Create or update `.github/unsigned_allowlist.txt` and add offending SHAs with a short justification and approver identity.
   - This documents the exception without rewriting history.

2) Recreate commits with signatures (disruptive):
   - Use an interactive rebase to rewrite commits and sign them with a secure key:
     ```bash
     git checkout -b resign-commits
     git rebase -i <oldest-bad-commit>~1
     # mark commits as 'reword' or 'edit' and in each edit run:
     git commit --amend --no-edit -S
     git rebase --continue
     ```
   - Risk: rewriting published history will require force-push and collaborators must rebase/clone.

3) Create a documented PR referencing the unsigned commits and require reviewer approval:
   - Use `scripts/create_unsigned_commits_report.sh` to generate a markdown report and optionally open a PR (requires `gh` CLI and repo permission).

Automation scripts
- `scripts/list_unsigned_commits.sh`: enumerates unsigned commits and writes `/tmp/unsigned_commits.txt`.
- `scripts/create_unsigned_commits_report.sh`: generates a human-readable report in `reports/unsigned_commits_report.md` and can create a draft PR if `gh` CLI is configured.

Policy recommendation
- Prefer allowlisting documented exceptions for legacy commits and use re-signing only for recent, critical commits where history rewrite is acceptable.
- Maintain `.github/unsigned_allowlist.txt` as the canonical record of allowed unsigned commits.
