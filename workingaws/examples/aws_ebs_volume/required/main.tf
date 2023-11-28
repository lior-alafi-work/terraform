terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_ebs_volume" "example" {
  availability_zone = "us-west-2a"
  size              = 10
  encrypted         = var.encrypt

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_kms_key" "example" {
  description             = "KMS key is used to encrypt EBS volumes"
  deletion_window_in_days = 7
}

resource "aws_ebs_encryption_by_default" "example" {
  enabled = var.encrypt_by_default
}

resource "aws_ebs_default_kms_key" "example" {
  key_arn = aws_kms_key.example.arn
}