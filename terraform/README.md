# Translation Platform - Terraform Infrastructure

This directory contains Terraform configurations for deploying the Translation Platform to AWS.

## 📁 Directory Structure

```
terraform/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── README.md                  # This file
├── modules/                   # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, NAT gateways
│   ├── ecr/                   # Docker container registry
│   ├── rds/                   # PostgreSQL database
│   ├── alb/                   # Application Load Balancer
│   └── ecs/                   # ECS Fargate services
├── environments/              # Environment-specific configurations
│   ├── dev/                   # Development environment
│   ├── staging/               # Staging environment
│   └── prod/                  # Production environment
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars.example
└── scripts/                   # Helper scripts
    └── deploy.sh              # Automated deployment script
```

## 🚀 Quick Start

### 1. Prerequisites

- AWS Account with administrator access
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0 installed
- Docker installed

### 2. Configure Environment

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Edit with your values
```

### 3. Deploy Using Script (Recommended)

```bash
# From the terraform directory
./scripts/deploy.sh prod us-east-1
```

### 4. Manual Deployment

```bash
cd environments/prod

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Get outputs
terraform output
```

## 🏗️ Architecture

The Terraform configuration creates:

- **VPC**: Multi-AZ VPC with public and private subnets
- **ECR**: Docker container repositories
- **RDS**: PostgreSQL database (Multi-AZ optional)
- **ECS Fargate**: Serverless container orchestration
- **Application Load Balancer**: HTTPS routing
- **CloudWatch**: Logging and monitoring
- **Security Groups**: Network security
- **IAM Roles**: Service permissions

## 📦 Modules

### Networking Module

Creates VPC infrastructure:
- Public subnets for ALB
- Private subnets for ECS and RDS
- NAT Gateways for outbound internet access
- VPC endpoints for AWS services

### ECR Module

Manages Docker container registries:
- Separate repositories for each service
- Image scanning enabled
- Lifecycle policies for image cleanup

### RDS Module

PostgreSQL database:
- Automated backups
- Multi-AZ deployment (optional)
- Encryption at rest
- Performance Insights

### ALB Module

Application Load Balancer:
- HTTPS termination
- Host-based routing
- Health checks
- SSL/TLS policies

### ECS Module

ECS Fargate services:
- Backend (FastAPI)
- Frontend (Next.js)
- Jitsi Meet (optional)
- Auto-scaling (optional)
- Service discovery

## 🔧 Configuration

### Required Variables

```hcl
# Domain Configuration
frontend_url   = "app.yourdomain.com"
backend_url    = "api.yourdomain.com"
jitsi_domain   = "meet.yourdomain.com"

# SSL Certificate ARN from ACM
acm_certificate_arn = "arn:aws:acm:..."

# Database Credentials
database_username = "dbadmin"
database_password = "SECURE_PASSWORD"

# JWT Secret
jwt_secret_key = "RANDOM_SECRET_KEY"
```

### Optional Variables

```hcl
# Instance sizes
rds_instance_class = "db.t3.small"
backend_cpu        = 1024
backend_memory     = 2048

# Scaling
backend_count  = 2
frontend_count = 2

# Retention
log_retention_days        = 30
rds_backup_retention_days = 14
```

## 💰 Cost Estimation

### Typical Production Setup

| Component | Monthly Cost |
|-----------|--------------|
| ECS Fargate (4 tasks) | $50-70 |
| RDS db.t3.small | $30-40 |
| ALB | $20-25 |
| NAT Gateway (2 AZs) | $60-70 |
| Data Transfer | $10-50 |
| CloudWatch Logs | $5-10 |
| **Total** | **~$175-265** |

Use the [AWS Pricing Calculator](https://calculator.aws/) for detailed estimates.

## 🔒 Security Best Practices

1. **Secrets Management**
   - Use AWS Secrets Manager for sensitive data
   - Rotate credentials regularly
   - Never commit `terraform.tfvars` to git

2. **Network Security**
   - Private subnets for compute and database
   - Security groups with least privilege
   - VPC Flow Logs enabled

3. **Encryption**
   - TLS 1.3 for ALB
   - RDS encryption at rest
   - S3 encryption for Terraform state

4. **Access Control**
   - IAM roles with minimal permissions
   - MFA for AWS console
   - CloudTrail logging enabled

## 📊 Monitoring

### CloudWatch Dashboards

Access metrics:
- ECS service CPU/Memory
- RDS database performance
- ALB request counts and latency
- Error rates

### Alarms

Recommended alarms:
- ECS CPU > 80%
- RDS storage < 20%
- ALB 5xx errors
- Database connections

### Logs

View logs:
```bash
aws logs tail /ecs/translation-platform-prod/backend --follow
```

## 🔄 Updates

### Update Infrastructure

```bash
cd environments/prod
terraform plan
terraform apply
```

### Update Application

```bash
# Build and push new images
docker build -t backend:v2 ./backend
docker push ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/backend:v2

# Update ECS service
aws ecs update-service --cluster CLUSTER --service SERVICE --force-new-deployment
```

## 🧹 Cleanup

To destroy all resources:

```bash
cd environments/prod
terraform destroy
```

⚠️ **Warning**: This permanently deletes all resources and data!

## 📚 Additional Documentation

- [AWS Deployment Guide](../../docs/AWS_DEPLOYMENT.md) - Complete deployment walkthrough
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)

## 🐛 Troubleshooting

### Common Issues

**Issue**: Terraform state lock error
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

**Issue**: ECS tasks failing to start
```bash
# Check service events
aws ecs describe-services --cluster CLUSTER --services SERVICE
```

**Issue**: Database connection timeout
```bash
# Verify security groups allow traffic from ECS to RDS
```

See [AWS_DEPLOYMENT.md](../../docs/AWS_DEPLOYMENT.md) for detailed troubleshooting.

## 📝 Notes

- Keep `terraform.tfvars` out of version control (`.gitignore`)
- Use separate AWS accounts for dev/staging/prod
- Enable CloudTrail for audit logging
- Regular backup testing recommended
- Review AWS Trusted Advisor recommendations

## 🤝 Contributing

When adding new infrastructure:
1. Create in appropriate module
2. Add variables with descriptions
3. Add outputs for important values
4. Update documentation
5. Test in dev environment first

---

**Last Updated**: 2025-12-24
**Terraform Version**: >= 1.0
**AWS Provider Version**: ~> 5.0
