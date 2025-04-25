resource "aws_iam_role_policy_attachment" "detach_example" {
  role       = var.role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"

  lifecycle {
    prevent_destroy = false # Allows Terraform to delete
  }
}
