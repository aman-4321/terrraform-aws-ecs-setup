output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.main_subnet.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ecs_sg.id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.nginx_repo.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "ecr_push_commands" {
  description = "Commands to push an image to the ECR repository"
  value       = <<-EOT
    # Authentication command
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.nginx_repo.repository_url}
    
    # Pull the latest nginx image
    docker pull nginx:latest
    
    # Tag the image
    docker tag nginx:latest ${aws_ecr_repository.nginx_repo.repository_url}:latest
    
    # Push the image
    docker push ${aws_ecr_repository.nginx_repo.repository_url}:latest
  EOT
}

output "verification_instructions" {
  description = "Instructions to verify the deployment"
  value       = <<-EOT
    1. Check your EC2 instances:
       - Go to AWS EC2 console and verify the instance is running
       - It should be a t2.micro in the ${var.availability_zone} availability zone
    
    2. Check your ECS cluster:
       - Go to the ECS console and check that the cluster "${var.ecs_cluster_name}" is active
       - Verify the service "${var.service_name}" is running
       - Check that tasks are in the RUNNING state
    
    3. Check the nginx container:
       - Find the public IP of your EC2 instance in the EC2 console
       - Open a browser and navigate to http://<EC2-PUBLIC-IP>
       - You should see the nginx welcome page
    
    4. Check CloudWatch metrics:
       - Go to CloudWatch console
       - Check the ECS metrics for cluster "${var.ecs_cluster_name}"
       - Verify that CPU and memory metrics are being collected
  EOT
}

output "cleanup_instructions" {
  description = "Instructions to clean up resources and avoid charges"
  value       = <<-EOT
    To avoid unexpected AWS charges, run the following command to destroy all resources:
    
    terraform destroy -auto-approve
    
    This will remove:
    - EC2 instances
    - ECS cluster and services
    - ECR repository
    - VPC and all networking components
    - IAM roles and policies
    - CloudWatch alarms
    
    Alternatively, you can manually delete resources in the AWS console in this order:
    1. ECS Services
    2. ECS Tasks
    3. Auto Scaling Group
    4. EC2 Instances
    5. ECS Cluster
    6. ECR Repository (delete images first)
    7. CloudWatch Alarms
    8. IAM Roles and Instance Profiles
    9. Security Groups
    10. Route Tables, Internet Gateway, Subnets, VPC
  EOT
}
