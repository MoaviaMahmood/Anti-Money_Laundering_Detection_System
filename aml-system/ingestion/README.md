# ingestion

The Kinesis consumer Lambda — the heart of the real-time AML detection pipeline.

## File

`aml-kinesis-consumer_LAMBDA.py` — subscribes to the `transactions-data-stream` Kinesis stream, evaluates 14 AML rules per record, and writes alerts to S3 in JSONL format.

## Trigger

This Lambda is invoked **by Kinesis**, not on a schedule:

- Source: `transactions-data-stream`
- Batch size: 100 records per invocation
- Starting position: `LATEST`
- Parallelization factor: 1

When `GenerateTransactions` publishes records to the stream, this consumer fires within 1-2 seconds.

## What it does, per transaction

1. Decodes the JSON payload from the Kinesis record
2. Evaluates each of the 14 AML rules
3. Each rule that fires generates an `Alert` with:
   - A unique alert ID
   - The rule name (`HIGH_VALUE`, `STRUCTURING`, ...)
   - Severity score (0-100)
   - Status (`OPEN`)
   - Reference to the source transaction and customer
4. All firing alerts for the batch are buffered in memory
5. At the end of the batch, alerts are written to S3 as a single JSONL file:
   ```
   aml-data/alerts/realtime/dt=YYYY-MM-DD/<uuid>.jsonl
   ```
6. (Optional) Stateful rules update DynamoDB to track sliding windows

JSONL (one JSON object per line) is used instead of CSV because alerts have variable-shape `notes` fields and JSONL is the standard for streaming append-only event logs.

## The 14 rules

Each rule is a function that takes a transaction dict and returns either `None` (no alert) or an `Alert` object. Rules are evaluated independently — a single transaction can fire multiple rules.

### Stateless rules (decided from one transaction alone)

| Rule | Logic | Score |
|---|---|---|
| `HIGH_VALUE` | `amount >= 10_000` | 85 |
| `HIGH_RISK_COUNTRY` | `country_origin in HIGH_RISK_SET or country_dest in HIGH_RISK_SET` | 60 |
| `CROSS_BORDER_HIGH` | Cross-border + amount > \$5K | 70 |
| `LAYERING` | `aml_pattern == "LAYERING"` (uses ground-truth label) | 95 |
| `ROUND_TRIP` | `aml_pattern == "ROUND_TRIP"` | 100 |
| `SHELL_COMPANY` | `aml_pattern == "SHELL_COMPANY"` | 100 |
| `TRADE_BASED` | `aml_pattern == "TRADE_BASED"` | 75 |
| `LARGE_RAPID` | `aml_pattern == "LARGE_RAPID"` | 99 |
| `IMPOSSIBLE_TRAVEL` | `aml_pattern == "IMPOSSIBLE_TRAVEL"` | 71 |
| `RAPID_MOVEMENT` | `aml_pattern == "RAPID_MOVEMENT"` | 80 |

### Stateful rules (need history)

| Rule | Logic | Score |
|---|---|---|
| `STRUCTURING` | 3+ cash deposits between \$8K-\$10K from same customer in last hour | 90 |
| `STRUCTURING_WINDOW` | Time-windowed variant | 90 |
| `HIGH_VELOCITY` | 8+ transactions from same account in 30 min | 73 |
| `VELOCITY_BURST` | Short-window high-frequency variant | 75 |

Stateful rules need to remember past transactions. The current implementation uses Python dicts as in-memory caches within a single Lambda invocation; a production version would use DynamoDB with a TTL.

## Why Kinesis-then-Lambda

The architecture deliberately separates ingestion (Kinesis) from processing (Lambda):

- **Decoupling** — if the Lambda fails, the stream retains data for 24h and Lambda retries automatically
- **Throughput** — Kinesis shards allow horizontal scaling without code changes
- **Ordering** — partition key `sender_customer` ensures stateful rules see one customer's events in order
- **Replay** — Kinesis lets you replay history into a new consumer (useful for testing rule changes)

A simpler EventBridge → Lambda path would have worked, but you'd lose ordering guarantees and replay.

## Required environment variables

| Variable | Example |
|---|---|
| `BUCKET_NAME` | `aml-fyp-stream-bucket-...` |
| `S3_PREFIX` | `aml-data/` |

## IAM permissions

This Lambda needs:

- `AWSLambdaKinesisExecutionRole` (managed) — read from Kinesis
- S3 PutObject on the alert prefix
- (optional) DynamoDB read/write if stateful rules use DynamoDB

## Deploying

1. Zip `aml-kinesis-consumer_LAMBDA.py`
2. Upload via Lambda console
3. Set timeout: 60s (it's batch-processing, can take a few seconds for 100 records)
4. Set memory: 512 MB
5. Add Kinesis trigger pointing at `transactions-data-stream`

## Output sample

A single line in the output JSONL file:

```json
{
  "alert_id": "A-9FB425D24C",
  "transaction_id": "T-A3F58F6C-94E",
  "customer_id": "C-DD7146AA-B81",
  "alert_type": "HIGH_VALUE",
  "alert_score": 85.0,
  "created_at": "2026-04-27T17:54:10Z",
  "status": "OPEN",
  "notes": "Auto-generated alert for transaction T-A3F58F6C-94E"
}
```

These get crawled by `aml-alerts-realtime-crawler` into the `realtime` Athena table, then exposed through the cleaned `alerts_clean` view used by the dashboard.

## Tuning

- **Increase batch size** to reduce Lambda invocation count if event volume is high
- **Increase memory** if processing time spikes (Lambda CPU scales with memory)
- **Add a Dead Letter Queue** for production: failed batches go to SQS for manual replay
