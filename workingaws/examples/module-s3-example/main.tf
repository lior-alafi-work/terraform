data "aws_canonical_user_id" "current" {}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.2.3"
  bucket  = "${var.bucket_name}-s3-test-bucket"

  grant = [
    {
      type       = "CanonicalUser"
      permission = "FULL_CONTROL"
      id         = data.aws_canonical_user_id.current.id
    },
    {
      type       = "Group"
      permission = "READ"
      uri        = "http://acs.amazonaws.com/groups/global/AllUsers"
    }
  ]
}
