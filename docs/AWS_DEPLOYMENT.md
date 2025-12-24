# AWS Deployment Guide

Complete guide for deploying the Translation Platform to AWS using Terraform and ECS Fargate.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Deployment Steps](#deployment-steps)
- [Post-Deployment](#post-deployment)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cost Estimation](#cost-estimation)

## Architecture Overview

The Translation Platform is deployed on AWS with the following architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────▼────┐
                    │  Route53 │
                    │   DNS    │
                    └────┬────┘
                         │
                    ┌────▼────┐
                    │   ACM    │
                    │   SSL    │
                    └────┬────┘
                         │
              ┌──────────▼──────────┐
              │  Application Load   │
              │     Balancer        │
              └──┬──────────────┬───┘
                 │              │
        ┌────────▼───┐    ┌────▼─────┐
        │  Frontend  │    │  Backend │
        │ECS Fargate │    │ECS Fargate│
        │  (Next.js) │    │ (FastAPI)│
        └────────────┘    └────┬─────┘
                               │
                          ┌────▼─────┐
                          │    RDS   │
                          │PostgreSQL│
                          └──────────┘
```

### Components:

- **VPC**: Isolated network with public and private subnets across multiple AZs
- **Application Load Balancer**: HTTPS termination and routing
- **ECS Fargate**: Serverless container orchestration
- **RDS PostgreSQL**: Managed database service
- **ECR**: Docker container registry
- **CloudWatch**: Logging and monitoring
- **Route53**: DNS management
- **ACM**: SSL/TLS certificates

## Prerequisites

### 1. AWS Account Setup

- AWS Account with administrator access
- AWS CLI installed and configured
- Terraform >= 1.0 installed
- Docker installed

### 2. Install Required Tools

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify AWS CLI
aws --version

# Install Terraform
brew install terraform  # macOS
# or download from https://www.terraform.io/downloads

# Verify Terraform
terraform --version

# Configure AWS credentials
aws configure
```

### 3. Domain Name

- Register a domain or use existing domain
- Access to DNS management (Route53 or external provider)

## Initial Setup

### Step 1: Request SSL Certificate

1. Go to AWS Certificate Manager (ACM) in your region
2. Request a public certificate
3. Add domain names:
   - `yourdomain.com`
   - `*.yourdomain.com` (wildcard for subdomains)
4. Use DNS validation
5. Add CNAME records to your DNS provider
6. Wait for certificate to be issued (can take up to 30 minutes)
7. Note the certificate ARN

### Step 2: Create Terraform State Backend (Optional but Recommended)

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://translation-platform-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket translation-platform-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket translation-platform-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 3: Configure Terraform Variables

```bash
cd terraform/environments/prod

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vim terraform.tfvars
```

Required variables:

```hcl
# Domain Configuration
frontend_url   = "app.yourdomain.com"
backend_url    = "api.yourdomain.com"
jitsi_domain   = "meet.yourdomain.com"

# SSL Certificate
acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID"

# Database Credentials (use strong passwords!)
database_username = "dbadmin"
database_password = "STRONG_RANDOM_PASSWORD"

# JWT Secret (generate with: openssl rand -base64 32)
jwt_secret_key = "YOUR_RANDOM_SECRET_KEY"
```

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd terraform/environments/prod

# Initialize Terraform
terraform init

# Review the plan
terraform plan
```

### Step 2: Deploy Infrastructure

```bash
# Apply Terraform configuration
terraform apply

# Review the changes and type 'yes' to confirm
```

This will create:
- VPC with public/private subnets
- NAT Gateways for private subnet internet access
- RDS PostgreSQL database
- ECR repositories for Docker images
- ECS Cluster
- Application Load Balancer
- Security Groups
- IAM Roles
- CloudWatch Log Groups

**Expected deployment time: 10-15 minutes**

### Step 3: Build and Push Docker Images

After infrastructure is created, get the ECR repository URLs:

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend
cd backend
docker build -t translation-platform-prod-backend:latest .
docker tag translation-platform-prod-backend:latest \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/translation-platform-prod-backend:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/translation-platform-prod-backend:latest

# Build and push frontend
cd ../frontend
docker build -t translation-platform-prod-frontend:latest .
docker tag translation-platform-prod-frontend:latest \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/translation-platform-prod-frontend:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/translation-platform-prod-frontend:latest
```

### Step 4: Deploy ECS Services

```bash
# Force new deployment to pull latest images
aws ecs update-service \
  --cluster translation-platform-prod-cluster \
  --service translation-platform-prod-backend \
  --force-new-deployment

aws ecs update-service \
  --cluster translation-platform-prod-cluster \
  --service translation-platform-prod-frontend \
  --force-new-deployment
```

### Step 5: Configure DNS

Get the ALB DNS name:

```bash
terraform output alb_dns_name
```

Create CNAME records in your DNS provider:

| Record Name | Type  | Value                                    |
|-------------|-------|------------------------------------------|
| app         | CNAME | translation-platform-prod-alb-xxx.elb.amazonaws.com |
| api         | CNAME | translation-platform-prod-alb-xxx.elb.amazonaws.com |
| meet        | CNAME | translation-platform-prod-alb-xxx.elb.amazonaws.com |

**DNS propagation can take 5-60 minutes**

### Step 6: Initialize Database

```bash
# Connect to backend task to run migrations
TASK_ARN=$(aws ecs list-tasks \
  --cluster translation-platform-prod-cluster \
  --service-name translation-platform-prod-backend \
  --query 'taskArns[0]' --output text)

# Execute migration command
aws ecs execute-command \
  --cluster translation-platform-prod-cluster \
  --task $TASK_ARN \
  --container backend \
  --interactive \
  --command "/bin/bash"

# Inside container, run:
# python seed_data.py  # to populate test data
```

## Post-Deployment

### Verify Deployment

1. **Check Service Health**
   ```bash
   aws ecs describe-services \
     --cluster translation-platform-prod-cluster \
     --services translation-platform-prod-backend translation-platform-prod-frontend
   ```

2. **Check Logs**
   ```bash
   aws logs tail /ecs/translation-platform-prod/backend --follow
   aws logs tail /ecs/translation-platform-prod/frontend --follow
   ```

3. **Test Endpoints**
   ```bash
   curl https://api.yourdomain.com/health
   curl https://app.yourdomain.com
   ```

4. **Login to Application**
   - Visit https://app.yourdomain.com
   - Use test credentials from `docs/TEST_ACCOUNTS.md`

### Security Hardening

1. **Enable AWS WAF** (Web Application Firewall)
   ```bash
   # TODO: Add WAF rules for ALB
   ```

2. **Enable VPC Flow Logs**
   ```bash
   # TODO: Add VPC flow logs to CloudWatch
   ```

3. **Set up AWS GuardDuty**
   ```bash
   aws guardduty create-detector --enable
   ```

4. **Rotate Secrets**
   - Move database credentials to AWS Secrets Manager
   - Enable automatic rotation

## Monitoring

### CloudWatch Dashboards

Create custom dashboard:

```bash
aws cloudwatch put-dashboard \
  --dashboard-name TranslationPlatform \
  --dashboard-body file://cloudwatch-dashboard.json
```

### Alarms

Set up CloudWatch Alarms for:

- ECS CPU > 80%
- ECS Memory > 80%
- RDS CPU > 80%
- ALB 5xx errors > 10
- RDS storage < 20%

### Logs

Access logs:

```bash
# Backend logs
aws logs tail /ecs/translation-platform-prod/backend --follow

# Frontend logs
aws logs tail /ecs/translation-platform-prod/frontend --follow

# Database logs
aws rds describe-db-log-files \
  --db-instance-identifier translation-platform-prod-db
```

## Troubleshooting

### Services Not Starting

```bash
# Check ECS service events
aws ecs describe-services \
  --cluster translation-platform-prod-cluster \
  --services translation-platform-prod-backend \
  --query 'services[0].events[:5]'

# Check task definition
aws ecs describe-task-definition \
  --task-definition translation-platform-prod-backend
```

### Database Connection Issues

```bash
# Verify security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*rds*"

# Test connection from backend task
aws ecs execute-command \
  --cluster translation-platform-prod-cluster \
  --task $TASK_ARN \
  --container backend \
  --interactive \
  --command "psql -h DB_ENDPOINT -U dbadmin -d translation_platform"
```

### SSL Certificate Issues

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn YOUR_CERT_ARN
```

## Cost Estimation

### Monthly Cost Breakdown (us-east-1)

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| **ECS Fargate** | 2 backend (1GB RAM), 2 frontend (512MB) | $50-70 |
| **RDS PostgreSQL** | db.t3.small, 50GB | $30-40 |
| **Application Load Balancer** | With SSL | $20-25 |
| **NAT Gateway** | 2 AZs | $60-70 |
| **Data Transfer** | Varies by usage | $10-50 |
| **CloudWatch Logs** | 30 day retention | $5-10 |
| **ECR Storage** | <10GB | $1-2 |
| **Total** | | **$176-267/month** |

### Cost Optimization Tips

1. **Use Spot Instances for non-prod**: Save up to 70%
2. **Enable RDS Auto-scaling**: Pay only for what you use
3. **Set up S3 lifecycle policies**: Reduce log storage costs
4. **Use CloudWatch Contributor Insights**: Identify costly operations
5. **Consider Reserved Instances**: 30-40% savings for predictable workloads

## Scaling

### Auto-Scaling ECS Services

```hcl
# Add to ECS module
resource "aws_appautoscaling_target" "backend" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "backend-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

## Backup and Disaster Recovery

### Database Backups

- Automated daily backups (14 day retention)
- Point-in-time recovery enabled
- Multi-AZ deployment recommended for production

### Restore from Backup

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier translation-platform-restored \
  --db-snapshot-identifier snapshot-name
```

## Updates and Maintenance

### Update Application

```bash
# Build new image
docker build -t backend:v2 ./backend

# Push to ECR
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/backend:v2

# Update service
aws ecs update-service \
  --cluster translation-platform-prod-cluster \
  --service translation-platform-prod-backend \
  --force-new-deployment
```

### Terraform Updates

```bash
cd terraform/environments/prod

# Update infrastructure
terraform plan
terraform apply
```

## Destroy Infrastructure

⚠️ **WARNING**: This will delete all resources and data!

```bash
cd terraform/environments/prod

# Destroy all resources
terraform destroy

# Type 'yes' to confirm
```

## Support and Additional Resources

- AWS ECS Documentation: https://docs.aws.amazon.com/ecs/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/
- Platform Issues: [GitHub Issues](https://github.com/yourorg/translation-platform/issues)

---

**Last Updated**: 2025-12-24
**Version**: 2.0.2
