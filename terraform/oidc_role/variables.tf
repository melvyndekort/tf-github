variable "github_org" {
  type = string
}

variable "github_owner_id" {
  type = number
}

variable "repos" {
  description = "Map of repo name to its numeric GitHub repo_id"
  type        = map(number)
}

variable "plan_repos" {
  description = <<-EOT
    Map of repo name to its numeric GitHub repo_id for repos that get an
    additional read-only role for PR plans. Opt-in: a repo only appears here
    when it sets `pr_plan_role: true` in repositories.yaml.
  EOT
  type        = map(number)
  default     = {}
}

variable "plan_job_workflow_refs" {
  description = <<-EOT
    Allowed `job_workflow_ref` claim values for the PR plan role, as the
    reusable workflow path plus ref (e.g.
    "melvyndekort/gha-workflows/.github/workflows/terraform-pr-plan.yml@refs/tags/v1").
    Only a job that IS the named reusable workflow presents a matching claim,
    so code authored inside a pull request can never hold these credentials
    even though the caller repository and event match the subject condition.
  EOT
  type        = list(string)
  default     = []
}

variable "plan_kms_key_arns" {
  description = <<-EOT
    Map of repo name to the KMS key ARN its plan must decrypt, for repos whose
    Terraform calls `data.aws_kms_secrets` at plan time. Opt-in: a repo only
    appears here when it sets `pr_plan_kms_decrypt: true` in repositories.yaml.

    Needed because the AWS-managed ReadOnlyAccess policy grants only
    kms:Describe*/Get*/List*, not kms:Decrypt. Granting it in the plan role's
    identity policy is enough for keys in the same account, because the key
    policy already delegates to the account root.
  EOT
  type        = map(string)
  default     = {}
}
