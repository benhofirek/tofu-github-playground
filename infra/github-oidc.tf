data "github_user" "current" {
  username = var.owner
}

# 3. Construct the immutable subject claim dynamically using locals
locals {
  github_oidc_subjects = [
    format(
      "repo:%s@%s/%s@%s:ref:refs/heads/main",
      data.github_user.current.login,
      data.github_user.current.id,
      github_repository.this.name,
      github_repository.this.repo_id
    )
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

# --------------------------------------------------
# IAM role trust policy
# --------------------------------------------------

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = local.github_oidc_subjects
    }
  }
}

resource "aws_iam_role" "github_actions_state" {
  name               = "github-actions-tofu-state"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

# --------------------------------------------------
# S3 backend permissions
# --------------------------------------------------

data "aws_iam_policy_document" "state_access" {
  statement {
    sid = "ListStateBucket"

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
}

resource "aws_iam_role_policy" "state_access" {
  name   = "github-actions-tofu-state-access"
  role   = aws_iam_role.github_actions_state.id
  policy = data.aws_iam_policy_document.state_access.json
}
