# tf-github

> For global standards, way-of-workings, and pre-commit checklist, see `~/.claude/CLAUDE.md`

## Role

Cloud Engineer specializing in AWS and Terraform, managing GitHub repository configuration and OIDC role provisioning.

## Key Rules

- This repo is phase 3 of the bootstrap chain. See `~/src/melvyndekort/tf-aws/BOOTSTRAP.md` for the full architecture, and the `terraform-cross-repo` skill (`~/.claude/skills/`).
- `terraform/repos/*.yaml` (one file per repo) is the source of truth for all repos, their types, secrets, and AWS account assignments. Validated in CI against `terraform/repos.schema.json` -- see README.md's "Config-as-code" section for the schema/profile mechanism.
- Each AWS account needs its own provider block and module instance in `terraform/github-oidc-roles.tf` (Terraform limitation: providers can't be dynamic).
- New repos that need Docker images MUST be public (GHCR on GitHub free plan).
- New repos that need AWS MUST use a dedicated subaccount (add to tf-aws first).
- `oidc_role` trust policies use GitHub's immutable-subject claim format (owner_id/repo_id, not repo name) — see `~/src/melvyndekort/tf-aws/BOOTSTRAP.md` → "GitHub OIDC subject format" before debugging any OIDC assume-role failure. Subjects are pinned to the `production` GitHub **Environment** (`:environment:production`), not to a branch ref -- there is no `:ref:refs/heads/main` fallback.
- The read-only PR-plan-role feature has one name everywhere in this repo: `aws_plan_role` (yaml key, `oidc_role` module variables/output). See README.md#naming.

## Repository Structure

- `terraform/repos/*.yaml` — Source of truth for all GitHub repos, one file per repo (`_defaults.yaml` holds the profile layer, not a repo)
- `terraform/repositories.tf` — Repo creation, secrets, and OIDC role ARN assignment
- `terraform/github-oidc-roles.tf` — Per-account OIDC role provisioning
- `terraform/oidc_role/` — Module: creates `github-actions-<repo>` IAM roles via OIDC
- `terraform/repo/` — Module: repo configuration (public and private; `type: custom` repos bypass this module, see README.md#custom-repos)
- `terraform/secrets.tf` — KMS-encrypted secrets handling
- `terraform/repos.schema.json` / `validate_repos_schema.py` — CI schema gate on `repos/*.yaml`
- `Makefile` — `decrypt`, `encrypt`, `clean_secrets`

## Adding a New Subaccount

When a new AWS subaccount is bootstrapped in tf-aws:
1. Add a new `provider "aws"` block in `github-oidc-roles.tf` assuming into `github-actions-tf-github` in the new account
2. Add a new `module "oidc_roles_<id>"` instance
3. Merge the new module's output into `all_role_arns`
4. Add workload repos to `repos/<name>.yaml` with `aws_account: "<id>"`

## Terraform Details

- Backend: S3 key in `mdekort-tfstate-075673041815`
- Secrets: KMS context `target=tf-github`

## Related Repositories

- `~/src/melvyndekort/tf-aws` — AWS account creation and bootstrap (phases 1-2)
- `~/src/melvyndekort/tf-cloudflare` — Provides API tokens via remote state
- `~/src/melvyndekort/network-monitor` — Example workload repo using the subaccount pattern
