# bonmoja-devops-asssessment
Assessment for bonmoja devops cicd pipeline

```mermaid
graph TD
  %% Simple styles
  classDef network fill=#D6EAF8,stroke=#2980B9,stroke-width=1px;
  classDef compute fill=#FADBD8,stroke=#C0392B,stroke-width=1px;
  classDef db fill=#D5F5E3,stroke=#27AE60,stroke-width=1px;
  classDef queue fill=#FCF3CF,stroke=#F1C40F,stroke-width=1px;
  classDef security fill=#F5EEF8,stroke=#8E44AD,stroke-width=1px;
  classDef monitoring fill=#EBDEF0,stroke=#7D3C98,stroke-width=1px;

  %% VPC Cluster
  subgraph VPCCluster[VPC 10.0.0.0/16]
    VPC[VPC]:::network
    PublicSubnets[Public Subnets<br/>10.0.101.0/24, 10.0.102.0/24]:::network
    PrivateSubnets[Private Subnets<br/>10.0.1.0/24, 10.0.2.0/24]:::network
    VPC --> PublicSubnets
    VPC --> PrivateSubnets
  end

  %% ALB Cluster
  subgraph ALBCluster[Load Balancer]
    ALB[Application Load Balancer]:::compute
    SGALB[SG: ALB]:::security
    ALB --> SGALB
  end

  %% ECS Cluster
  subgraph ECSClusterGroup[ECS (Fargate)]
    ECSCluster[ECS Cluster]:::compute
    ECSService[ECS Service]:::compute
    ECSTask[ECS Task: http-echo]:::compute
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

  %% Other Services
  subgraph OtherServices[Other Services]
    DDB[(DynamoDB Table)]:::db
    SQS[(SQS Queue)]:::queue
    SNS[(SNS Topic)]:::queue
    Email[Email Subscription<br/>charlinmartin@gmail.com]
    SNS --> Email
  end

  %% IAM
  subgraph IAMCluster[IAM Roles]
    IAMExec[IAM Role: ECS Execution]:::security
    IAMTask[IAM Role: ECS Task]:::security
    ECSTask --> IAMExec
    ECSTask --> IAMTask
  end

  %% CloudWatch
  subgraph Monitoring[Monitoring & Logs]
    CWLogs[CloudWatch Logs]:::monitoring
    CWAlarmRDS[Alarm: RDS CPU > 80%]:::monitoring
    CWAlarmSQS[Alarm: SQS Depth > 100]:::monitoring
    ECSService --> CWLogs
    RDS --> CWAlarmRDS
    SQS --> CWAlarmSQS
  end

  %% Output
  Output[Output: ALB DNS]:::compute
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
