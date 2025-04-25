# This file contains the provisioners for the IAM role and policy attachments.
resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"

  provisioner "local-exec" {
    when    = destroy
    command = "aws iam detach-role-policy --role-name ${self.role} --policy-arn ${self.policy_arn}"
  }
}
