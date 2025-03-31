provider "aws" {
  region = "us-east-1" # Change to your desired region
}

# Part 1: Create S3 Bucket
resource "aws_s3_bucket" "static_bucket" {
  bucket        = "rgers3.sctp-sandbox.com" # Replace with your desired bucket name
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

# Part 4: Set Up Route 53 Record to Point to Your Bucket
data "aws_route53_zone" "sctp_zone" {
  name = "sctp-sandbox.com" # Replace with your domain name
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.sctp_zone.zone_id
  name    = "rgers3" # Bucket prefix before sctp-sandbox.com
  type    = "A"

  alias {
    name                   = aws_s3_bucket_website_configuration.website.website_domain
    zone_id                = aws_s3_bucket.static_bucket.hosted_zone_id
    evaluate_target_health = true
  }
}

# backend.
terraform {
  backend "s3" {
    bucket = "rgers3.tfstate-backend.com"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locks"  # Critical for locking
  }
}

# Output the S3 Bucket Website Endpoint
output "s3_bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}
#output route53 name servers
output "route53_name_servers" {
  value = data.aws_route53_zone.sctp_zone.name_servers
}

# DynamoDB permissions ---added to try
resource "aws_iam_policy" "terraform_lock_policy" {
  name        = "TerraformLockTableAccess"
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

# Then attach to the IAM user...
resource "aws_iam_user_policy_attachment" "rgers3" {
  user       = "rgers3-github-actions-iam-user"
  policy_arn = aws_iam_policy.terraform_lock_policy.arn
  
}

# grant permissions to attach policy
resource "aws_iam_user_policy" "roger_permissions" {
  user = "roger_ce9"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy"
        ]
        Resource = "arn:aws:iam::255945442255:user/rgers3-github-actions-iam-user"
      }
    ]
  })
}