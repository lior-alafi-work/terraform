data "aws_region" "current" {}

locals {
  name            = var.name
  cluster_version = "1.23"
  instance_type   = var.instance_type
  region          = data.aws_region.current.name
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      use_name_prefix = true

      create_launch_template = false
      launch_template_name   = ""

      min_size     = var.node_count
      max_size     = var.node_count
      desired_size = var.node_count

      #TODO: SSH Access
      remote_access = var.ssh_public_key == null ? {} : {
        ec2_ssh_key = aws_key_pair.node_key_pair[0].id
      }

      instance_types = [local.instance_type]

      tags = local.tags
    }
  }

  enable_irsa = false

  tags = local.tags
}

################################################################################
# aws-auth configmap
# Only EKS managed node groups automatically add roles to aws-auth configmap
# so we need to ensure fargate profiles and self-managed node roles are added
################################################################################

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  alias                  = "local_cluster"
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

data "kubernetes_config_map" "aws_auth" {
  depends_on = [module.eks]
  provider   = kubernetes.local_cluster
  metadata {
    namespace = "kube-system"
    name      = "aws-auth"
  }
}

locals {
  kubeconfig_with_token = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = module.eks.cluster_arn
    clusters = [{
      name = module.eks.cluster_arn
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = module.eks.cluster_arn
      context = {
        cluster = module.eks.cluster_arn
        user    = module.eks.cluster_arn
      }
    }]
    users = [{
      name = module.eks.cluster_arn
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })

  aws_auth_users = [for user in var.additional_admins :
    <<EOT
    - userarn: ${user.arn}
      username: ${user.username}
      groups:
      - system:masters
  EOT
  ]

  aws_auth_configmap_yaml_patch = <<-EOT
data:
  mapUsers: |
${join("", local.aws_auth_users)}
  EOT

  cmd_patch = "./kubectl patch configmap/aws-auth --patch \"${local.aws_auth_configmap_yaml_patch}\" -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)"
}


resource "null_resource" "patch" {
  depends_on = [
    module.eks,
    data.kubernetes_config_map.aws_auth,
    data.aws_eks_cluster_auth.this
  ]

  triggers = {
    patch = local.aws_auth_configmap_yaml_patch
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = base64encode(local.kubeconfig_with_token)
    }
    command = <<-EOT
      curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${var.kubectl_platform}/amd64/kubectl
      chmod +x ./kubectl
      ${local.cmd_patch}
    EOT
  }
}

################################################################################
# Supporting resources
################################################################################

resource "aws_key_pair" "node_key_pair" {
  count           = var.ssh_public_key == null ? 0 : 1
  key_name_prefix = "eks-${var.name}"
  public_key      = file(var.ssh_public_key)
  tags            = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = false
  create_flow_log_cloudwatch_iam_role  = false
  create_flow_log_cloudwatch_log_group = false

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  tags = local.tags
}

resource "aws_security_group" "additional" {
  name_prefix = "${local.name}-additional"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = local.tags
}
