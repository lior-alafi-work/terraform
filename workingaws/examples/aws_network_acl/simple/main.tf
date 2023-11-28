terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_network_acl" "main" {
  vpc_id = "some-vpc-id"

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    # Access from 0.0.0.0/0 to port 22 or 3389 violates CIS 5.1
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  tags = {
    Name = "main"
  }
}