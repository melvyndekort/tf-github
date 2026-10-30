# tf-github

Terraform that manages every GitHub repository under the `melvyndekort` GitHub
organization as config-as-code: repo settings, branch protection, secrets,
collaborators, environments, and each repo's GitHub↔AWS OIDC federation.

tf-github is "phase 3" of a three-repo bootstrap chain — see
[`tf-aws/BOOTSTRAP.md`](https://github.com/melvyndekort/tf-aws/blob/main/BOOTSTRAP.md)
for the account-creation and OIDC-provider phases this repo builds on.

## Project structure

```
.
├── terraform/
│   ├── main.tf                    # github_user data sources, docker/cloudflare locals
│   ├── providers.tf                # backend (S3), github + aws providers
│   ├── remote-state.tf              # terraform_remote_state: tf_cloudflare, tf_aws
│   ├── secrets.tf                   # data.aws_kms_secrets (KMS-encrypted local secrets)
│   ├── secrets.yaml.encrypted        # KMS ciphertext (not committed in plaintext)
│   ├── global.yaml                   # global_collaborators list, added to every repo
│   ├── repositories.tf               # repo creation, secrets, collaborators, environments
│   ├── github-oidc-roles.tf          # per-AWS-account provider + oidc_role module wiring
│   ├── repos.schema.json             # JSON Schema for every repos/*.yaml file
│   ├── repos_defaults.schema.json    # JSON Schema for repos/_defaults.yaml
│   ├── validate_repos_schema.py      # CI check: repos/*.yaml against the schemas above
│   ├── repos/                        # config-as-code source of truth, one file per repo
│   │   ├── _defaults.yaml            # named profiles (see "Defaults / profile layer")
│   │   └── <repo>.yaml               # one file per GitHub repo (33+ today)
│   ├── repo/                         # module: github_repository + branch protection + Actions perms
│   └── oidc_role/                    # module: per-account IAM role(s) via OIDC, + opt-in plan role
├── .github/workflows/
│   ├── terraform-pr.yml              # validate + schema-validate + plan-leak-audit + plan
│   ├── terraform-apply.yml           # thin caller: apply via gha-workflows, environment-gated
│   └── dependabot.yml                # auto-approve/merge + workflow_dispatch trigger-deploy
├── Makefile                          # decrypt/encrypt/clean_secrets (AWS KMS), fmt/init/plan/apply
├── CLAUDE.md                         # AI-agent operating notes
└── README.md                         # this file
```

There is no `repositories.yaml` and no `public_repo`/`private_repo` modules —
those existed before the 2026-10 config-as-code redesign (#41/#42) and were
replaced by `repos/*.yaml` + the single `repo` module. If you find either
name mentioned anywhere else (an old doc, a stale comment), it's wrong; this
file is the structural source of truth.

## Config-as-code: `repos/*.yaml`

Every repository under `melvyndekort` is one file, `terraform/repos/<name>.yaml`,
decoded by `repositories.tf` and validated in CI against `repos.schema.json`
(every legal key, its type, and a short description live there — read it
instead of relying on this README to stay exhaustively in sync). A misspelled
key fails the `schema-validate` CI job instead of silently defaulting away
through the `try(each.value.foo, default)` pattern used throughout the
Terraform.

Minimal example (most keys are optional, defaults come from `repo`/`oidc_role`
variable defaults or the profile layer below):

```yaml
visibility: public
description: "What this repo is for"
aws_account: "123456789012"   # presence creates a github-actions-<repo> OIDC role
profile: terraform-workload   # see below
```

### Defaults / profile layer

`terraform/repos/_defaults.yaml` holds named profiles — reusable bundles of
keys a repo can opt into with `profile: <name>` instead of repeating them.
Today there is one profile, matching the shape most AWS-connected repos share:

```yaml
profiles:
  terraform-workload:
    shared_workflows: true
    aws_plan_role: true
    required_status_checks:
      - "validate / validate"
```

A repo's own keys always win over its profile's (shallow merge per key — a
repo that sets `required_status_checks` replaces the whole list, it does not
append to the profile's list). `_defaults.yaml` is not itself a repo; it's
excluded from the `repos/*.yaml` glob and validated separately against
`repos_defaults.schema.json`.

Add a new profile when a repeated shape emerges across several repos; keep
`repos.schema.json`'s `profile` enum in sync with the profile names defined
here (the CI schema check and `validate_repos_schema.py` both cross-check
that every `profile:` value used by a repo actually exists in
`_defaults.yaml`).

### `type: custom` — the GitHub Pages escape hatch {#custom-repos}

`melvyndekort.github.io` is the one repo with `type: custom`. It is hand-rolled
directly in `repositories.tf` (`github_repository.custom_repos` and friends)
instead of going through the `repo` module, because it needs GitHub Pages
(`pages:` / `default_branch:`), which the `repo` module does not support.

This is a deliberate, permanent escape hatch, not forgotten technical debt: a
single repo needing Pages did not justify adding a Pages option to the `repo`
module used by the other 32. If a second repo ever needs Pages, that's the
trigger to add an optional `pages` variable to `repo` and migrate both onto it
with `moved` blocks — see the comment above `github_repository.custom_repos`
in `repositories.tf`.

## Naming {#naming}

The read-only PR-plan-role feature has one canonical name everywhere in this
repo: **`aws_plan_role`** — the `repos/<name>.yaml` key, the `oidc_role`
module's `aws_plan_role_repos`/`aws_plan_role_kms_targets`/etc. variables, and
its `aws_plan_role_arns` output all use it. The top-level outputs in
`github-oidc-roles.tf` (`github_actions_role_arns` /
`github_actions_plan_role_arns`) are the one intentional exception: they
share the `github_actions_*` prefix as their own small, consistent naming
pair, documented inline where they're defined.

If you see `pr_plan_role` or `repositories.yaml` anywhere (an old doc, an
external repo, a stale comment), it refers to the same `aws_plan_role`
concept / `repos/*.yaml` file and should be corrected to match when you touch
that text.

## CI/CD pipeline

Real pipeline logic lives in the separate [`gha-workflows`](https://github.com/melvyndekort/gha-workflows)
repo, consumed as reusable (`workflow_call`) workflows pinned to a tag
(`@v1`), not `@main`.

`terraform-pr.yml` (on every PR to `main`) runs four jobs:

| Job | What | Credentials |
|---|---|---|
| `validate` | `fmt -check`, `init -backend=false`, `validate` (shared `terraform-pr-validate.yml`) | none |
| `schema-validate` | `repos/*.yaml` against `repos.schema.json` (local job, this repo only) | none |
| `plan-leak-audit` | `gha-workflows/tools/audit_plan_leaks.py` against this repo's `.tf` (local job, this repo only) | none |
| `plan` | `terraform plan`, posted as a PR comment (shared `terraform-pr-plan.yml`) | read-only plan role (OIDC) |

`schema-validate` and `plan-leak-audit` are specific to this repo's own
config-as-code surface, so they're plain jobs in `terraform-pr.yml` rather
than additions to the shared `terraform-pr-validate.yml` (which runs,
unmodified, for every other repo too). Both are required status checks on
`main` (see `repos/tf-github.yaml`).

`plan-leak-audit` extracts provider schemas via `terraform providers schema
-json`, which needs an initialized backend even though it touches no state —
the job overrides the real S3 backend with a throwaway local one for that
step only, so it stays credential-free (no AWS calls at all).

`terraform-apply.yml` (on push to `main`) applies via the shared
`terraform-apply.yml`, gated by the `production` GitHub Environment with a
deployment-branch policy restricting it to `main`.

## Usage

### Prerequisites

- Terraform `~> 1.10`
- AWS CLI, authenticated via `awsume` for local plan/apply (CI uses OIDC —
  see the table above; local `apply` is off-limits per standing convention,
  applies happen in CI only)
- `gh` CLI, for opening PRs

### Adding a new repository

1. Add `terraform/repos/<name>.yaml` (see "Config-as-code" above; use
   `profile: terraform-workload` if it needs the standard
   shared-workflows/plan-role/status-checks shape).
2. To grant AWS access, set `aws_account: "<12-digit id>"` — the account must
   already be bootstrapped by `tf-aws` (see its `BOOTSTRAP.md`).
3. Open a PR. `schema-validate` catches a malformed file immediately;
   `plan` (if the repo has an `aws_account`) shows the new OIDC role.
4. Merge to apply (gated by the `production` environment, OIDC apply role).

Adding a new AWS account additionally requires a new `provider "aws"` block
and `module "oidc_roles_<id>"` instance in `github-oidc-roles.tf` — a
Terraform limitation (provider blocks cannot be dynamic/`for_each`'d). See
`CLAUDE.md`.

### Managing secrets

Secrets are stored encrypted in `terraform/secrets.yaml.encrypted` and
decrypted using AWS KMS (`target=tf-github` encryption context):

```bash
make decrypt   # -> terraform/secrets.yaml (gitignored)
make encrypt   # terraform/secrets.yaml -> terraform/secrets.yaml.encrypted
make clean_secrets
```

### Local plan (read-only)

```bash
assume   # or your preferred AWS authentication method
make plan
```

`make apply` exists for emergency/manual use but the normal path is CI: merge
to `main` after a clean PR plan.

### GitHub Actions PR-approval workaround

The Terraform GitHub provider cannot enable "Allow GitHub Actions to create
and approve pull requests," which dependabot auto-approval needs. It's set
directly via the API instead:

```bash
for repo in $(gh repo list melvyndekort --limit 1000 --json name -q '.[].name'); do
  if gh api repos/melvyndekort/$repo/contents/.github/workflows &>/dev/null; then
    gh api --method PUT repos/melvyndekort/$repo/actions/permissions/workflow \
      --field default_workflow_permissions=read \
      --field can_approve_pull_request_reviews=true
  fi
done
```

## Remote state

Terraform state is stored in S3 (`mdekort-tfstate-075673041815`, `eu-west-1`).
This repo reads `tf_cloudflare` (secret values) and `tf_aws` (the generic KMS
key ARN) via `terraform_remote_state`.

## Security

- Secrets are encrypted at rest with AWS KMS; nothing sensitive is committed
  in plaintext (`.gitignore` excludes `secrets.yaml`, `*.tfstate*`,
  `.terraform/`).
- Every `aws_account` repo's apply role carries `AdministratorAccess` in its
  target account (accepted tradeoff, see the tf-github improvement plan in
  the planning vault for the rationale and considered alternatives).
- Private repos get no server-side branch protection (GitHub Free plan
  limitation); `plan-leak-audit` and scoped bot push access are the
  compensating, CI-only controls.
- See `SECURITY.md` for vulnerability reporting.
