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

## Remote State

Terraform state is stored remotely in an S3 bucket (`mdekort.tfstate`) in the `eu-west-1` region.

## Security

- Secrets are encrypted at rest using AWS KMS
- GitHub tokens and sensitive data are never stored in plain text in the repository
- All secret files are excluded from version control via `.gitignore`
