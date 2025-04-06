provider "aws" {
  region = "us-east-1" # Change to your desired region
}
locals {
  project_name = "tf-workflows"
  github_actions_role_arn = "arn:aws:iam::255945442255:role/github-actions-role"
}

# Part 1: Create S3 Bucket
resource "aws_s3_bucket" "static_bucket" {
  bucket        = "rgers3.${local.project_name}" # Replace with your desired bucket name
  force_destroy = true # Allows the bucket to be destroyed even if it contains objects
}

# Controls Restrictions for the Bucket
resource "aws_s3_bucket_public_access_block" "controls_restrictions" {
  bucket = aws_s3_bucket.static_bucket.bucket

  block_public_acls       = false #Allow public ACLs
  ignore_public_acls      = false #Respect public ACLs
  block_public_policy     = false #Allow public bucket policies
  restrict_public_buckets = false #Don't restrict public buckets
}

# Part 2: Enable Static Website Hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}


# Part 3: Bucket Policy to Allow Public Access
resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.static_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_bucket.arn}/*" #arn:aws:s3:::rgers3.sctp-sandbox.com/*
      }
    ]
  })
}


# backend # check this created before calling
terraform {
  backend "s3" {
    bucket = "rgers3.tfstate-backend.com"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locks"  # Critical for locking
  }
}



# DynamoDB permissions ---added
resource "aws_iam_policy" "terraform_lock_policy" {
  name        = "TerraformLockTableAccess${local.project_name}"
  description = "Permissions for Terraform state locking"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/terraform-state-locks"
      }
    ]
  })
}


# OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]  # This is the audience we'll use
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]  # GitHub's OIDC thumbprint2024
}

# Create IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-role" # unique per project
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect: "Allow" 
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn # References existing provider
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:keengwatanabe/m3.1-tf-workflows:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Start broad, then restrict
}

  
# # 2. Policy attachements (repeatable)
resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = aws_iam_role.github_actions.name  
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" # aws_iam_policy.terraform_lock_policy.arn
}

# Outputs to look for creations in aws
output "s3_bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "github_role_arn" {
  value = aws_iam_role.github_actions.arn 
}
output "aws_iam_policy" {
  value = aws_iam_policy.terraform_lock_policy.id
}
# Use the local value elsewhere (e.g., outputs)
output "role_arn" {
  value = local.github_actions_role_arn
}


output "aws_iam_role" {
  value = aws_iam_role.github_actions.id
}