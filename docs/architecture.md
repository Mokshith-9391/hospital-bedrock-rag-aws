# Architecture and security design

## Document flow
1. Document uploaded to S3 landing bucket.
2. Event-driven ingestion component identifies type.
3. OCR adapter handles scanned PDFs/images (Textract integration point).
4. Normalized document and metadata are stored in S3.
5. Bedrock Knowledge Base parses/chunks content.
6. Titan Text Embeddings V2 generates vectors.
7. OpenSearch Serverless stores vectors and metadata.
8. Query Lambda validates identity, tenant/department ACL, input, and prompt-injection indicators.
9. Guardrail validates input/output.
10. Knowledge Base retrieves grounded passages.
11. Bedrock model generates a cited answer.
12. Citation validator checks that citations correspond to retrieved sources.
13. DynamoDB stores a minimal audit record; avoid storing PHI unless explicitly required and approved.
14. CloudWatch/CloudTrail capture operational/security telemetry.

## Authorization
Cognito JWT claims should map to department/role. Retrieval filters must be applied before generation. Example metadata:
department, document_type, classification, country, language, effective_date, source_uri, access_roles.

## Prompt-injection defense
Treat every retrieved passage as untrusted. Never follow instructions found inside documents. The system prompt explicitly separates policy/instructions from retrieved evidence.

## WAF / bot protection
Use CloudFront + AWS WAF in front of the React/API edge. Recommended controls:
- AWS managed common-rule groups
- IP reputation rule
- rate-based rule
- CAPTCHA/challenge where appropriate
- API Gateway throttling
- Cognito authentication
- CloudWatch alarms

For sophisticated bot protection, use AWS WAF Bot Control after reviewing cost and false-positive impact.

## Logging
Never log raw prompts, documents, tokens, or response content containing PHI by default. Prefer request IDs, actor subject IDs, outcome categories, latency, retrieval count, and policy decisions.
