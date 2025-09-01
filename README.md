# bonmoja-devops-asssessment
Assessment for bonmoja devops cicd pipeline

```mermaid
graph TD
  %% Style
  classDef aws fill=#FF9900,stroke=#232F3E,stroke-width=1px,color=#fff,font-weight:bold;
  classDef network fill=#146EB4,stroke=#232F3E,stroke-width=1px,color=#fff,font-weight:bold;
  classDef db fill=#4DB33D,stroke=#232F3E,stroke-width=1px,color=#fff,font-weight:bold;
  classDef queue fill=#FFCC00,stroke=#232F3E,stroke-width=1px,color=#000,font-weight:bold;
  classDef security fill=#DD2C00,stroke=#232F3E,stroke-width=1px,color=#fff,font-weight:bold;

  %% VPC Cluster
  subgraph VPCCluster[VPC 10.0.0.0/16]
    VPC[VPC]:::network
    PublicSubnets[Public Subnets<br/>10.0.101.0/24, 10.0.102.0/24]:::network
    PrivateSubnets[Private Subnets<br/>10.0.1.0/24, 10.0.2.0/24]:::network
    VPC --> PublicSubnets
    VPC --> PrivateSubnets
  end

  %% ALB Cluster
  subgraph ALBCluster[Load Balancing]
    ALB[Application Load Balancer]:::aws
    SGALB[SG: ALB]:::security
    ALB --> SGALB
  end

  %% ECS Cluster
  subgraph ECSClusterGroup[ECS (Fargate)]
    ECSCluster[ECS Cluster]:::aws
    ECSService[ECS Service]:::aws
    ECSTask[ECS Task: http-echo]:::aws
    SGECS[SG: ECS]:::security
    ECSCluster --> ECSService
    ECSService --> ECSTask
    ECSService --> SGECS
  end

  %% RDS Cluster
  subgraph RDSCluster[Database Layer]
    RDS[(RDS PostgreSQL)]:::db
    SGRDS[SG: RDS]:::security
    RDS --> SGRDS
  end

  %% Other Services Cluster
  subgraph OtherServices[Supporting Services]
    DDB[(DynamoDB Table)]:::db
    SQS[(SQS Queue)]:::queue
    SNS[(SNS Topic)]:::queue
    Email[Email Subscription<br/>charlinmartin@gmail.com]
    SNS --> Email
  end

  %% IAM Cluster
  subgraph IAMCluster[Security & IAM]
    IAMExec[IAM Role: ECS Execution]:::security
    IAMTask[IAM Role: ECS Task]:::security
    ECSTask --> IAMExec
    ECSTask --> IAMTask
  end

  %% CloudWatch Cluster
  subgraph Monitoring[Monitoring & Logging]
    CWLogs[CloudWatch Logs]:::aws
    CWAlarmRDS[Alarm: RDS CPU > 80%]:::aws
    CWAlarmSQS[Alarm: SQS Depth > 100]:::aws
    ECSService --> CWLogs
    RDS --> CWAlarmRDS
    SQS --> CWAlarmSQS
  end

  %% Outputs
  Output[Output: ALB DNS]:::aws
  ALB --> Output

  %% Connections
  PublicSubnets --> ALB
  PrivateSubnets --> ECSCluster
  PrivateSubnets --> RDS
  ALB --> ECSService
  ECSService --> RDS
  ECSService --> DDB
  ECSService --> SQS
  ECSService --> SNS
  ```
