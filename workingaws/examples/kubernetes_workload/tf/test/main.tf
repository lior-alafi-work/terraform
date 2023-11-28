module "test_dep" {
  source = "../tf-test-dep"
}

resource "kubernetes_deployment" "test" {
  metadata {
    name = "test"
  }

  spec {
    selector {
      match_labels = {
        app = "test"
      }
    }

    template {
      metadata {
        labels = {
          app = "test"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "test"
        }

        security_context {
          run_as_user = module.test_dep.run_as_user
        }

      }
    }
  }
}