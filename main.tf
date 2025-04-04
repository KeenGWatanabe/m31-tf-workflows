provider "aws" {
  region = "us-east-1" # Change to your desired region
}
locals {
  project_name = "tf-workflows"
}

# Part 1: Create S3 Bucket
resource "aws_s3_bucket" "static_bucket" {
  bucket        = "rgers3.${local.project_name}" # Replace with your desired bucket name
  force_destroy = true # Allows the bucket to be destroyed even if it contains objects
}

# Enable Public Access for the Bucket
resource "aws_s3_bucket_public_access_block" "enable_public_access" {
  bucket = aws_s3_bucket.static_bucket.bucket

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
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


# # Set role permissions
# resource "aws_iam_role_policy_attachment" "github_actions" {
#   role       = aws_iam_role.github_actions.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Start broad, then restrict
# }

  
# # 2. Policy attachements (repeatable)
# resource "aws_iam_role_policy_attachment" "dynamodb" {
#   role       = aws_iam_role.github_actions.name  
#   policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" # aws_iam_policy.terraform_lock_policy.arn
# }

# Outputs to look for creations in aws
output "s3_bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}

# output "github_role_arn" {
#   value = aws_iam_role.github_actions.arn 
# }
output "aws_iam_policy" {
  value = aws_iam_policy.terraform_lock_policy.id
}
