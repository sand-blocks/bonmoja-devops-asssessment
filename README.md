# bonmoja-devops-asssessment
Assessment for bonmoja devops cicd pipeline

```mermaid
flowchart LR

  %% VPC
  subgraph VPC
    PublicSubnets["Public Subnets 10.0.101.0/24, 10.0.102.0/24"]
    PrivateSubnets["Private Subnets 10.0.1.0/24, 10.0.2.0/24"]
  end

  %% Load Balancer
  subgraph Load_Balancing
    ALB["Application Load Balancer"]
  end

  %% ECS
  subgraph ECS
    ECSCluster["ECS Cluster"]
    ECSService["ECS Service"]
    ECSTask["ECS Task http-echo"]
  end

  %% Database
  subgraph Database
    RDS["RDS PostgreSQL"]
  end

  %% Messaging and Storage
  subgraph Messaging_Storage
    DDB["DynamoDB Table"]
    SQS["SQS Queue"]
    SNS["SNS Topic"]
    Email["Email Subscription charlinmartin@gmail.com"]
  end

  %% Security
  subgraph Security
    SGALB["Security Group ALB"]
    SGECS["Security Group ECS"]
    SGRDS["Security Group RDS"]
    IAMExec["IAM Role ECS Execution"]
    IAMTask["IAM Role ECS Task"]
  end

  %% Monitoring
  subgraph Monitoring
    CWLogs["CloudWatch Logs"]
    AlarmRDS["Alarm RDS CPU > 80%"]
    AlarmSQS["Alarm SQS Depth > 100"]
  end

  %% Connections
  PublicSubnets --> ALB
  ALB -->|HTTP 80| ECSService

  PrivateSubnets --> ECSCluster
  PrivateSubnets --> RDS

  ECSCluster --> ECSService
  ECSService --> ECSTask

  ALB --> SGALB
  ECSService --> SGECS
  RDS --> SGRDS

  ECSService --> RDS
  ECSService --> DDB
  ECSService --> SQS
  ECSService --> SNS
  SNS --> Email

  ECSTask --> IAMExec
  ECSTask --> IAMTask

  ECSService --> CWLogs
  RDS --> AlarmRDS
  SQS --> AlarmSQS

  Output["Output ALB DNS"]
  ALB --> Output

  ```
