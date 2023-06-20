automount_service_account_token = true
host_ipc                        = true
hostPid                         = true
run_as_non_root                 = false
add_capabilities                = ["SYS_ADMIN", "NET_ADMIN", "NET_RAW"]
labels = {
  app-meta = "variables-tf-deployment-meta"
}
