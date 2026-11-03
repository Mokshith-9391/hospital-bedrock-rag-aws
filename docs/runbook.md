# Operations runbook

## Ingestion failure
Check S3 object metadata, OCR job status, KB ingestion job, CloudWatch logs, and OpenSearch capacity.

## Poor answers
Check metadata filters, chunk quality, retrieval scores, source freshness, prompt version, Guardrail interventions, and evaluation metrics.

## Security incident
Disable affected client/user, inspect Cognito activity, API/WAF logs and CloudTrail, preserve evidence, rotate credentials/secrets if required, and follow hospital incident-response policy.

## PHI
Do not put PHI into CloudWatch logs, source-control, test fixtures, or evaluation datasets. Use synthetic/de-identified data.
