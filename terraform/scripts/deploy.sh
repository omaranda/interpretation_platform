#!/bin/bash

# Translation Platform AWS Deployment Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-prod}
AWS_REGION=${2:-us-east-1}

echo -e "${GREEN}🚀 Translation Platform AWS Deployment${NC}"
echo -e "${GREEN}Environment: $ENVIRONMENT${NC}"
echo -e "${GREEN}Region: $AWS_REGION${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install it first.${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS Account ID: $AWS_ACCOUNT_ID${NC}"
echo ""

# Navigate to environment directory
cd "$(dirname "$0")/../environments/$ENVIRONMENT"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}❌ terraform.tfvars not found!${NC}"
    echo -e "${YELLOW}Please copy terraform.tfvars.example to terraform.tfvars and configure it.${NC}"
    exit 1
fi

# Initialize Terraform
echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
terraform init

# Validate configuration
echo -e "${YELLOW}✓ Validating Terraform configuration...${NC}"
terraform validate

# Plan deployment
echo -e "${YELLOW}📝 Planning deployment...${NC}"
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

# Apply Terraform
echo -e "${YELLOW}🏗️  Deploying infrastructure...${NC}"
terraform apply tfplan

# Get ECR repository URLs
echo -e "${YELLOW}📦 Getting ECR repository URLs...${NC}"
BACKEND_REPO=$(terraform output -raw ecr_repository_urls | jq -r '.backend')
FRONTEND_REPO=$(terraform output -raw ecr_repository_urls | jq -r '.frontend')

echo "Backend ECR: $BACKEND_REPO"
echo "Frontend ECR: $FRONTEND_REPO"
echo ""

# Build and push Docker images
echo -e "${YELLOW}🐳 Building and pushing Docker images...${NC}"

# ECR login
echo -e "${YELLOW}🔐 Logging into ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push backend
echo -e "${YELLOW}🔨 Building backend...${NC}"
cd ../../../../backend
docker build -t $BACKEND_REPO:latest .
docker push $BACKEND_REPO:latest

# Build and push frontend
echo -e "${YELLOW}🔨 Building frontend...${NC}"
cd ../frontend
docker build -t $FRONTEND_REPO:latest .
docker push $FRONTEND_REPO:latest

# Get cluster and service names
cd ../terraform/environments/$ENVIRONMENT
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
BACKEND_SERVICE=$(terraform output -raw backend_service_name)
FRONTEND_SERVICE=$(terraform output -raw frontend_service_name)

# Update ECS services
echo -e "${YELLOW}🔄 Updating ECS services...${NC}"
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $BACKEND_SERVICE \
    --force-new-deployment \
    --region $AWS_REGION

aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $FRONTEND_SERVICE \
    --force-new-deployment \
    --region $AWS_REGION

# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${GREEN}📊 Deployment Information:${NC}"
echo -e "  Frontend: $(terraform output -raw frontend_url)"
echo -e "  Backend:  $(terraform output -raw backend_url)"
echo -e "  Jitsi:    $(terraform output -raw jitsi_url)"
echo ""
echo -e "${GREEN}🔗 ALB DNS: $ALB_DNS${NC}"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo "  1. Configure DNS CNAME records to point to: $ALB_DNS"
echo "  2. Wait for DNS propagation (5-60 minutes)"
echo "  3. Test the application"
echo ""
echo -e "${GREEN}🎉 Deployment successful!${NC}"
