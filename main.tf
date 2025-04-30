provider "aws" {
  region = "us-east-1" # Change to your desired region
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

# 1️⃣ Create an S3 Bucket
resource "aws_s3_bucket" "static_bucket" {
  bucket = "rgers3.tf-workflows2"  # Change this to a unique bucket name
}

# 2️⃣ Configure Static Website Hosting
resource "aws_s3_bucket_public_access_block" "enable_public_access" {
  bucket = aws_s3_bucket.static_bucket.id

  block_public_acls = true
  block_public_policy = false  # Allow public bucket policy
  ignore_public_acls = true
  restrict_public_buckets = true
}

# 3️⃣ Set S3 Bucket Policy for Public Read Access
resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.static_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.static_bucket.id}/*"
    }
  ]
}
POLICY
}


resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = "rgers3.tf-workflows2"
  
  block_public_acls = true
  block_public_policy = false  # Allow public bucket policy
  ignore_public_acls = true
  restrict_public_buckets = true
}