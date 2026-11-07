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

resource "github_actions_variable" "aws_region" {
  repository    = github_repository.this.name
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

resource "github_actions_variable" "opentofu_version" {
  repository    = github_repository.this.name
  variable_name = "TF_VERSION"
  value         = var.opentofu_version
}

resource "github_actions_repository_permissions" "this" {
  repository      = github_repository.this.name
  allowed_actions = "selected"
  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
    patterns_allowed     = ["opentofu/setup-opentofu@*"]
  }
  sha_pinning_required = true
}

resource "github_workflow_repository_permissions" "this" {
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
  repository                       = github_repository.this.name
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
