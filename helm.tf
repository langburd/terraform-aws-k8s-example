data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    annotations = {
      created-by = "terraform"
    }
    labels = {
      purpose = "testing"
    }
  }
}

resource "helm_release" "nginx_ingress" {
  name = "nginx-ingress"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "nginx-ingress"

  set {
    name  = "replicaCount"
    value = "3"
  }

  # values = [
  #   "${file("values.yaml")}"
  # ]
}

# Get the FQDN of the loadbalancer connected to the Ingress Controller
data "kubernetes_service" "ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.nginx_ingress]
}

# # Get ID of the zone hosted in Route53 (if it's not managed by Terraform)
# data "aws_route53_zone" "main" {
#   name         = "customername.com"
#   private_zone = false
# }

# # create CNAME for 'desiredsubdomainname' pointed to the loadbalancer
# resource "aws_route53_record" "dns_record" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "desiredsubdomainname"
#   type    = "CNAME"
#   ttl     = "300"
#   records = [data.kubernetes_service.ingress.load_balancer_ingress.0.hostname]
# }

# ==================== Example of ArgoCD installation via Helm Chart ====================
# resource "kubernetes_namespace" "argocd" {
#   metadata {
#     name = "argocd"
#     annotations = {
#       created-by = "terraform"
#     }
#     labels = {
#       purpose = "testing"
#     }
#   }
# }

#
# resource "helm_release" "argocd" {
#   name       = "argo-cd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   version    = "3.2.1"
#   namespace  = kubernetes_namespace.argocd.metadata.0.name
#   set {
#     name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
#     value = var.acm_cert
#     type  = "string"
#   }
#   values = [
#     file("${path.module}/files/argo-cd/values-override.yaml"),
#   ]
# }

# data "aws_secretsmanager_secret" "argocd_ssh_key" {
#   name = var.prod_infra_sshkey
# }

# data "aws_secretsmanager_secret_version" "argocd_ssh_key" {
#   secret_id = data.aws_secretsmanager_secret.argocd_ssh_key.id
# }

# locals {
#   argocd_ssh_key_base64 = base64decode(data.aws_secretsmanager_secret_version.argocd_ssh_key.secret_string)
# }

# resource "kubernetes_secret" "argocd_ssh_key" {
#   metadata {
#     name      = "infra-ssh-key"
#     namespace = kubernetes_namespace.argocd.metadata.0.name
#   }

#   data = {
#     sshPrivateKey = local.argocd_ssh_key_base64
#   }
# }
