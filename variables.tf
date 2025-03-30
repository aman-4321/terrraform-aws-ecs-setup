variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type for ECS"
  type        = string
  default     = "t2.micro"
}

variable "ecs_ami" {
  description = "AMI ID for ECS optimized instances"
  type        = string
  default     = "ami-0c7217cdde317cfec" # ECS-optimized AMI for us-east-1
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "nginx-cluster"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "nginx-app"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "nginx-service"
}

variable "cpu_threshold" {
  description = "CPU threshold for CloudWatch alarm"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the ECS task in MiB"
  type        = string
  default     = "512"
}
