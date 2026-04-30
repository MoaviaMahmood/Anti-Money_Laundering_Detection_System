# data-generators

Three Lambda functions that generate synthetic banking data on a schedule.

## Files

| File | Lambda | Schedule | Output |
|---|---|---|---|
| `entity-generator_LAMBDA_FUNCTION.py` | `Entities-Generator` | EventBridge, every 5 min | 300 customers + 450 accounts as CSV in S3 |
| `transactions-generations_LAMBDA_FUNCTION.py` | `GenerateTransactions` | Step Functions, every 1 min | 100+ transactions written to S3 + Kinesis |
| `alert-generation_LAMBDA_FUNCTION.py` | `GenerateAlerts` | Step Functions, every 1 min | Batch alerts as CSV in S3 (parallel to real-time alerts) |

## Why three generators

- **Entities** are slowly-changing dimensions. Banks don't onboard new customers every minute. We snapshot every 5 minutes for analytical tractability.
- **Transactions** are the hot data. New ones every minute simulate real-time banking activity.
- **Batch alerts** exist alongside the streaming consumer to demonstrate both patterns: the "old way" (re-scan all transactions periodically) and the "new way" (event-driven, real-time via Kinesis). Comparing them is part of the FYP evaluation.

## Data shapes

### Customer
```python
@dataclass
class Customer:
    customer_id: str           # "C-XXXXXXXX-XXX"
    first_name: str
    last_name: str
    country_code: str          # ISO-2 (e.g. "US", "KY", "AE")
    city: str
    risk_rating: str           # LOW / MEDIUM / HIGH (computed)
    business_type: str         # RETAIL / SHELL_COMPANY / NGO / ...
    pep_flag: bool             # ~5% are flagged as Politically Exposed Persons
    created_date: str          # ISO 8601
    is_suspicious: bool = False
```

### Account
```python
@dataclass
class Account:
    account_id: str            # "ACCXXXXXXXX"
    customer_id: str
    account_type: str          # CHECKING / SAVINGS / BUSINESS
    currency: str              # USD / EUR / GBP / ...
    balance: float
    opened_date: str
    country_code: str
    city: str
    is_active: bool = True
```

### Transaction
```python
@dataclass
class Transaction:
    transaction_id: str        # "T-XXXXXXXX-XXX"
    timestamp: str             # ISO 8601, UTC
    sender_account: str
    receiver_account: str
    sender_customer: str
    receiver_customer: str
    amount: float
    currency: str
    transaction_type: str      # WIRE / ACH / CASH_DEPOSIT / TRADE_PAYMENT / ...
    merchant_category: str
    location_city: str
    location_country: str
    device_used: str           # mobile / web / atm / pos
    country_origin: str
    country_dest: str
    is_suspicious: bool        # ground truth label
    aml_pattern: str           # NONE / STRUCTURING / LAYERING / ...
    alert_score: float         # 0-100
```

The `is_suspicious` and `aml_pattern` fields are ground-truth labels: they tell the consumer Lambda what the *correct* answer would be. This lets us measure detection precision/recall.

## How transactions get suspicious

`transactions-generations_LAMBDA_FUNCTION.py` calls eight specialized generators that each produce a different AML pattern:

| Function | Pattern | Builds |
|---|---|---|
| `gen_structuring()` | STRUCTURING | 3-8 deposits just below \$10K from random account |
| `gen_layering()` | LAYERING | A chain of 3-7 wires, each slightly smaller |
| `gen_round_trip()` | ROUND_TRIP | A → B then B → A within hours |
| `gen_shell_company()` | SHELL_COMPANY | Money in → shell account → money out |
| `gen_trade_based()` | TRADE_BASED | Over- or under-invoiced trade payment |
| `gen_large_rapid()` | LARGE_RAPID | Single big wire to high-risk jurisdiction |
| `gen_high_velocity()` | HIGH_VELOCITY | Burst of 8-15 small payments in 30 min |
| `gen_impossible_travel()` | IMPOSSIBLE_TRAVEL | Same account in two distant cities minutes apart |

These are interleaved with normal transactions at a configurable ratio (`SUSPICIOUS_RATIO`).

## S3 output structure

After generation:

```
aml-data/
├── customers/dt=2026-04-27/customers_15-30-12-123456.csv
├── accounts/dt=2026-04-27/accounts_15-30-13-456789.csv
├── transactions/dt=2026-04-27/transactions_15-31-04-789012.csv
└── alerts/batch/dt=2026-04-27/alerts_15-31-15-345678.csv
```

The `dt=YYYY-MM-DD/` prefix is critical — Glue auto-detects it as a Hive partition column, which makes Athena queries fast and cheap.

## Kinesis publishing

`GenerateTransactions` writes to S3 (for the data lake / batch path) **and** publishes to Kinesis (for the real-time path). Records are partitioned by `sender_customer` so all of one customer's transactions land on the same shard in order — important for stateful detection rules like HIGH_VELOCITY and STRUCTURING_WINDOW.

## Required environment variables

| Variable | Used by | Example |
|---|---|---|
| `BUCKET_NAME` | All three | `aml-fyp-stream-bucket-...` |
| `S3_PREFIX` | All three | `aml-data/` |
| `KINESIS_STREAM_NAME` | Transactions only | `transactions-data-stream` |

## Running locally for testing

The Lambdas are pure functions — you can invoke them locally with a stub event:

```python
# from inside the Lambda directory, with venv activated:
import os
os.environ["BUCKET_NAME"] = "aml-fyp-stream-bucket-..."
os.environ["S3_PREFIX"] = "aml-data/"
os.environ["KINESIS_STREAM_NAME"] = "transactions-data-stream"

from entity_generator_LAMBDA_FUNCTION import lambda_handler
result = lambda_handler({}, None)
print(result)
```

Requires `boto3` installed and AWS credentials configured.

## Deploying

For each Lambda:

1. Zip the `.py` file (and any dependencies if you add them — the current code uses only standard library + boto3, which is pre-installed in Lambda)
2. Upload via console or `aws lambda update-function-code`
3. Set environment variables
4. Wire to its trigger (EventBridge for entities, Step Functions for the others)
