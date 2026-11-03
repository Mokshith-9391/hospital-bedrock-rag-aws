# Guardrail policy

Configure Bedrock Guardrails for:
- prompt injection / jailbreak detection
- harmful content categories as appropriate
- sensitive information handling
- profanity
- grounding/relevance checks where supported
- denied topics for autonomous diagnosis/prescribing
- custom blocked phrases for attempts to reveal system prompts/secrets

Guardrails are one layer only. Also validate input, retrieval metadata, authorization, citations, and output.
