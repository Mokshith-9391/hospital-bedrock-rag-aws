# Hospital Enterprise RAG — AWS Bedrock Knowledge Bases

Production-oriented reference implementation for a hospital document assistant using:
- Amazon S3 document landing zone
- OCR/PDF/document ingestion
- Amazon Bedrock Knowledge Bases
- Amazon Titan Text Embeddings V2
- Amazon OpenSearch Serverless vector store
- Bedrock Guardrails + prompt templates
- Amazon API Gateway + Lambda
- Amazon Cognito
- DynamoDB audit/session metadata
- AWS WAF + rate limiting/bot-control design
- CloudWatch + CloudTrail
- Evaluation harness with retrieval/generation metrics
- Terraform infrastructure
- React frontend

## Safety boundary
This repository is an educational/reference architecture. Use only synthetic or de-identified data.
It is not a diagnostic, prescribing, triage, or autonomous clinical decision system.
Retrieved documents are treated as untrusted input. Responses must cite sources and abstain when evidence is insufficient.
Clinical deployment requires hospital security/privacy review, clinical validation, human oversight, and applicable regulatory/compliance review.

## Architecture

CloudFront/WAF -> React -> API Gateway -> Cognito JWT -> Query Lambda
                                      |
                                      +-> Bedrock Guardrail
                                      +-> Bedrock Knowledge Base
                                      |      S3 -> parsing/OCR -> chunking
                                      |      Titan Embeddings V2 -> OpenSearch Serverless
                                      +-> Bedrock FM
                                      +-> DynamoDB audit
                                      +-> CloudWatch / CloudTrail

For scanned PDFs, the ingestion pipeline should perform OCR before placing normalized text/PDF artifacts into the KB data source. For production, Amazon Textract is the preferred AWS OCR component for scanned documents; this starter uses an OCR adapter interface so Textract can be wired without changing the KB layer.

## Current deployment status

The Terraform configuration is a validated foundation only. It currently
creates an S3 document bucket, Cognito user pool/client, DynamoDB audit table,
HTTP API shell, and CloudWatch log group. It does **not** yet define the Lambda
function or API integration, Bedrock Knowledge Base/data source/guardrail,
OpenSearch Serverless collection and policies, CloudFront/WAF, frontend hosting,
or CI/CD. Do not run `terraform apply` expecting a working application until
those components and their least-privilege IAM roles are implemented and
reviewed. Use only synthetic or de-identified documents during all testing.

## Deployment sequence

1. Configure AWS credentials and region.
2. Review `config/metadata-schema.json`.
3. Review and customize Terraform variables.
4. Deploy network/security/storage/OpenSearch/Bedrock/API/auth/observability modules.
5. Upload synthetic/de-identified hospital documents to the configured S3 prefix.
6. Start the Bedrock Knowledge Base ingestion job.
7. Build/deploy the Lambda package.
8. Build the React app and host it behind CloudFront.
9. Run `pytest` and the evaluation harness.
10. Enable alarms and review CloudTrail/WAF/Guardrail logs before any production use.

## Important implementation note
Bedrock Knowledge Bases are managed AWS resources. Terraform support and resource arguments vary by AWS provider version and region. The Terraform files therefore separate stable resource configuration from clearly marked provider-version/region checks rather than pretending every argument is universally available.

## Example questions
- "What is the hospital's visitor policy?"
- "Summarize the patient discharge procedure and cite the source."
- "Which document defines the insurance pre-authorization workflow?"

Do not use the system for patient-specific diagnosis or medication recommendations.
