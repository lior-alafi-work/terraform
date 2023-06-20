
resource "kubernetes_deployment" "tf-variables-deployment" {
  metadata {
    name = "tf-variables-deployment"
    namespace = "default"
    labels = var.labels
  }

    spec {
      replicas = 1
      min_ready_seconds = 5

    selector {
      match_labels = {
        app = "variables-tf-deployment"
      }
    }

    template {
      metadata {
        labels = {
          app = "variables-tf-deployment"
        }
      }
      
      spec {
        automount_service_account_token = var.automount_service_account_token
        host_ipc = var.host_ipc
        host_pid = var.hostPid
		
        container {
          image = "ngnix"
          name  = "tfvars-ngnix-container"
	        image_pull_policy = "Always"

          security_context {
            run_as_non_root = var.run_as_non_root

            capabilities {
              add = var.add_capabilities
            }
          }
        }

        container {
          image = "ngnix"
          name  = "tfvars-ngnix-container-2"
	        image_pull_policy = "Always"

          security_context {
            run_as_non_root = var.run_as_non_root

            capabilities {
              add = var.add_capabilities
            }
          }
        }
      }
    }
  }
}
