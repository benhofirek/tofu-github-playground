resource "github_repository" "this" {
  name        = var.repository_name
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

resource "github_repository_ruleset" "development" {
  name        = "development-protection"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/development"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }
}

resource "github_repository_ruleset" "main" {
  name        = "main-protection"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true
  }
}
