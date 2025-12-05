terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. S3 Bucket for State File
resource "aws_s3_bucket" "s3_remote_backend" {
  bucket = "devops-automation-project-komal-tfstate" # Changed bucket name for better adherence to uniqueness
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name = "Terraform-State-Bucket"
  }
}

# 2. Enable Versioning (Crucial for state recovery)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.s3_remote_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Enable Encryption (Best Practice)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.s3_remote_backend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. DynamoDB Table for State Locking
resource "aws_dynamodb_table" "dynamodb_lock_table" {
  name           = "devops-automation-project-lock-table-komal"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "Terraform-Lock-Table"
  }
}