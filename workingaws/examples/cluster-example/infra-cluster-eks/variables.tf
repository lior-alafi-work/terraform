variable "name" {
  description = "Cluster name"
  type        = string
}

variable "node_count" {
  type    = number
  default = 2
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "ssh_public_key" {
  description = "Path to the SSH Public key file"
}

variable "additional_admins" {
  description = "List of ARNs for users that should have admin permissions in the cluster"
  type = list(object({
    arn      = string
    username = string
  }))
}

variable "kubectl_platform" {
  type    = string
  default = "linux"
}
