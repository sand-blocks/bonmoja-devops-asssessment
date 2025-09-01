# bonmoja-devops-asssessment
Assessment for bonmoja devops cicd pipeline

```mermaid
graph TD

  %% VPC
  subgraph VPCCluster[VPC 10.0.0.0/16]
    VPC[VPC]
    PublicSubnets[Public Subnets: 10.0.101.0/24, 10.0.102.0/24]
    PrivateSubnets[Private Subnets: 10.0.1.0/24, 10.0.2.0/24]
    VPC --> PublicSubnets
    VPC --> PrivateSubnets
  end

  %% ALB
  subgraph ALBCluster[Load Balancer]
    ALB[Application Load Balancer]
    SGALB[Security Group: ALB]
    ALB --> SGALB
  end

  %% ECS
  subgraph ECSClusterGroup[ECS Fargate]
    ECSCluster[ECS Cluster]
    ECSService[ECS Service]
    ECSTask[ECS Task http-echo]
    SGECS[Security Group: ECS]
    ECSCluster --> ECSService
    ECSService --> ECSTask
    ECSService --> SGECS
  end

  %% RDS
  subgraph RDSCluster[Database Layer]
    RDS[RDS PostgreSQL]
    SGRDS[Security Group: RDS]
    RDS --> SGRDS
  end

  %% Other Services
  subgraph OtherServices[Other Services]
    DDB[DynamoDB Table]
    SQS[SQS Queue]
    SNS[SNS Topic]
    Email[Email Subscription: charlinmartin@gmail.com]
    SNS --> Email
  end

  %% IAM
  subgraph IAMCluster[IAM Roles]
    IAMExec[IAM Role: ECS Execution]
    IAMTask[IAM Role: ECS Task]
    ECSTask --> IAMExec
    ECSTask --> IAMTask
  end

  %% CloudWatch
  subgraph Monitoring[Monitoring and Logs]
    CWLogs[CloudWatch Logs]
    CWAlarmRDS[Alarm RDS CPU > 80%]
    CWAlarmSQS[Alarm SQS Depth > 100]
    ECSService --> CWLogs
    RDS --> CWAlarmRDS
    SQS --> CWAlarmSQS
  end

  %% Output
  Output[Output: ALB DNS]
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
