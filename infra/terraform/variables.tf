variable "aws_region" {
  description = "AWS region for the platform."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for platform resources."
  type        = string
  default     = "idp-demo"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR for the platform VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "cluster_version" {
  description = "EKS Kubernetes minor version."
  type        = string
  default     = "1.36"
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "github_org" {
  description = "GitHub organization or username allowed to assume the CI role."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the CI role."
  type        = string
  default     = "internal-developer-platform"
}
