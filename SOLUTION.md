# SOLUTION.md

## Overview & Rationale

The goal of this assessment is to simulate a simple messaging system using a HTTP workload while covering a broad array of AWS components to deploy the solution (networking, containers, databases, communication, observability, CI/CD pipelines by ways of Github). The app uses `hashicorp/http-echo` as a base image to demonstrate the expected application so we can focus on cloud infrastructure and operations.

## Key design decisions:
- **VPC**: 10.0.0.0/16 Allows more than enough IPs for our simulated application, Public and Private subnets implemented to maintain security scope.
- **ECS on Fargate**: Serverless container runtime with minimal overhead. Good fit for a stateless demo service with an **ALB** to handle the ingress.
- **RDS PostgreSQL**: Common relational DB in private subnets (not publicly accessible). Security groups restrict access.
- **DynamoDB**: On-demand datastore for flexible key-value/session metadata without capacity planning.
- **SQS/SNS**: Decoupled async Pub/Sub messaging services and fan-out/notifications.
- **CloudWatch**: Logs, metrics, alarms for basic observerability.
- **Terraform**: Declarative IaC which maintains state.
- **GitHub Actions**: CI/CD workflow handled using OIDC.

## Security notes
- **Least privilege IAM**:
  - ECS **execution role** scoped to ECR pulls, logs.
  - ECS **task role** scoped to DynamoDB table, SQS queue, SNS topic only (CRUD as needed).
- **Network segmentation**:
  - RDS in **private subnets** only; SG allows ingress from ECS tasks SG on 5432.
  - ALB in **public subnets** exposes only HTTP/80 inbound; forwards to ECS target group on 5678. 
- **No public DB** endpoints; NAT for egress from private subnets.

## Monitoring & alerting
- **Log groups** for ECS tasks.
- **Alarms**:
  - `RDS CPU > 80% for 5m` – catches runaway queries or sizing issues.
  - `SQS depth > 100 for 10m` – signs of backlog/ lack of resources.

## CI/CD
- **Plan**: build image, push to ECR, validate/apply Terraform, update ECS service with new task def, run health check.
- **Deployment safety**:
  - Infra changes gated by Terraform plan in PRs (extend workflow for manual approvals in prod).

## Cost optimization

**Actionable strategies**
1. **Use Fargate Spot for ECS tasks** (up to ~70% savings). *Trade-off*: Interruption risk; use for non-critical/HA stateless services.
2. **DynamoDB On-Demand** vs Provisioned with Auto Scaling based on access patterns.
3. **One NAT Gateway per AZ vs Single NAT**: Single NAT reduces cost but reduces AZ resilience.

## Future work TODOs
- Refactor Terraform and create modules for all resources, would make maintaining and readibility way better
- Add **Route53 + TLS** via ACM, HTTPS on ALB.
- Add **autoscaling** policies for ECS on CPU/ReqPerTarget.
- Blue/Green with **CodeDeploy** for zero-downtime deploys.
- RDS replica set / Multi-AZ for HA.
- Terraform **remote backend** (S3 bucket).
- Health script to send notifications to obs team on failures
- Rollback strategies for when things go wrong