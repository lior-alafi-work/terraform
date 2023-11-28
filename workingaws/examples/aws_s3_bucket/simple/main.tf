terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

###################################################################
# See "The meaning of public" https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
# When a bucket is considered public:
# 1. ACL with "AllUsers" or "AuthenticatedUsers"
# 2. For Policies :evaluate the policy to determine whether it qualifies as non-public (see details in doc)

resource "aws_s3_bucket" "example" {
  bucket = "test-bucket"

  #Should have either server_side_encryption_configuration or a linked aws_s3_bucket_server_side_encryption_configuration resource
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "foo"
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "foo"
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_http_access" {
  bucket = aws_s3_bucket.example.id
  policy = <<EOF
{
  'Sid': <optional>',
  'Effect': 'Deny',
  'Principal': '*',
  'Action': 's3:GetObject',
  'Resource': 'arn:aws:s3:::${aws_s3_bucket.example.id}/*',
  'Condition': {
    'Bool': {
      'aws:SecureTransport': 'false'
    }
  }
}
EOF
}
