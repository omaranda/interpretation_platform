# Import all variables from root module
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type = number
}

variable "database_name" {
  type = string
}

variable "database_username" {
  type      = string
  sensitive = true
}

variable "database_password" {
  type      = string
  sensitive = true
}

variable "rds_instance_class" {
  type = string
}

variable "rds_allocated_storage" {
  type = number
}

variable "rds_backup_retention_days" {
  type = number
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
}

variable "frontend_url" {
  type = string
}

variable "backend_url" {
  type = string
}

variable "jitsi_domain" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "backend_cpu" {
  type = number
}

variable "backend_memory" {
  type = number
}

variable "backend_count" {
  type = number
}

variable "frontend_cpu" {
  type = number
}

variable "frontend_memory" {
  type = number
}

variable "frontend_count" {
  type = number
}

variable "jitsi_cpu" {
  type = number
}

variable "jitsi_memory" {
  type = number
}

variable "log_retention_days" {
  type = number
}
