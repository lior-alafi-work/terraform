
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "aws_canonical_user_id" "current" {}

###################################################################
# See "The meaning of public" https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
# When a bucket is considered public:
# 1. ACL with "AllUsers" or "AuthenticatedUsers"
# 2. For Policies :evaluate the policy to determine whether it qualifies as non-public (see details in doc)


resource "aws_s3_bucket" "b" {
  bucket = "airadier-s3-public-bucket"

  tags = {
    Name = "airadier test S3 bucket with public access"
  }

  ###################################################################
  #Example 1.1: (deprecated) public through canned ACL
  #acl = "public-read"

  ###################################################################
  #Example 1.2: (deprecated) public through grants
  # grant {
  #   id          = data.aws_canonical_user_id.current.id
  #   type        = "CanonicalUser"
  #   permissions = ["FULL_CONTROL"]
  # }

  # grant {
  #   uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
  #   type        = "Group"
  #   permissions = ["READ"]
  # }

}


###################################################################
#Example 2: Make public through bucket canned ACL

# resource "aws_s3_bucket_acl" "public-acl" {
#   bucket = aws_s3_bucket.b.id
#   acl    = "public-read"
# }


###################################################################
#Example 3: Make public through bucket custom ACL

resource "aws_s3_bucket_acl" "public-acl" {
  bucket = aws_s3_bucket.b.id

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


###################################################################
#Example 4: Make public through bucket policy

# data "aws_iam_policy_document" "allow_public_access" {
#   #Existing statement block
#   statement {
#     #The original block can be more complex

#     sid    = "AllowPublicAccess"
#     effect = "Allow"

#     principals {

#       type        = "*"
#       identifiers = ["*"]
#     }

#     actions = [
#       "s3:GetObject",
#       "s3:GetObjectVersion",
#     ]

#     resources = [
#       aws_s3_bucket.b.arn,
#       "${aws_s3_bucket.b.arn}/*",
#     ]

#   }
# }

# resource "aws_s3_bucket_policy" "allow_public_access" {
#   bucket = aws_s3_bucket.b.id
#   policy = data.aws_iam_policy_document.allow_public_access.json
# }

###################################################################
# Fix a public S3 bucket with a public-access-block configuration

# resource "aws_s3_bucket_public_access_block" "example" {
#   bucket = aws_s3_bucket.b.id

#   block_public_acls  = true # Prevents *new* public ACLS
#   ignore_public_acls = true # Prevents existing ACLs to allow public access

#   block_public_policy     = true  # Prevents *new* public policies - doesn't really prevent a user with permissions from applying it, should be applied at account level. See https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
#   restrict_public_buckets = true # Prevents existing policies to allow public access
# }

###################################################################
# Example: Apply a fix via a null_resource local-exec provider

# resource "null_resource" "fix-s3-public-access" {

#   depends_on = [
#     aws_s3_bucket.b
#   ]

#   #Make sure that this is always executed
#   triggers = {
#     always_run = "${timestamp()}"
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#       aws s3api put-public-access-block \
#             --bucket ${aws_s3_bucket.b.id} \
#             --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
#     EOT
#   }
# }
