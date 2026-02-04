#!/bin/bash

# AWS Infrastructure Setup Script
# This script helps you set up the required AWS resources for deployment

set -e

echo "🚀 Setting up AWS infrastructure for Nihongo E-commerce..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    echo "Visit: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    exit 1
fi

# Variables
PROJECT_NAME="nihongo-ecom"
AWS_REGION="${AWS_REGION:-us-west-2}"
BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"

echo "📋 Configuration:"
echo "   Project Name: $PROJECT_NAME"
echo "   AWS Region: $AWS_REGION"
echo "   S3 Bucket: $BUCKET_NAME"
echo ""

# Create S3 bucket for Terraform state
echo "🪣 Creating S3 bucket for Terraform state..."
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name "${PROJECT_NAME}-terraform-locks" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $AWS_REGION

# Create ECR repository
echo "🐳 Creating ECR repository..."
aws ecr create-repository \
    --repository-name $PROJECT_NAME \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true

# Wait for DynamoDB table to be active
echo "⏳ Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists --table-name "${PROJECT_NAME}-terraform-locks" --region $AWS_REGION

echo "✅ AWS infrastructure setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Update terraform/main.tf backend configuration with:"
echo "   bucket = \"$BUCKET_NAME\""
echo "   key    = \"$PROJECT_NAME/terraform.tfstate\""
echo "   region = \"$AWS_REGION\""
echo "   dynamodb_table = \"${PROJECT_NAME}-terraform-locks\""
echo ""
echo "2. Copy terraform/terraform.tfvars.example to terraform/terraform.tfvars"
echo "3. Update the values in terraform.tfvars"
echo "4. Run: cd terraform && terraform init"
echo "5. Run: terraform plan"
echo "6. Run: terraform apply"
echo ""
echo "🔐 Remember to set up these GitHub Secrets:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - DB_PASSWORD"
echo "   - RAILS_MASTER_KEY"
