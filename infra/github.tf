resource "github_repository" "this" {
  name        = "tofu-github-playground"
  description = "Experimental showcase of provisioning Github repository with OpenTofu"

  visibility = "public"
  has_issues = true
  auto_init  = true

  topics = [
    "terraform",
    "opentofu",
    "infrastructure",
    "automation"
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch" "main" {
  repository = github_repository.this.name
  branch     = "main"

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch" "development" {
  repository = github_repository.this.name
  branch     = "development"

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_default" "default" {
  repository = github_repository.this.name
  branch     = github_branch.main.branch
}

resource "github_branch_protection" "development" {
  repository_id = github_repository.this.node_id

  pattern          = "development"
  allows_deletions = false
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.this.node_id

  pattern                 = "main"
  allows_deletions        = false
  required_linear_history = true
  allows_force_pushes      = false

  required_pull_request_reviews {
    dismiss_stale_reviews = true
  }
}
