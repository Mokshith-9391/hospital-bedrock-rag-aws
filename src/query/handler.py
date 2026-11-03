import json
import os
import time
import uuid
import boto3

SYSTEM_PROMPT = open(os.path.join(os.path.dirname(__file__), "system.txt"), encoding="utf-8").read()

def _response(status, body):
    return {"statusCode": status, "headers": {"content-type": "application/json"}, "body": json.dumps(body)}

def _access_filter(department, role):
    """Constrain retrieval using claims from the verified JWT authorizer only."""
    return {
        "andAll": [
            {"equals": {"key": "department", "value": department}},
            {"listContains": {"key": "access_roles", "value": role}},
        ]
    }

def _audit(table, request_id, **values):
    table.put_item(Item={"request_id": request_id, "timestamp": int(time.time()), **values})

def lambda_handler(event, context):
    started = time.time()
    request_id = str(uuid.uuid4())
    # Create SDK clients only at invocation time. This keeps module imports
    # side-effect free for tests and lets Lambda resolve its runtime region.
    bedrock_agent_runtime = boto3.client("bedrock-agent-runtime")
    guardrails = boto3.client("bedrock-runtime")
    ddb = boto3.resource("dynamodb")
    kb_id = os.environ["KNOWLEDGE_BASE_ID"]
    model_arn = os.environ["MODEL_ARN"]
    guardrail_id = os.environ.get("GUARDRAIL_ID", "")
    guardrail_version = os.environ.get("GUARDRAIL_VERSION", "DRAFT")
    audit_table = os.environ["AUDIT_TABLE"]
    try:
        body = json.loads(event.get("body") or "{}")
        question = (body.get("question") or "").strip()
        if not question or len(question) > 4000:
            return _response(400, {"error": "Invalid question"})

        # In production, derive department/roles from verified Cognito claims.
        claims = ((event.get("requestContext") or {}).get("authorizer") or {}).get("jwt", {}).get("claims", {})
        role = claims.get("custom:role", "authenticated")
        department = claims.get("custom:department", "general")

        retrieval = bedrock_agent_runtime.retrieve(
            knowledgeBaseId=kb_id,
            retrievalQuery={"text": question},
            retrievalConfiguration={
                "vectorSearchConfiguration": {
                    "numberOfResults": 8,
                    "filter": _access_filter(department, role),
                }
            }
        )
        results = retrieval.get("retrievalResults", [])
        context_blocks = []
        sources = []
        for r in results:
            text = r.get("content", {}).get("text", "")
            loc = r.get("location", {})
            uri = loc.get("s3Location", {}).get("uri", "unknown")
            score = r.get("score")
            context_blocks.append(f"[SOURCE {len(context_blocks)+1}] {text}")
            sources.append({"id": len(sources)+1, "uri": uri, "score": score})

        if not context_blocks:
            answer = "I don't have enough evidence in the hospital knowledge base to answer that reliably."
            _audit(ddb.Table(audit_table), request_id, department=department, role=role,
                   retrieval_count=0, latency_ms=int((time.time()-started)*1000), outcome="no_evidence")
            return _response(200, {"request_id": request_id, "answer": answer, "sources": []})

        prompt = SYSTEM_PROMPT + "\n\nUser question:\n" + question + \
                 f"\n\nAuthorized role: {role}; department: {department}\n\n" + \
                 "\n\n".join(context_blocks)

        kwargs = {
            "modelId": model_arn,
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "inferenceConfig": {"temperature": 0.1, "maxTokens": 1200}
        }
        if guardrail_id:
            kwargs["guardrailConfig"] = {
                "guardrailIdentifier": guardrail_id,
                "guardrailVersion": guardrail_version
            }

        response = guardrails.converse(**kwargs)
        answer = response["output"]["message"]["content"][0]["text"]

        _audit(ddb.Table(audit_table), request_id, department=department, role=role,
               retrieval_count=len(results), latency_ms=int((time.time()-started)*1000), outcome="success")
        return _response(200, {"request_id": request_id, "answer": answer, "sources": sources})
    except Exception:
        try:
            _audit(ddb.Table(audit_table), request_id, outcome="error")
        except Exception:
            pass
        return _response(500, {"request_id": request_id, "error": "Request failed"})
