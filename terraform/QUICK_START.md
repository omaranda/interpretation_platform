# Terraform Quick Start Guide

## 🚀 Deploy to AWS in 5 Steps

### Prerequisites
```bash
# Install required tools
brew install terraform awscli
aws configure  # Enter your AWS credentials
```

### Step 1: Request SSL Certificate
```bash
# Go to AWS Certificate Manager (ACM)
# Request certificate for: *.yourdomain.com
# Use DNS validation
# Wait for "Issued" status
```

### Step 2: Configure Variables
```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
vim terraform.tfvars
```

Required values:
```hcl
frontend_url        = "app.yourdomain.com"
backend_url         = "api.yourdomain.com"
jitsi_domain        = "meet.yourdomain.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT_ID"
database_password   = "STRONG_PASSWORD"
jwt_secret_key      = "RANDOM_SECRET"  # openssl rand -base64 32
```

### Step 3: Deploy Infrastructure
```bash
# Automated deployment (recommended)
cd ../..
./scripts/deploy.sh prod us-east-1

# OR manual deployment
cd environments/prod
terraform init
terraform plan
terraform apply
```

### Step 4: Configure DNS
Create CNAME records pointing to ALB DNS:

```
app.yourdomain.com  → CNAME → translation-platform-prod-alb-xxx.elb.amazonaws.com
api.yourdomain.com  → CNAME → translation-platform-prod-alb-xxx.elb.amazonaws.com
meet.yourdomain.com → CNAME → translation-platform-prod-alb-xxx.elb.amazonaws.com
```

### Step 5: Verify Deployment
```bash
# Check services
aws ecs describe-services --cluster translation-platform-prod-cluster \
  --services translation-platform-prod-backend translation-platform-prod-frontend

# Test endpoints
curl https://api.yourdomain.com/health
curl https://app.yourdomain.com

# View logs
aws logs tail /ecs/translation-platform-prod/backend --follow
```

## 📊 What Gets Created

| Resource | Type | Purpose |
|----------|------|---------|
| VPC | Network | Isolated network infrastructure |
| 2x Public Subnets | Network | ALB placement |
| 2x Private Subnets | Network | ECS tasks and RDS |
| 2x NAT Gateways | Network | Outbound internet for private subnets |
| Application Load Balancer | Load Balancer | HTTPS routing |
| ECS Cluster | Compute | Container orchestration |
| 2x Backend Tasks | Compute | FastAPI containers |
| 2x Frontend Tasks | Compute | Next.js containers |
| RDS PostgreSQL | Database | Managed PostgreSQL |
| 6x ECR Repositories | Registry | Docker images |
| CloudWatch Logs | Monitoring | Application logs |
| Security Groups | Security | Network access control |
| IAM Roles | Security | Service permissions |

## 💰 Estimated Monthly Cost

| Component | Cost |
|-----------|------|
| ECS Fargate (4 tasks) | $50-70 |
| RDS db.t3.small | $30-40 |
| ALB | $20-25 |
| NAT Gateway (2 AZs) | $60-70 |
| Data Transfer | $10-50 |
| **Total** | **~$170-255/month** |

## 🔄 Common Commands

### Update Application
```bash
# Build and push new images
docker build -t backend:latest ./backend
aws ecr get-login-password | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com
docker tag backend:latest ACCOUNT.dkr.ecr.REGION.amazonaws.com/translation-platform-prod-backend:latest
docker push ACCOUNT.dkr.ecr.REGION.amazonaws.com/translation-platform-prod-backend:latest

# Force new deployment
aws ecs update-service --cluster CLUSTER --service SERVICE --force-new-deployment
```

### View Logs
```bash
aws logs tail /ecs/translation-platform-prod/backend --follow
aws logs tail /ecs/translation-platform-prod/frontend --follow
```

### Scale Services
```bash
# Increase backend to 4 tasks
aws ecs update-service --cluster CLUSTER --service BACKEND_SERVICE --desired-count 4
```

### Database Access
```bash
# Get database endpoint
terraform output database_endpoint

# Connect via psql (from bastion or local with VPN)
psql -h DB_ENDPOINT -U dbadmin -d translation_platform
```

## 🧹 Cleanup

```bash
cd terraform/environments/prod
terraform destroy  # WARNING: Deletes everything!
```

## 📚 Full Documentation

- **Complete Guide**: [docs/AWS_DEPLOYMENT.md](../../docs/AWS_DEPLOYMENT.md)
- **Terraform Docs**: [terraform/README.md](../README.md)
- **Troubleshooting**: [docs/AWS_DEPLOYMENT.md#troubleshooting](../../docs/AWS_DEPLOYMENT.md#troubleshooting)

## 🆘 Quick Troubleshooting

### Services Won't Start
```bash
# Check events
aws ecs describe-services --cluster CLUSTER --services SERVICE

# Check logs
aws logs tail /ecs/translation-platform-prod/backend --since 10m
```

### Database Connection Failed
```bash
# Verify security groups allow ECS → RDS
aws ec2 describe-security-groups --filters "Name=group-name,Values=*rds*"
```

### Certificate Issues
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn CERT_ARN
```

---

**Need Help?** See [docs/AWS_DEPLOYMENT.md](../../docs/AWS_DEPLOYMENT.md) for detailed documentation.
