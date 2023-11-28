
output "cluster_kubeconfig" {
  description = "Kubeconfig to connect to the cluster"
  value       = module.cluster.kubeconfig
}

############ EKS cluster ############

provider "aws" {
  region = "eu-west-2"
}

module "cluster" {
  source            = "./infra-cluster-eks"
  name              = "test-eks-cluster"
  additional_admins = var.additional_admins
  ssh_public_key    = var.ssh_public_key
  kubectl_platform  = var.kubectl_platform
  instance_type     = "t2.medium"
}
