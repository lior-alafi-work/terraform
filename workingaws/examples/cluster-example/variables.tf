variable "additional_admins" {
  description = "List of ARNs for users that should have admin permissions in the cluster"
  type = list(object({
    arn      = string
    username = string
  }))
}

variable "ssh_public_key" {
  description = "Path to the SSH Public key file"
}

variable "kubectl_platform" {
  type    = string
  default = "linux"
}
