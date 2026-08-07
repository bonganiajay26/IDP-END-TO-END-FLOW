output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name."
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS API endpoint."
}

output "ecr_repository_name" {
  value       = aws_ecr_repository.sample_api.name
  description = "ECR repository name used by GitHub Actions."
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.sample_api.repository_url
  description = "ECR repository URL."
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "OIDC role assumed by GitHub Actions."
}
