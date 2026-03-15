# Session Instructions

## Your Role

You're an experienced Cloud Engineer specializing in AWS and Terraform, helping manage GitHub repository configuration and OIDC role provisioning across an AWS Organization.

## Key Principles

1. **UNDERSTAND THE BOOTSTRAP CHAIN** - This repo is phase 3 of a three-phase chain:
   - Phase 1-2 (tf-aws): Creates AWS accounts, OIDC providers, and the `github-actions-tf-github` role
   - Phase 3 (this repo): Creates per-repo OIDC roles in the correct AWS account and sets `AWS_ROLE_ARN` secrets
   - See `~/src/melvyndekort/tf-aws/BOOTSTRAP.md` for the full architecture
2. **Repos are defined in YAML** - `terraform/repositories.yaml` is the source of truth for all repos, their types, secrets, and AWS account assignments.
3. **OIDC roles are per-account** - Each AWS account needs a provider block and module instance in `terraform/github-oidc-roles.tf`. This is a Terraform limitation (providers can't be dynamic).
4. **No long-lived credentials** - All CI/CD uses OIDC. Never introduce static access keys.
5. **Be critical and honest** - Challenge ideas if they have issues.

## Repository Structure

- `terraform/repositories.yaml` - Source of truth for all GitHub repos
- `terraform/repositories.tf` - Repo creation, secrets, and OIDC role ARN assignment
- `terraform/github-oidc-roles.tf` - Per-account OIDC role provisioning
- `terraform/oidc_role/` - Module: creates `github-actions-<repo>` IAM roles via OIDC
- `terraform/public_repo/` - Module: public repo configuration
- `terraform/private_repo/` - Module: private repo configuration
- `terraform/secrets.tf` - SOPS-encrypted secrets handling

## Adding a New Subaccount

When a new AWS subaccount is bootstrapped in tf-aws, this repo needs:
1. A new `provider "aws"` block in `github-oidc-roles.tf` assuming into `github-actions-tf-github` in the new account
2. A new `module "oidc_roles_<id>"` instance
3. The new module's output merged into `all_role_arns`
4. Workload repos added to `repositories.yaml` with `aws_account: "<id>"`

## Related Repositories

- `~/src/melvyndekort/tf-aws` - AWS account creation and bootstrap (phases 1-2)
- `~/src/melvyndekort/tf-aws/BOOTSTRAP.md` - Full bootstrap architecture documentation
- `~/src/melvyndekort/tf-cloudflare` - Cloudflare config (provides API tokens via remote state)
