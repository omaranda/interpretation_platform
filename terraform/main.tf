# Translation Platform - AWS Infrastructure
# This Terraform configuration deploys the platform to AWS using ECS Fargate

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state management
  # Uncomment and configure after creating S3 bucket
  # backend "s3" {
  #   bucket         = "translation-platform-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TranslationPlatform"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Container ports
  backend_port   = 8000
  frontend_port  = 3000
  jitsi_web_port = 8443
  postgres_port  = 5432
}

# VPC and Networking
module "networking" {
  source = "./modules/networking"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  tags = local.common_tags
}

# ECR Repositories
module "ecr" {
  source = "./modules/ecr"

  name_prefix = local.name_prefix

  repositories = [
    "backend",
    "frontend",
    "jitsi-web",
    "jitsi-prosody",
    "jitsi-jicofo",
    "jitsi-jvb"
  ]

  tags = local.common_tags
}

# RDS PostgreSQL Database
module "rds" {
  source = "./modules/rds"

  name_prefix           = local.name_prefix
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  database_name         = var.database_name
  database_username     = var.database_username
  database_password     = var.database_password
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  backup_retention_days = var.rds_backup_retention_days

  allowed_security_group_ids = [module.ecs.backend_security_group_id]

  tags = local.common_tags
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  name_prefix        = local.name_prefix
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  certificate_arn    = var.acm_certificate_arn

  tags = local.common_tags
}

# ECS Cluster and Services
module "ecs" {
  source = "./modules/ecs"

  name_prefix                = local.name_prefix
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  public_subnet_ids          = module.networking.public_subnet_ids

  # ECR repositories
  backend_repository_url     = module.ecr.repository_urls["backend"]
  frontend_repository_url    = module.ecr.repository_urls["frontend"]
  jitsi_web_repository_url   = module.ecr.repository_urls["jitsi-web"]
  jitsi_prosody_repository_url = module.ecr.repository_urls["jitsi-prosody"]
  jitsi_jicofo_repository_url  = module.ecr.repository_urls["jitsi-jicofo"]
  jitsi_jvb_repository_url     = module.ecr.repository_urls["jitsi-jvb"]

  # Database configuration
  database_host     = module.rds.db_endpoint
  database_name     = var.database_name
  database_username = var.database_username
  database_password = var.database_password

  # Application configuration
  jwt_secret_key    = var.jwt_secret_key
  frontend_url      = var.frontend_url
  backend_url       = var.backend_url
  jitsi_domain      = var.jitsi_domain

  # Load balancer
  alb_target_group_backend_arn  = module.alb.backend_target_group_arn
  alb_target_group_frontend_arn = module.alb.frontend_target_group_arn
  alb_target_group_jitsi_arn    = module.alb.jitsi_target_group_arn
  alb_security_group_id         = module.alb.security_group_id

  # Service configuration
  backend_cpu       = var.backend_cpu
  backend_memory    = var.backend_memory
  backend_count     = var.backend_count

  frontend_cpu      = var.frontend_cpu
  frontend_memory   = var.frontend_memory
  frontend_count    = var.frontend_count

  jitsi_cpu         = var.jitsi_cpu
  jitsi_memory      = var.jitsi_memory

  tags = local.common_tags
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name_prefix}/backend"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.name_prefix}/frontend"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "jitsi" {
  name              = "/ecs/${local.name_prefix}/jitsi"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}
