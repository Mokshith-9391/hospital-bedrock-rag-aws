"""Idempotently create the Bedrock-compatible OpenSearch Serverless index."""
import json
import os
import sys
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest

endpoint = os.environ["OPENSEARCH_ENDPOINT"].rstrip("/")
index = os.environ["OPENSEARCH_INDEX"]
region = os.environ["AWS_REGION"]
body = json.dumps({
    "settings": {"index": {"knn": True}},
    "mappings": {"properties": {
        "bedrock-knowledge-base-default-vector": {
            "type": "knn_vector", "dimension": 1024,
            "method": {"name": "hnsw", "engine": "faiss", "space_type": "l2", "parameters": {"ef_construction": 512, "m": 16}},
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {"type": "text", "index": True},
        "AMAZON_BEDROCK_METADATA": {"type": "text", "index": False},
    }},
}).encode()
request = AWSRequest(method="PUT", url=f"{endpoint}/{index}", data=body, headers={"content-type": "application/json"})
SigV4Auth(boto3.Session().get_credentials().get_frozen_credentials(), "aoss", region).add_auth(request)
prepared = request.prepare()
try:
    with urlopen(Request(prepared.url, data=body, method="PUT", headers=dict(prepared.headers)), timeout=60) as response:
        print(response.read().decode())
except HTTPError as error:
    detail = error.read().decode()
    if error.code == 400 and "resource_already_exists_exception" in detail:
        print("Index already exists")
    else:
        print(detail, file=sys.stderr)
        raise
