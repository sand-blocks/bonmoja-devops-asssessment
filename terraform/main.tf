variable "project_name" {
  type        = string
  description = "name of the project"
  default     = "bonmoja"
}

variable "infra_environment" {
  type        = string
  description = "infrastructure environment"
  default     = "staging"
}

variable "default_region" {
  type        = string
  description = "region for resources to be located in"
  default     = "af-south-1"
}


## VPC with public/private subnets, routing tables, and a NAT gateway
module "vpc" {
  source = "./modules/vpc"

  azs               = ["${var.default_region}a", "${var.default_region}b"]
  public_subnets    = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  vpc_cidr          = "10.0.0.0/16"
  project_name      = var.project_name
  infra_environment = var.infra_environment
}

#### CM 2025-08-31 Decision made to forego using a modular design approach going forward due to time contrainst
#### TODO refactor and use modules as done with VPC

#----------------------------------------------------------------------


## ECS (Fargate) cluster running the HTTP service
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-${var.infra_environment}-ecs"
}

### Repo
resource "aws_ecr_repository" "repo" {
  name = "${var.project_name}-${var.infra_environment}-repo"
}

### Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.project_name}-${var.infra_environment}-http-echo-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name         = "${var.project_name}-${var.infra_environment}-http-echo"
    image        = aws_ecr_repository.repo.name
    essential    = true
    portMappings = [{ containerPort = 5678, hostPort = 5678 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = "af-south-1"
        awslogs-stream-prefix = "http-echo"
      }
    }
  }])
}

### Service
resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-${var.infra_environment}-http-echo-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.vpc_private_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    container_name   = "${var.project_name}-${var.infra_environment}-http-echo"
    container_port   = 5678
  }
}

### ALB
resource "aws_lb" "alb" {
  name               = "${var.project_name}-${var.infra_environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.vpc_public_subnets
}

resource "aws_lb_target_group" "alb_tg" {
  name        = "${var.project_name}-${var.infra_environment}-http-echo-tg"
  port        = 5678
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

#----------------------------------------------------------------------

## RDS (PostgreSQL) instance in private subnets

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${var.project_name}-${var.infra_environment}-rds-subnet-group"
  subnet_ids  = module.vpc.vpc_private_subnets
  description = "RDS subnet group for private subnets"
  tags = {
    Terraform   = "true"
    Environment = var.infra_environment
    Project     = var.project_name
    Type        = "RDS subnet group"
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"

  identifier = "${var.project_name}-${var.infra_environment}-postgres-rds"

  engine                 = "postgres"
  engine_version         = "17"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "bonmojadb"
  username               = "groot"
  password               = "Th!s!sN0tTh3P@ssw0rd"
  port                   = 5432
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = module.vpc.vpc_private_subnets
  family                 = "postgres17"
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Terraform   = "true"
    Environment = var.infra_environment
    Project     = var.project_name
    Type        = "RDS"
  }
}

#----------------------------------------------------------------------


## DynamoDB table (e.g., for session or metadata storage)
resource "aws_dynamodb_table" "table" {
  name         = "${var.project_name}-${var.infra_environment}-dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "_id"

  attribute {
    name = "_id"
    type = "S"
  }

  tags = {
    Terraform   = "true"
    Environment = var.infra_environment
    Project     = var.project_name
    Type        = "DynamoDB"
  }
}

#----------------------------------------------------------------------

## SQS queue 
resource "aws_sqs_queue" "queue" {
  name = "${var.project_name}-${var.infra_environment}-queue"
}

#----------------------------------------------------------------------

## SNS topic (with at least one subscription)
resource "aws_sns_topic" "topic" {
  name = "${var.project_name}-${var.infra_environment}-topic"
}

resource "aws_sns_topic_subscription" "sub" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = "charlinmartin@gmail.com"
}

#----------------------------------------------------------------------

## IAM roles and policies following least-privilege principles
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-${var.infra_environment}-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.infra_environment}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage", "sns:Publish"]
      Resource = ["*"] # Tighten in prod
    }]
  })
}

#----------------------------------------------------------------------

## Security groups and access control between components
resource "aws_security_group" "alb" {
  name   = "${var.project_name}-${var.infra_environment}-ralb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "ecs" {
  name   = "${var.project_name}-${var.infra_environment}-ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5678
    to_port         = 5678
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.project_name}-${var.infra_environment}-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
}

#----------------------------------------------------------------------


## CloudWatch log groups for ECS service
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${var.project_name}-${var.infra_environment}/ecs/http-echo"
  retention_in_days = 3
}

### CloudWatch Alarms

#### RDS CPU usage > 80% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.infra_environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU >80% for 5min"
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
}

#### SQS queue depth > 100 messages for 10 minutes

resource "aws_cloudwatch_metric_alarm" "sqs_depth" {
  alarm_name          = "${var.project_name}-${var.infra_environment}-sqs-high-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 600
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "SQS depth >100 for 10min"
  dimensions = {
    QueueName = aws_sqs_queue.queue.name
  }
}

output "alb_dns" {
  value = aws_lb.alb.dns_name
}