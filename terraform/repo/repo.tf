# Unified repo module - merges the former modules/public_repo and
# modules/private_repo into one (tf-github-redesign-plan-2026-10.md §8
# Phase 2 task 2, §6.2). Resource-shape changes relative to the two
# predecessor modules are called out with `moved` blocks below so every
# existing repo's state maps onto the same real-world resource instead of
# a destroy+recreate; see the module-call site (repositories.tf) for the
# matching module.public_repos/module.private_repos -> module.repo moved
# blocks that carry the per-repo state across the module merge itself.

resource "github_repository" "repo" {
  name        = var.name
  description = var.description

  visibility = var.visibility

  has_issues   = true
  has_projects = false
  has_wiki     = false

  auto_init              = true
  allow_auto_merge       = var.visibility == "public" ? true : false
  delete_branch_on_merge = true
  archive_on_destroy     = true
  allow_forking          = var.allow_forking
  archived               = var.archived

  allow_update_branch = true
}

# Shape change only for repos that came from modules/public_repo: that
# module created this with no count (a plain singleton), while
# modules/private_repo already used `count = var.archived ? 0 : 1`. Unifying
# on the private shape (needed to support archived public repos too) moves
# every already-public repo's instance from the bare address to [0].
moved {
  from = github_repository_vulnerability_alerts.repo
  to   = github_repository_vulnerability_alerts.repo[0]
}

resource "github_repository_vulnerability_alerts" "repo" {
  count = var.archived ? 0 : 1

  repository = github_repository.repo.name
  enabled    = true
}

resource "github_actions_repository_permissions" "repo" {
  repository = github_repository.repo.name

  allowed_actions = "selected"

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
    patterns_allowed     = var.allowed_actions_config
  }
}

# Lets the dependabot auto-approve workflow approve PRs; without it the
# review required by branch protection never arrives and auto-merge stalls.
#
# Same shape change as github_repository_vulnerability_alerts.repo above,
# same reason.
moved {
  from = github_workflow_repository_permissions.repo
  to   = github_workflow_repository_permissions.repo[0]
}

resource "github_workflow_repository_permissions" "repo" {
  count = var.archived ? 0 : 1

  repository = github_repository.repo.name

  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = true
}

resource "time_sleep" "vulnerability_alerts_propagation" {
  create_duration = "30s"

  triggers = {
    repository_id = github_repository.repo.id
  }
}

# Same shape change as github_repository_vulnerability_alerts.repo above,
# same reason. depends_on carries both predecessor modules' dependency
# edges (modules/private_repo additionally waited on the vulnerability
# alerts resource; modules/public_repo did not) - depends_on is not a
# tracked attribute, so taking the union changes nothing in state.
moved {
  from = github_repository_dependabot_security_updates.repo
  to   = github_repository_dependabot_security_updates.repo[0]
}

resource "github_repository_dependabot_security_updates" "repo" {
  count = var.archived ? 0 : 1

  repository = github_repository.repo.id
  enabled    = true

  depends_on = [time_sleep.vulnerability_alerts_propagation, github_repository_vulnerability_alerts.repo]
}

resource "github_issue_label" "requires-manual-qa" {
  repository = github_repository.repo.id
  name       = "requires-manual-qa"
  color      = "ffa500"
}

data "github_branch" "main" {
  repository = github_repository.repo.name
  branch     = "main"
}

# Only modules/public_repo ever created this (as a plain singleton);
# modules/private_repo had no branch_protection resource at all - no
# private repo today has one live. Preserving that exactly: gated on
# visibility instead of unconditional, so private repos still get none.
moved {
  from = github_branch_protection.main
  to   = github_branch_protection.main[0]
}

resource "github_branch_protection" "main" {
  count = var.visibility == "public" ? 1 : 0

  repository_id = github_repository.repo.name

  pattern = data.github_branch.main.branch

  require_conversation_resolution = true
  require_signed_commits          = true
  allows_deletions                = false

  # `require_pull_request` (default true) gates both of the blocks below.
  # Set to false per-repo (require_pull_request: false in repositories.yaml)
  # to let main accept direct pushes with no PR and no required status
  # checks, for the duration of a declared migration window only - see the
  # comment next to the repo's repos/<name>.yaml entry for the owning task
  # and the rollback task that must flip it back to true.
  dynamic "required_status_checks" {
    for_each = var.require_pull_request ? [1] : []
    content {
      strict   = false
      contexts = var.required_status_checks
    }
  }

  dynamic "required_pull_request_reviews" {
    for_each = var.require_pull_request ? [1] : []
    content {
      dismiss_stale_reviews           = true
      require_last_push_approval      = true
      required_approving_review_count = var.required_review_count
    }
  }

  force_push_bypassers = var.force_push_bypassers
}

resource "github_branch_default" "main" {
  repository = github_repository.repo.name
  branch     = data.github_branch.main.branch
}

resource "github_repository_deploy_key" "keys" {
  for_each = { for key in var.deploy_keys : key.title => key }

  repository = github_repository.repo.name
  title      = each.value.title
  key        = each.value.key
  read_only  = each.value.read_only
}
