provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
}

locals {
  cluster_name = "customername-eks-spot-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.47"

  name                 = "customername-vpc-spot"
  cidr                 = "10.188.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.188.4.0/24", "10.188.5.0/24", "10.188.6.0/24"]
  enable_dns_hostnames = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.1.0"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  worker_groups_launch_template = [
    {
      name = "spot-1"
      override_instance_types = ["t3.medium", "t3a.medium"]
      spot_instance_pools     = 4
      asg_min_size            = 1
      asg_max_size            = 6
      asg_desired_capacity    = 3
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot"
      public_ip               = true
    },
  ]
}
