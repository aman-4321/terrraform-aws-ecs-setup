# AWS ECS Next.js Deployment

This project sets up a containerized Next.js environment on AWS using Terraform, meeting the requirements for a basic containerized environment using AWS free tier resources. It includes CI/CD pipelines using GitHub Actions for automated builds and deployments.

## Architecture

The infrastructure includes:

- VPC with single AZ networking
- ECR repository for storing container images
- ECS cluster with EC2 launch type (t2.micro instances)
- Auto Scaling Group for the ECS instances
- CloudWatch monitoring for CPU/memory metrics
- Security groups, IAM roles, and policies
- GitHub Actions workflows for CI/CD

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or later)
- [Docker](https://www.docker.com/get-started) (for building and pushing container images)
- [GitHub repository](https://github.com) with the source code
- AWS credentials set as GitHub secrets

## Project Structure

```
├── .github/workflows/  # GitHub Actions workflow files
│   ├── build.yml       # Workflow for building the Docker image
│   └── deploy.yml      # Workflow for deploying to ECR and ECS
├── next-app/           # Next.js application files
│   └── Dockerfile      # Dockerfile for the Next.js application
├── main.tf             # Provider configuration
├── variables.tf        # Variable declarations
├── outputs.tf          # Output definitions
├── networking.tf       # VPC, subnet, route tables, etc.
├── security.tf         # Security groups, IAM roles
├── ecr.tf              # ECR repository resources
├── ecs.tf              # ECS cluster, task definitions, services
├── monitoring.tf       # CloudWatch resources
└── README.md           # Project documentation
```

## CI/CD Setup

### GitHub Secrets

Add the following secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: The AWS region you're deploying to (e.g., us-east-1)

### Workflows

1. **Build Workflow** (`.github/workflows/build.yml`)

   - Triggers on pushes to the `main` branch that affect the `next-app` directory
   - Builds the Docker image from the Dockerfile
   - Stores the image as an artifact

2. **Deploy Workflow** (`.github/workflows/deploy.yml`)
   - Triggers when the build workflow completes successfully
   - Configures AWS credentials
   - Downloads the Docker image artifact
   - Tags and pushes the image to Amazon ECR
   - Forces a new deployment on the ECS service

## Terraform Setup

### 1. Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 2. Commit and Push Changes

After the Terraform deployment is complete, any changes pushed to the `next-app` directory will trigger the CI/CD pipeline:

1. The build workflow will build the Docker image
2. The deploy workflow will push the image to ECR and update the ECS service
3. The ECS service will pull the new image and deploy it

## Verify Deployment

### 1. Check GitHub Actions

1. Go to your GitHub repository
2. Navigate to the "Actions" tab
3. Verify that the workflows are running successfully

### 2. Check EC2 Instance

1. Go to the AWS EC2 console
2. Check that a t2.micro instance is running
3. It should be in the us-east-1a availability zone
4. The instance should have the tag "Name: ecs-instance"

### 3. Check ECS Cluster

1. Go to the AWS ECS console
2. Verify the "nginx-cluster" is active
3. Check that the "nginx-service" service is running
4. Verify tasks are in the RUNNING state

### 4. Verify Next.js Service

1. Find the public IP of your EC2 instance in the EC2 console
2. Open a browser and navigate to http://<EC2-PUBLIC-IP>
3. You should see your Next.js application

## Auto-Scaling Configuration

This deployment includes auto-scaling based on CPU utilization:

- Scale up when CPU exceeds 80% for 2 consecutive periods of 60 seconds
- Scale down when CPU is below 20% for 3 consecutive periods of 120 seconds
- The Auto Scaling Group has a minimum size of 1 and a maximum size of 2

## Manual Deployment (if needed)

If you need to manually push an image to ECR:

```bash
# Log in to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build the Next.js application image
cd next-app
docker build -t next-app:latest .

# Tag the image
docker tag next-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/nginx-app:latest

# Push the image
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/nginx-app:latest
```

## Cleanup Instructions

To avoid unexpected AWS charges, clean up the resources when you're done:

```bash
# Destroy all resources
terraform destroy
```

This will remove:

- EC2 instances
- ECS cluster and services
- ECR repository (and images)
- VPC and all networking components
- IAM roles and policies
- CloudWatch alarms and dashboard

## Cost Awareness

This deployment uses AWS free tier eligible resources:

- t2.micro EC2 instances
- Basic CloudWatch monitoring
- ECR repository (with limited storage)
- ECS (which is free, you only pay for the underlying resources)

Always monitor your AWS Billing Dashboard to avoid unexpected charges.
