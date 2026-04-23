# Automatic Data Generation in AWS

This module automatically generates synthetic AML data on AWS using scheduled serverless workflows.  
It creates Customers, Accounts, Transactions, and Alerts datasets and stores them in S3 for downstream processing.

<img width="1921" height="1281" alt="Image" src="https://github.com/user-attachments/assets/71ba18c1-c1bf-4020-8050-4a862a21fa0e" />
<img width="1919" height="971" alt="Image" src="https://github.com/user-attachments/assets/18f0f67f-4d94-47a7-8afd-3c0cc1a5ee7a" />
<img width="286" height="304" alt="Image" src="https://github.com/user-attachments/assets/f88b2b30-097b-4937-b9b1-b052d691e97e" />


# Architecture Overview

The system uses:

- AWS EventBridge (Scheduling)
- AWS Lambda (Data generation)
- AWS Step Functions (Workflow orchestration)
- AWS S3 (Storage)

Two pipelines run:

1. Entity Generation Pipeline (Customers & Accounts)
2. AML Pipeline (Transactions & Alerts)

---

# Data Flow

## 1. Entity Generator (Every 5 minutes)

EventBridge → Lambda → S3

- EventBridge triggers `Entities-Generator`
- Lambda generates:
  - Customers CSV
  - Accounts CSV
- Files uploaded to S3

``` bash
EventBridge (5 min)
↓
Entities-Generator Lambda
↓
S3
├── customers.csv
└── accounts.csv
```

---

## 2. AML Pipeline (Every 1 minute)

EventBridge → Step Functions → Lambda → S3

### Step 1: Generate Transactions
- Reads Customers & Accounts from S3
- Generates transaction data
- Uploads `transactions.csv`

### Step 2: Generate Alerts
- Reads transactions
- Applies AML logic
- Uploads `alerts.csv`

``` bash
EventBridge (1 min)
↓
Step Functions
↓
GenerateTransactions Lambda
↓
S3 → transactions.csv
↓
GenerateAlerts Lambda
↓
S3 → alerts.csv
```

---

# S3 Output Structure
``` bash
s3://aml-data-bucket/

customers/
  customers.csv

accounts/
  accounts.csv

transactions/
  transactions.csv

alerts/
  alerts.csv
```
---

# Components

## EventBridge Rules

### Entity Scheduler
- Trigger: every 5 minutes
- Target: Entities-Generator Lambda

### AML Scheduler
- Trigger: every 1 minute
- Target: Step Functions State Machine

## Lambda Functions

### 1. Entities-Generator
Generates:
- Customers
- Accounts

Output:
- customers.csv
- accounts.csv

### 2. GenerateTransactions

Input:
- customers.csv
- accounts.csv

Output:
- transactions.csv

### 3. GenerateAlerts

Input:
- transactions.csv

Output:
- alerts.csv

## Step Functions Workflow

``` bash
Start
↓
GenerateTransactions
↓
GenerateAlerts
↓
End
```
---

# Deployment Steps

## 1. Create S3 Bucket

```bash
aws s3 mb s3://aml-data-bucket
```

## 2. Deploy Lambda Functions
- Entities-Generator
- GenerateTransactions
- GenerateAlerts

Set environment variables:
```bash
BUCKET_NAME=aml-data-bucket
```
## 3. Create Step Function

Workflow:

GenerateTransactions → GenerateAlerts

## 4. Create EventBridge Schedules
- Entity Generator
    rate(5 minutes)

    Target:

    Entities-Generator Lambda

- AML Pipeline
    rate(1 minute)

    Target:

    Step Function State Machine

# Purpose

This system simulates realistic AML data for:

- Real-time streaming pipelines
- Fraud detection models
- Data engineering pipelines
- Kafka / Kinesis ingestion
- Data warehouse testing

# Future Integration

This module feeds into:

- Kafka / Kinesis streaming
- Real-time AML detection
- AWS Glue ETL
- Redshift / Snowflake
- Dashboarding (PowerBI / QuickSight)

# Example Generated Data
Customers
```bash

customer_id,name,country,risk_score
C001,John Doe,UK,0.23
C002,Ali Khan,UAE,0.87
```
Accounts
```bash

account_id,customer_id,balance
A001,C001,12000
A002,C002,54000
```
Transactions
```bash

txn_id,from_account,to_account,amount
T001,A001,A002,9000
Alerts
```bash

alert_id,txn_id,reason
AL001,T001,High Value Transfer
```
# Author
Moavia Mahmood