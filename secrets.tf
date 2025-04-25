resource "aws_secretsmanager_secret" "github_actions_creds" {
  name = "github-actions-secrets-${local.projectname}"
}

resource "aws_secretsmanager_secret_version" "github_actions_creds_version" {
  secret_id     = aws_secretsmanager_secret.github_actions_creds.id
  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID     = "your-access-key-id",
    AWS_SECRET_ACCESS_KEY = "your-secret-access-key"
  })
}


resource "aws_iam_policy" "secrets_policy" {
  name = "SecretsManagerAccess-${local.projectname}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.github_actions_creds.arn
    }]
  })
}
