resource "github_repository" "melvyndekort_github_io" {
  name        = "melvyndekort.github.io"
  description = "My personal blog"

  visibility = "public"

  has_downloads = false
  has_issues    = false
  has_projects  = false
  has_wiki      = false

  auto_init              = true
  allow_auto_merge       = true
  delete_branch_on_merge = true
  vulnerability_alerts   = true
  archive_on_destroy     = true

  pages {
    source {
      branch = "gh-pages"
    }
  }
}

data "github_branch" "melvyndekort_github_io_gh_pages" {
  repository = github_repository.melvyndekort_github_io.name
  branch     = "gh-pages"
}

resource "github_branch_default" "melvyndekort_github_io" {
  repository = github_repository.melvyndekort_github_io.name
  branch     = data.github_branch.melvyndekort_github_io_gh_pages.branch
}
