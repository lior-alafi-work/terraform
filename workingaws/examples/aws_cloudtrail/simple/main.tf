terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_canonical_user_id" "current" {}

resource "aws_kms_key" "example" {
  description             = "KMS key is used to encrypt DB instance"
  deletion_window_in_days = 7
}

resource "aws_cloudtrail" "example" {
  name                          = "tf-trail-example"
  s3_bucket_name                = aws_s3_bucket.example.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false

  #This should be true for CIS 3.2
  enable_log_file_validation    = false

  #CIS 3.7
  kms_key_id = aws_kms_key.example.id
}

resource "aws_s3_bucket" "example" {
  bucket        = "tf-example-trail"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.example.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.example.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF
}

################################################
#The ACLS and Policies break CIS 3.3
################################################

resource "aws_s3_bucket_acl" "public-canned-acl" {
  bucket = aws_s3_bucket.example.id
  acl    = "public-read"
}

resource "aws_s3_bucket_acl" "public-acl" {
  bucket = aws_s3_bucket.example.id

  access_control_policy {
    grant {
      permission = "READ"

      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/global/AllUsers"
      }
    }

    grant {
      permission = "FULL_CONTROL"

      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

data "aws_iam_policy_document" "allow_public_access" {
  #Existing statement block
  statement {
    #The original block can be more complex

    sid    = "AllowPublicAccess"
    effect = "Allow"

    principals {

      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]

  }
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.allow_public_access.json
}

###################################################################
# Fix a public S3 bucket with a public-access-block configuration

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls  = true # Prevents *new* public ACLS
  ignore_public_acls = true # Prevents existing ACLs to allow public access

  block_public_policy     = true  # Prevents *new* public policies - doesn't really prevent a user with permissions from applying it, should be applied at account level. See https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
  restrict_public_buckets = true # Prevents existing policies to allow public access
}

###################################################################
# CIS 3.6, bucket access logging

resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-tf-log-bucket"
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.example.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}