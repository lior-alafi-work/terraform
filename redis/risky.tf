resource "kubernetes_deployment" "risky_redis_deployment" {
  metadata {
    name      = "risky-redis-deployment-tf"
    namespace = "default"
  }

  spec {
    replicas          = 1
    min_ready_seconds = 6

    selector {
      match_labels = {
        app = "web"
      }
    }

    template {
      metadata {
        labels = {
          app = "web"
        }
      }

      spec {
        volume {
          name = "risky-volume"

          host_path {
            path = "/var/run/docker.sock"
          }
        }


        container {
          name  = "risky-redis-container"
          image = "redis:latest"

          port {
            name           = "redis"
            host_port      = 6379
            container_port = 6379
            protocol       = "TCP"
          }

          env_from {
            secret_ref {
              name = "risky-secret"
            }
          }

          env {
            name = "MY_DB_PW"

            value_from {
              secret_key_ref {
                name = "risky-secret"
                key  = "PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "risky-volume"
            mount_path = "/mnt/risky"
          }

          image_pull_policy = "Never"

          security_context {
            capabilities {
              add = ["SYS_ADMIN", "NET_ADMIN", "NET_RAW"]
            }

            privileged                 = true
            allow_privilege_escalation = true
            run_as_user                = 1
          }
        }

        container {
          name  = "some-second-container"
          image = "mysql"
          security_context {
            run_as_user = 1
          }
        }

        service_account_name            = "default"
        automount_service_account_token = true
        host_network                    = true
        host_pid                        = true
        host_ipc                        = true
      }
    }
  }
}
