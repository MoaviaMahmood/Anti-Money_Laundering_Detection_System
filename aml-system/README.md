# Repo Structure
``` bash
aml-system
│
├── data-generators/                        ←-- synthetic transaction simulator
│   ├── aml_synthetic_data_generator.py
│   ├── README.md
│   └── .gitignore
│   
├── frontend/
│   ├── scr/
│   ├── vite.config.ts
│   ├── README.md
│   └── .gitignore
│
├── infra
│   ├── docker-compose.yml            ←-- all infrastructure services
│   ├── docker-compose.override.yml   ←-- local dev overrides   
│   └── terraform/                    ←-- for transforming to cloud 
│   
├── ingestion
│   ├── kafka-configs/
│   └── debezium-connectors/
│
├── ml/
│   ├── notebooks/
│   ├── models/
│   └── feature-store/
│
├── pipelines/
│   ├── dags/             ←-- Airflow DAGs
│   ├── flink-jobs/
│   ├── spark-jobs/
│   └── dbt/              ←-- transformations
│                    
├── services/
│   ├── transaction-service/
│   ├── screening-service/
│   ├── scoring-service/
│   ├── alert-service/
│   └── case-management-api/
│
├── README.md            
└── docs/
```