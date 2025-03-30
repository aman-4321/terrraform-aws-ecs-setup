# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.ecs_cluster_name
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx-container"
      image     = "${aws_ecr_repository.nginx_repo.repository_url}:latest"
      cpu       = tonumber(var.task_cpu)
      memory    = tonumber(var.task_memory)
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/nginx-task"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "nginx-task"
  }
}

# Launch Template for EC2 instances
resource "aws_launch_template" "ecs_launch_template" {
  name_prefix            = "ecs-launch-template"
  image_id               = var.ecs_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
  # Amazon ECS-optimized AMIs already have Docker and the ECS agent
  echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
  echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
  systemctl restart ecs
EOF
  )

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ecs-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "ecs-asg"
  vpc_zone_identifier = [aws_subnet.main_subnet.id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1 # Set max_size to 1 to ensure we stay within free tier limits

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "capacity-provider-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }

  tags = {
    Name = "capacity-provider-ec2"
  }
}

# Associate the capacity provider with the cluster
resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_providers" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 100
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/nginx-task"
  retention_in_days = 7

  tags = {
    Name = "ecs-logs"
  }
}

# ECS Service
resource "aws_ecs_service" "nginx_service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 100
  }

  # Allow the service to be deployed even if it doesn't initially reach a steady state
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  timeouts {
    delete = "30m"
  }

  tags = {
    Name = var.service_name
  }

  # Wait for capacity provider and auto scaling group
  depends_on = [
    aws_ecs_cluster_capacity_providers.cluster_capacity_providers,
    aws_autoscaling_group.ecs_asg
  ]
}
