# GitHub Repository Management with Terraform

This project uses Terraform to manage GitHub repositories, secrets, and configurations for the `melvyndekort` GitHub organization.

## Overview

The infrastructure is defined using Terraform and manages:
- Public and private GitHub repositories
- Repository secrets and configurations
- GitHub Actions settings
- Repository permissions and settings

## Prerequisites

- Terraform ~> 1.6.0
- AWS CLI configured with appropriate permissions
- GitHub token with repository management permissions
- Access to AWS KMS for secret decryption

## Project Structure

```
.
├── terraform/
│   ├── main.tf              # Main configuration and locals
│   ├── providers.tf         # Provider configurations
│   ├── repositories.tf      # Repository resource definitions
│   ├── repositories.yaml    # Repository configuration data
│   ├── secrets.tf          # Secret management
│   ├── secrets.yaml.encrypted # Encrypted secrets file
│   ├── remote-state.tf     # Remote state configuration
│   ├── public_repo/        # Public repository modules
│   └── private_repo/       # Private repository modules
├── bootstrap/              # Bootstrap scripts
├── Makefile               # Automation commands
└── README.md              # This file
```

## Usage

### Initial Setup

1. Ensure you're authenticated with AWS:
   ```bash
   assume  # or your preferred AWS authentication method
   ```

2. Decrypt secrets:
   ```bash
   make decrypt
   ```

3. Initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

### Managing Repositories

Repository configurations are defined in `terraform/repositories.yaml`. Each repository can be configured with:
- Type (public/private/custom)
- Description
- Secrets
- GitHub Actions settings
- Branch protection rules

### Common Operations

**Plan changes:**
```bash
cd terraform
terraform plan
```

**Apply changes:**
```bash
cd terraform
terraform apply
```

**Decrypt secrets:**
```bash
make decrypt
```

**Encrypt secrets:**
```bash
make encrypt
```

**Clean up decrypted secrets:**
```bash
make clean_secrets
```

## Configuration

### Adding a New Repository

1. Add the repository configuration to `terraform/repositories.yaml`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to create the repository

### Managing Secrets

Secrets are stored encrypted in `terraform/secrets.yaml.encrypted` and decrypted using AWS KMS. The decrypted file is automatically excluded from version control.

### GitHub Actions PR Approval Workaround

**Issue**: The Terraform GitHub provider doesn't support enabling "Allow GitHub Actions to create and approve pull requests" setting, which is required for dependabot auto-approval workflows.

**Solution**: Use the GitHub API directly to enable this setting for all repositories:

```bash
# Enable for all repositories with workflows
for repo in $(gh repo list melvyndekort --limit 1000 --json name -q '.[].name'); do
  if gh api repos/melvyndekort/$repo/contents/.github/workflows &>/dev/null; then
    echo "Enabling PR approval for $repo"
    gh api --method PUT repos/melvyndekort/$repo/actions/permissions/workflow \
      --field default_workflow_permissions=read \
      --field can_approve_pull_request_reviews=true
  fi
done
```

**API Endpoint**: `PUT /repos/{owner}/{repo}/actions/permissions/workflow`
- `can_approve_pull_request_reviews: true` - Allows GitHub Actions to approve PRs
- `default_workflow_permissions: read` - Sets default workflow permissions

This setting is required for dependabot workflows to automatically approve and merge GitHub Actions updates.

## Remote State

Terraform state is stored remotely in an S3 bucket (`mdekort.tfstate`) in the `eu-west-1` region.

## Security

- Secrets are encrypted at rest using AWS KMS
- GitHub tokens and sensitive data are never stored in plain text in the repository
- All secret files are excluded from version control via `.gitignore`
