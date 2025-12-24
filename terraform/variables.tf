# General Configuration
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "translation-platform"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

# Database Configuration
variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "translation_platform"
}

variable "database_username" {
  description = "PostgreSQL database username"
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "rds_backup_retention_days" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

# Application Configuration
variable "jwt_secret_key" {
  description = "JWT secret key for authentication"
  type        = string
  sensitive   = true
}

variable "frontend_url" {
  description = "Frontend URL"
  type        = string
}

variable "backend_url" {
  description = "Backend API URL"
  type        = string
}

variable "jitsi_domain" {
  description = "Jitsi Meet domain"
  type        = string
}

# SSL Certificate
variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = ""
}

# ECS Service Configuration
variable "backend_cpu" {
  description = "CPU units for backend service (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory for backend service in MB"
  type        = number
  default     = 1024
}

variable "backend_count" {
  description = "Number of backend tasks"
  type        = number
  default     = 2
}

variable "frontend_cpu" {
  description = "CPU units for frontend service"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory for frontend service in MB"
  type        = number
  default     = 512
}

variable "frontend_count" {
  description = "Number of frontend tasks"
  type        = number
  default     = 2
}

variable "jitsi_cpu" {
  description = "CPU units for Jitsi services"
  type        = number
  default     = 1024
}

variable "jitsi_memory" {
  description = "Memory for Jitsi services in MB"
  type        = number
  default     = 2048
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}
