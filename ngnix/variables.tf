variable "automount_service_account_token" {}

variable "host_ipc" {}
variable "hostPid" {}
variable "run_as_non_root" {}

variable "add_capabilities" {
  type = list(string)
}

variable "labels" {
  type = map
}