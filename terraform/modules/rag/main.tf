data "aws_caller_identity" "current" {}

locals {
  collection_name = substr(replace(lower("${var.name}-kb"), "_", "-"), 0, 32)
  index_name      = "bedrock-knowledge-base-index"
}

data "aws_iam_policy_document" "assume_bedrock" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "knowledge_base" {
  name               = "${var.name}-knowledge-base"
  assume_role_policy = data.aws_iam_policy_document.assume_bedrock.json
}

data "aws_iam_policy_document" "knowledge_base" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [var.document_bucket_arn, "${var.document_bucket_arn}/*"]
  }
  statement {
    actions   = ["aoss:APIAccessAll"]
    resources = ["*"]
  }
  statement {
    actions   = ["bedrock:InvokeModel"]
    resources = [var.embedding_model_arn]
  }
}

resource "aws_iam_role_policy" "knowledge_base" {
  name   = "knowledge-base-runtime"
  role   = aws_iam_role.knowledge_base.id
  policy = data.aws_iam_policy_document.knowledge_base.json
}

resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${local.collection_name}-encryption"
  type = "encryption"
  policy = jsonencode([{
    Rules = [{ ResourceType = "collection", Resource = ["collection/${local.collection_name}"] }]
    AWSOwnedKey = true
  }])
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${local.collection_name}-network"
  type = "network"
  # Development-only: data access is still restricted by the access policy below.
  policy = jsonencode([{
    Rules = [
      { ResourceType = "collection", Resource = ["collection/${local.collection_name}"] },
      { ResourceType = "dashboard", Resource = ["collection/${local.collection_name}"] }
    ]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_collection" "knowledge_base" {
  name             = local.collection_name
  type             = "VECTORSEARCH"
  standby_replicas = "DISABLED"
  depends_on       = [aws_opensearchserverless_security_policy.encryption]
}

resource "aws_opensearchserverless_access_policy" "knowledge_base" {
  name = "${local.collection_name}-access"
  type = "data"
  policy = jsonencode([{
    Description = "Knowledge Base and deployer access"
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${local.collection_name}"]
        Permission   = ["aoss:DescribeCollectionItems", "aoss:CreateCollectionItems", "aoss:UpdateCollectionItems"]
      },
      {
        ResourceType = "index"
        Resource     = ["index/${local.collection_name}/*"]
        Permission   = ["aoss:CreateIndex", "aoss:DescribeIndex", "aoss:ReadDocument", "aoss:WriteDocument", "aoss:UpdateIndex"]
      }
    ]
    Principal = [aws_iam_role.knowledge_base.arn, data.aws_caller_identity.current.arn]
  }])
}

resource "terraform_data" "vector_index" {
  triggers_replace = [aws_opensearchserverless_collection.knowledge_base.arn]
  depends_on       = [aws_opensearchserverless_access_policy.knowledge_base]

  provisioner "local-exec" {
    command = "python3 ${path.module}/../../../scripts/create_opensearch_index.py"
    environment = {
      AWS_REGION           = var.aws_region
      OPENSEARCH_ENDPOINT  = aws_opensearchserverless_collection.knowledge_base.collection_endpoint
      OPENSEARCH_INDEX     = local.index_name
    }
  }
}

resource "aws_bedrockagent_knowledge_base" "this" {
  name     = "${var.name}-knowledge-base"
  role_arn = aws_iam_role.knowledge_base.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = var.embedding_model_arn
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.knowledge_base.arn
      vector_index_name = local.index_name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [terraform_data.vector_index]
}

resource "aws_bedrockagent_data_source" "documents" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "${var.name}-documents"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn         = var.document_bucket_arn
      inclusion_prefixes = [var.document_prefix]
    }
  }
  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}

output "knowledge_base_id" { value = aws_bedrockagent_knowledge_base.this.id }
output "knowledge_base_arn" { value = aws_bedrockagent_knowledge_base.this.arn }
output "data_source_id" { value = aws_bedrockagent_data_source.documents.data_source_id }
