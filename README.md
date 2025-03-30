# AWS ECS Nginx Deployment

This project sets up a containerized nginx environment on AWS using Terraform, meeting the requirements for a basic containerized environment using AWS free tier resources.

## Architecture

The infrastructure includes:

- VPC with single AZ networking
- ECR repository for storing container images
- ECS cluster with EC2 launch type (t2.micro instances)
- Auto Scaling Group for the ECS instances
- CloudWatch monitoring for CPU/memory metrics
- Security groups, IAM roles, and policies

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or later)
- [Docker](https://www.docker.com/get-started) (for building and pushing container images)

## Project Structure

```
├── app/                # Express.js application files (for future enhancement)
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

## Setup Instructions

### 1. Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 2. Push Nginx Image to ECR

After the Terraform deployment is complete, you'll see outputs including ECR push commands. Run these commands to push the nginx image to your ECR repository:

```bash
# Log in to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Pull the latest nginx image
docker pull nginx:latest

# Tag the image
docker tag nginx:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/nginx-app:latest

# Push the image
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/nginx-app:latest
```

## Verify Deployment

### 1. Check EC2 Instance

1. Go to the AWS EC2 console
2. Check that a t2.micro instance is running
3. It should be in the us-east-1a availability zone
4. The instance should have the tag "Name: ecs-instance"

### 2. Check ECS Cluster

1. Go to the AWS ECS console
2. Verify the "nginx-cluster" is active
3. Check that the "nginx-service" service is running
4. Verify tasks are in the RUNNING state

### 3. Verify Nginx Service

1. Find the public IP of your EC2 instance in the EC2 console
2. Open a browser and navigate to http://<EC2-PUBLIC-IP>
3. You should see the nginx welcome page

### 4. Check CloudWatch Monitoring

1. Go to the CloudWatch console
2. Navigate to Dashboards and select "ecs-nginx-dashboard"
3. Verify that CPU and memory metrics are being collected
4. Check the alarms section to see the CPU and memory alarms

## Auto-Scaling Configuration

This deployment includes auto-scaling based on CPU utilization:

- Scale up when CPU exceeds 80% for 2 consecutive periods of 60 seconds
- Scale down when CPU is below 20% for 3 consecutive periods of 120 seconds
- The Auto Scaling Group has a minimum size of 1 and a maximum size of 2

## Future Enhancements

The `app` directory contains a custom Express.js application that could be used in the future to:

- Replace the default nginx with a custom application
- Add a CPU-intensive endpoint for better testing of auto-scaling
- Implement health checks and custom routing

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
