data "github_user" "current" {
  username = var.owner
}

data "aws_caller_identity" "current" {}

locals {
  github_oidc_subject_main = format(
    "repo:%s@%s/%s@%s:ref:refs/heads/main",
    data.github_user.current.login,
    data.github_user.current.id,
    github_repository.this.name,
    github_repository.this.repo_id
  )

  github_oidc_subject_pr = format(
    "repo:%s@%s/%s@%s:pull_request",
    data.github_user.current.login,
    data.github_user.current.id,
    github_repository.this.name,
    github_repository.this.repo_id
  )
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# --------------------------------------------------
# Main branch trust policy
# --------------------------------------------------

data "aws_iam_policy_document" "github_assume_role_main" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_subject_main]
    }
  }
}

resource "aws_iam_role" "github_actions_main" {
  name               = "github-actions-tofu-main"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role_main.json
}

resource "github_actions_secret" "aws_role_arn_main" {
  repository  = github_repository.this.name
  secret_name = "AWS_ROLE_ARN_MAIN"
  value       = aws_iam_role.github_actions_main.arn
}

# --------------------------------------------------
# Pull request trust policy
# --------------------------------------------------

data "aws_iam_policy_document" "github_assume_role_pr" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_subject_pr]
    }
  }
}

resource "aws_iam_role" "github_actions_pr" {
  name               = "github-actions-tofu-pr"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role_pr.json
}

resource "github_actions_secret" "aws_role_arn_pr" {
  repository  = github_repository.this.name
  secret_name = "AWS_ROLE_ARN_PR"
  value       = aws_iam_role.github_actions_pr.arn
}

# --------------------------------------------------
# S3 backend permissions
# --------------------------------------------------

data "aws_iam_policy_document" "main_state_access" {
  statement {
    sid = "ReadAndInspectStateBucketConfiguration"

    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:Get*"
    ]

    resources = [
      aws_s3_bucket.terraform_state.arn
    ]
  }

  statement {
    sid = "ManageStateAndLock"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.terraform_state.arn}/${local.state_key}",
      "${aws_s3_bucket.terraform_state.arn}/${local.state_key}.tflock"
    ]
  }

  statement {
    sid = "ReadIamConfiguration"

    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:GetPolicy",
      "iam:GetPolicyVersion"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-tofu-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
    ]
  }

  statement {
    sid = "ReadGitHubOidcProvider"

    effect = "Allow"

    actions = [
      "iam:GetOpenIDConnectProvider"
    ]

    resources = [
      aws_iam_openid_connect_provider.github.arn
    ]
  }
}

resource "aws_iam_role_policy" "main_state_access" {
  name   = "github-actions-tofu-state-access"
  role   = aws_iam_role.github_actions_main.id
  policy = data.aws_iam_policy_document.main_state_access.json
}

# --------------------------------------------------
# Pull request state-only permissions
# --------------------------------------------------

data "aws_iam_policy_document" "pr_state_access" {

  # Only allow listing the Terraform state and lock file.
  statement {
    sid    = "ListTerraformState"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.terraform_state.arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        var.state_bucket_key_prefix,
        "${var.state_bucket_key_prefix}/*"
      ]
    }
  }

  # Read-only access to the actual Terraform state.
  statement {
    sid    = "ReadTerraformState"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.terraform_state.arn}/${local.state_key}"
    ]
  }

  # Terraform needs to manage its lock file, even during plan.
  statement {
    sid    = "ManageTerraformStateLock"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.terraform_state.arn}/${local.state_key}.tflock"
    ]
  }
}

resource "aws_iam_role_policy" "pr_state_access" {
  name   = "github-actions-tofu-pr-state-access"
  role   = aws_iam_role.github_actions_pr.id
  policy = data.aws_iam_policy_document.pr_state_access.json
}

