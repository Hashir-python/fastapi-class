provider "aws" {
  region = "eu-north-1"
}

# ---------------- IAM ROLE ----------------

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-staging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------- ECS CLUSTER ----------------

resource "aws_ecs_cluster" "staging_cluster" {
  name = "fastapi-staging-cluster"
}

# ---------------- TASK DEFINITION ----------------

resource "aws_ecs_task_definition" "staging_task" {
  family                   = "fastapi-staging-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "fastapi"
      image     = "209578578300.dkr.ecr.eu-north-1.amazonaws.com/fastapi-dev:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "GROQ_API_KEY"
          value = "YOUR_STAGING_API_KEY"
        }
      ]
    }
  ])
}

# ---------------- NETWORK (same as dev) ----------------

resource "aws_vpc" "staging_vpc" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "staging_subnet" {
  vpc_id            = aws_vpc.staging_vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "eu-north-1a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.staging_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.staging_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.staging_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "staging_sg" {
  name   = "staging-sg"
  vpc_id = aws_vpc.staging_vpc.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- SERVICE ----------------

resource "aws_ecs_service" "staging_service" {
  name            = "fastapi-staging-service"
  cluster         = aws_ecs_cluster.staging_cluster.id
  task_definition = aws_ecs_task_definition.staging_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.staging_subnet.id]
    security_groups  = [aws_security_group.staging_sg.id]
    assign_public_ip = true
  }
}