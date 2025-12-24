# Production Environment
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    # Configure after creating S3 bucket
    # bucket         = "translation-platform-terraform-state"
    # key            = "prod/terraform.tfstate"
    # region         = "us-east-1"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}

module "translation_platform" {
  source = "../../"

  # Pass all variables from terraform.tfvars
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  database_name     = var.database_name
  database_username = var.database_username
  database_password = var.database_password

  rds_instance_class        = var.rds_instance_class
  rds_allocated_storage     = var.rds_allocated_storage
  rds_backup_retention_days = var.rds_backup_retention_days

  jwt_secret_key = var.jwt_secret_key
  frontend_url   = var.frontend_url
  backend_url    = var.backend_url
  jitsi_domain   = var.jitsi_domain

  acm_certificate_arn = var.acm_certificate_arn

  backend_cpu    = var.backend_cpu
  backend_memory = var.backend_memory
  backend_count  = var.backend_count

  frontend_cpu    = var.frontend_cpu
  frontend_memory = var.frontend_memory
  frontend_count  = var.frontend_count

  jitsi_cpu    = var.jitsi_cpu
  jitsi_memory = var.jitsi_memory

  log_retention_days = var.log_retention_days
}

output "deployment_info" {
  value = module.translation_platform.deployment_instructions
}
