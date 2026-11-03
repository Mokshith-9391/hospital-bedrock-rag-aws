# Terraform production checklist

Before production:
- Pin exact AWS provider version after validation in the target region.
- Add KMS CMKs for S3, DynamoDB, logs and OpenSearch where required.
- Add bucket policies and VPC endpoints where applicable.
- Configure Bedrock Knowledge Base, data source, Titan Text Embeddings V2, and OpenSearch Serverless collection/index.
- Configure IAM least privilege.
- Add Cognito JWT authorizer and Lambda integration.
- Add CloudFront + WAF Web ACL, managed rules, rate-based rules and optional Bot Control.
- Add CloudWatch alarms for Lambda errors/throttles, API 4xx/5xx, latency, WAF blocks, ingestion failures and Bedrock throttles.
- Enable CloudTrail organization/account trail and immutable log destination.
- Add Guardrail and version it.
- Add backup/retention and incident-response procedures.
