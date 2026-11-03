import json
import os
import time
import uuid
import boto3

bedrock_agent_runtime = boto3.client("bedrock-agent-runtime")
guardrails = boto3.client("bedrock-runtime")
ddb = boto3.resource("dynamodb")

KB_ID = os.environ["KNOWLEDGE_BASE_ID"]
MODEL_ARN = os.environ.get("MODEL_ARN", "")
GUARDRAIL_ID = os.environ.get("GUARDRAIL_ID", "")
GUARDRAIL_VERSION = os.environ.get("GUARDRAIL_VERSION", "DRAFT")
TABLE = os.environ["AUDIT_TABLE"]

SYSTEM_PROMPT = open(os.path.join(os.path.dirname(__file__), "../../prompts/system.txt")).read()

def _response(status, body):
    return {"statusCode": status, "headers": {"content-type": "application/json"}, "body": json.dumps(body)}

def lambda_handler(event, context):
    started = time.time()
    request_id = str(uuid.uuid4())
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
            knowledgeBaseId=KB_ID,
            retrievalQuery={"text": question},
            retrievalConfiguration={
                "vectorSearchConfiguration": {
                    "numberOfResults": 8
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
            return _response(200, {"request_id": request_id, "answer": answer, "sources": []})

        prompt = SYSTEM_PROMPT + "\n\nUser question:\n" + question + \
                 f"\n\nAuthorized role: {role}; department: {department}\n\n" + \
                 "\n\n".join(context_blocks)

        kwargs = {
            "modelId": MODEL_ARN,
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "inferenceConfig": {"temperature": 0.1, "maxTokens": 1200}
        }
        if GUARDRAIL_ID:
            kwargs["guardrailConfig"] = {
                "guardrailIdentifier": GUARDRAIL_ID,
                "guardrailVersion": GUARDRAIL_VERSION
            }

        response = guardrails.converse(**kwargs)
        answer = response["output"]["message"]["content"][0]["text"]

        table = ddb.Table(TABLE)
        table.put_item(Item={
            "request_id": request_id,
            "timestamp": int(time.time()),
            "department": department,
            "role": role,
            "retrieval_count": len(results),
            "latency_ms": int((time.time()-started)*1000),
            "outcome": "success"
        })
        return _response(200, {"request_id": request_id, "answer": answer, "sources": sources})
    except Exception:
        try:
            ddb.Table(TABLE).put_item(Item={
                "request_id": request_id,
                "timestamp": int(time.time()),
                "outcome": "error"
            })
        except Exception:
            pass
        return _response(500, {"request_id": request_id, "error": "Request failed"})
