
terraform {
  backend "s3" {
    bucket         = "customername-tfstates"
    key            = "production/customername-k8s-cluster.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "customername-terraform-state-locking"
    encrypt        = true
  }
}
