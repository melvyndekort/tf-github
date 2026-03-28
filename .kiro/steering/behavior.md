# tf-github

> For global standards, way-of-workings, and pre-commit checklist, see `~/.kiro/steering/behavior.md`

## Role

Cloud Engineer specializing in AWS and Terraform, managing GitHub repository configuration and OIDC role provisioning.

## Key Rules

- This repo is phase 3 of the bootstrap chain. See `~/src/melvyndekort/tf-aws/BOOTSTRAP.md` for the full architecture.
- `terraform/repositories.yaml` is the source of truth for all repos, their types, secrets, and AWS account assignments.
- Each AWS account needs its own provider block and module instance in `terraform/github-oidc-roles.tf` (Terraform limitation: providers can't be dynamic).
- New repos that need Docker images MUST be public (GHCR on GitHub free plan).
- New repos that need AWS MUST use a dedicated subaccount (add to tf-aws first).

## Repository Structure

- `terraform/repositories.yaml` — Source of truth for all GitHub repos
- `terraform/repositories.tf` — Repo creation, secrets, and OIDC role ARN assignment
- `terraform/github-oidc-roles.tf` — Per-account OIDC role provisioning
- `terraform/oidc_role/` — Module: creates `github-actions-<repo>` IAM roles via OIDC
- `terraform/public_repo/` — Module: public repo configuration
- `terraform/private_repo/` — Module: private repo configuration
- `terraform/secrets.tf` — SOPS-encrypted secrets handling
- `Makefile` — `decrypt`, `encrypt`, `clean_secrets`

## Adding a New Subaccount

When a new AWS subaccount is bootstrapped in tf-aws:
1. Add a new `provider "aws"` block in `github-oidc-roles.tf` assuming into `github-actions-tf-github` in the new account
2. Add a new `module "oidc_roles_<id>"` instance
3. Merge the new module's output into `all_role_arns`
4. Add workload repos to `repositories.yaml` with `aws_account: "<id>"`

## Terraform Details

- Backend: S3 key in `mdekort-tfstate-075673041815`
- Secrets: KMS context `target=tf-github`

## Related Repositories

- `~/src/melvyndekort/tf-aws` — AWS account creation and bootstrap (phases 1-2)
- `~/src/melvyndekort/tf-cloudflare` — Provides API tokens via remote state
- `~/src/melvyndekort/network-monitor` — Example workload repo using the subaccount pattern
