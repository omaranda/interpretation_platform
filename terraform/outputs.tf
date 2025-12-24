# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

# RDS Outputs
output "database_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = var.database_name
}

# ALB Outputs
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer Zone ID"
  value       = module.alb.zone_id
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "https://${var.frontend_url}"
}

output "backend_url" {
  description = "Backend API URL"
  value       = "https://${var.backend_url}"
}

output "jitsi_url" {
  description = "Jitsi Meet URL"
  value       = "https://${var.jitsi_domain}"
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "backend_service_name" {
  description = "Backend ECS service name"
  value       = module.ecs.backend_service_name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = module.ecs.frontend_service_name
}

# Deployment Instructions
output "deployment_instructions" {
  description = "Quick deployment instructions"
  value = <<-EOT

    📦 Deployment Instructions:

    1. Build and push Docker images:
       aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

       docker build -t ${module.ecr.repository_urls["backend"]}:latest ./backend
       docker push ${module.ecr.repository_urls["backend"]}:latest

       docker build -t ${module.ecr.repository_urls["frontend"]}:latest ./frontend
       docker push ${module.ecr.repository_urls["frontend"]}:latest

    2. Update ECS services:
       aws ecs update-service --cluster ${module.ecs.cluster_name} --service ${module.ecs.backend_service_name} --force-new-deployment
       aws ecs update-service --cluster ${module.ecs.cluster_name} --service ${module.ecs.frontend_service_name} --force-new-deployment

    3. Configure DNS:
       Create CNAME records pointing to: ${module.alb.dns_name}
       - ${var.frontend_url}
       - ${var.backend_url}
       - ${var.jitsi_domain}

    4. Access your application:
       Frontend: https://${var.frontend_url}
       Backend API: https://${var.backend_url}/docs
       Jitsi: https://${var.jitsi_domain}
  EOT
}
