
#Option 1, patch the "module" block
#Problems: each module can define parameters in any way!! Not standard
module "s3-bucket" {
  grant = [
    {
      type       = "CanonicalUser"
      permission = "FULL_CONTROL"
      id         = data.aws_canonical_user_id.current.id
    },
  ]
}


###########################################################################################################################
# Patching resources defined inside a module is not supported.
# Ideally we could do something like resource "module.s3-bucket.aws_s3_bucket_acl.this[0]" or similar, but it does not work
# resource "aws_s3_bucket_acl" "this[0]" {
#   access_control_policy {
#     grant {
#       permission = "FULL_CONTROL"

#       grantee {
#         id   = data.aws_canonical_user_id.current.id
#         type = "CanonicalUser"
#       }
#     }

#     owner {
#       id = data.aws_canonical_user_id.current.id
#     }
#   }
# }
