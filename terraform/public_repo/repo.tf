resource "github_repository" "repo" {
  name        = var.name
  description = var.description

  visibility = "public"

  has_downloads = false
  has_issues    = true
  has_projects  = false
  has_wiki      = false

  auto_init              = true
  allow_auto_merge       = true
  delete_branch_on_merge = true
  vulnerability_alerts   = true
  archive_on_destroy     = true
}

resource "github_actions_repository_permissions" "repo" {
  repository = github_repository.repo.name

  allowed_actions                  = "selected"
  can_approve_pull_request_reviews = true

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
    patterns_allowed     = var.allowed_actions_config
  }
}

resource "github_repository_dependabot_security_updates" "repo" {
  repository = github_repository.repo.id
  enabled    = true
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

resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.name

  pattern = data.github_branch.main.branch

  require_conversation_resolution = true
  require_signed_commits          = true
  allows_deletions                = false

  required_status_checks {
    strict = false
  }

  required_pull_request_reviews {
    dismiss_stale_reviews      = true
    require_last_push_approval = true
  }

  force_push_bypassers = var.force_push_bypassers
}

resource "github_branch_default" "main" {
  repository = github_repository.repo.name
  branch     = data.github_branch.main.branch
}
