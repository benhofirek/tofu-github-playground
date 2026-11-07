output "github_repository_url" {
  value = github_repository.this.html_url
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_state.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
