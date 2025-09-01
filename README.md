# bonmoja-devops-asssessment
Assessment for bonmoja devops cicd pipeline

```graph TB
    %% Internet and External Access
    Internet([Internet])
    
    %% VPC and Networking
    subgraph VPC["VPC (10.0.0.0/16)"]
        subgraph AZ1["Availability Zone A"]
            PubSub1["Public Subnet<br/>10.0.101.0/24"]
            PrivSub1["Private Subnet<br/>10.0.1.0/24"]
        end
        
        subgraph AZ2["Availability Zone B"]
            PubSub2["Public Subnet<br/>10.0.102.0/24"]
            PrivSub2["Private Subnet<br/>10.0.2.0/24"]
        end
        
        %% NAT Gateway
        NAT["NAT Gateway"]
        IGW["Internet Gateway"]
    end
    
    %% Load Balancer
    ALB["Application Load Balancer<br/>(Port 80)"]
    
    %% ECS Components
    subgraph ECS["ECS Cluster"]
        Service["ECS Service<br/>(Fargate)"]
        Task["Task Definition<br/>(http-echo container)"]
        ECR["ECR Repository"]
    end
    
    %% Database
    RDS["RDS PostgreSQL<br/>(db.t3.micro)<br/>Port 5432"]
    
    %% Storage and Messaging
    DynamoDB["DynamoDB Table<br/>(Pay-per-request)"]
    SQS["SQS Queue"]
    SNS["SNS Topic"]
    Email["📧 charlinmartin@gmail.com"]
    
    %% Monitoring
    subgraph CloudWatch["CloudWatch"]
        LogGroup["Log Group<br/>/ecs/http-echo"]
        RDSAlarm["RDS CPU Alarm<br/>(>80% for 5min)"]
        SQSAlarm["SQS Depth Alarm<br/>(>100 for 10min)"]
    end
    
    %% Security Groups
    subgraph Security["Security Groups"]
        ALBSG["ALB Security Group<br/>(HTTP:80 from 0.0.0.0/0)"]
        ECSSG["ECS Security Group<br/>(Port 5678 from ALB)"]
        RDSSG["RDS Security Group<br/>(Port 5432 from ECS)"]
    end
    
    %% IAM Roles
    subgraph IAM["IAM Roles"]
        ExecRole["ECS Execution Role<br/>(ECR, CloudWatch)"]
        TaskRole["ECS Task Role<br/>(SQS, SNS)"]
    end
    
    %% Connections
    Internet --> IGW
    IGW --> ALB
    ALB --> PubSub1
    ALB --> PubSub2
    
    NAT --> PubSub1
    PrivSub1 --> NAT
    PrivSub2 --> NAT
    
    ALB --> Service
    Service --> PrivSub1
    Service --> PrivSub2
    Service --> Task
    Task --> ECR
    
    Service --> RDS
    RDS --> PrivSub1
    RDS --> PrivSub2
    
    Task --> SQS
    Task --> SNS
    SNS --> Email
    
    Service --> LogGroup
    RDS --> RDSAlarm
    SQS --> SQSAlarm
    
    %% Security Group Associations
    ALB -.-> ALBSG
    Service -.-> ECSSG
    RDS -.-> RDSSG
    
    %% IAM Role Associations
    Task -.-> ExecRole
    Task -.-> TaskRole
    
    %% Styling
    classDef aws fill:#ff9900,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef network fill:#4a90e2,stroke:#2c5aa0,stroke-width:2px,color:#fff
    classDef compute fill:#00c851,stroke:#007e33,stroke-width:2px,color:#fff
    classDef storage fill:#ff6b6b,stroke:#cc5252,stroke-width:2px,color:#fff
    classDef security fill:#ffc107,stroke:#e0a800,stroke-width:2px,color:#000
    classDef monitoring fill:#6f42c1,stroke:#59359a,stroke-width:2px,color:#fff
    
    class VPC,PubSub1,PubSub2,PrivSub1,PrivSub2,NAT,IGW network
    class ECS,Service,Task,ECR,ALB compute
    class RDS,DynamoDB,SQS,SNS storage
    class Security,ALBSG,ECSSG,RDSSG,IAM,ExecRole,TaskRole security
    class CloudWatch,LogGroup,RDSAlarm,SQSAlarm monitoring
```
