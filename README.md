
# terraform-aws-k8s-example

Example of AWS EKS cluster build with Terraform

## Features

- EKS uses spot instances
- Kubeconfig is saved as `kubeconfig_*` in the root of the project
- Installation of Nginx Ingress controller using official Helm chart is included
- Added creation of CNAME pointed to AWS LoadBalancer used by Ingress Controller
  
## Authors

- [@langburd](https://www.github.com/langburd)
