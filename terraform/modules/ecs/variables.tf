variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

# ECR Repository URLs
variable "backend_repository_url" {
  description = "Backend ECR repository URL"
  type        = string
}

variable "frontend_repository_url" {
  description = "Frontend ECR repository URL"
  type        = string
}

variable "jitsi_web_repository_url" {
  description = "Jitsi Web ECR repository URL"
  type        = string
}

variable "jitsi_prosody_repository_url" {
  description = "Jitsi Prosody ECR repository URL"
  type        = string
}

variable "jitsi_jicofo_repository_url" {
  description = "Jitsi Jicofo ECR repository URL"
  type        = string
}

variable "jitsi_jvb_repository_url" {
  description = "Jitsi JVB ECR repository URL"
  type        = string
}

# Database Configuration
variable "database_host" {
  description = "Database host"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Application Configuration
variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "frontend_url" {
  description = "Frontend URL"
  type        = string
}

variable "backend_url" {
  description = "Backend URL"
  type        = string
}

variable "jitsi_domain" {
  description = "Jitsi domain"
  type        = string
}

# Load Balancer
variable "alb_target_group_backend_arn" {
  description = "Backend ALB target group ARN"
  type        = string
}

variable "alb_target_group_frontend_arn" {
  description = "Frontend ALB target group ARN"
  type        = string
}

variable "alb_target_group_jitsi_arn" {
  description = "Jitsi ALB target group ARN"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}

# Service Configuration
variable "backend_cpu" {
  description = "Backend CPU units"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Backend memory in MB"
  type        = number
  default     = 1024
}

variable "backend_count" {
  description = "Number of backend tasks"
  type        = number
  default     = 2
}

variable "frontend_cpu" {
  description = "Frontend CPU units"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Frontend memory in MB"
  type        = number
  default     = 512
}

variable "frontend_count" {
  description = "Number of frontend tasks"
  type        = number
  default     = 2
}

variable "jitsi_cpu" {
  description = "Jitsi CPU units"
  type        = number
  default     = 1024
}

variable "jitsi_memory" {
  description = "Jitsi memory in MB"
  type        = number
  default     = 2048
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}
