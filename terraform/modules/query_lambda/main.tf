data "archive_file" "query" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/.build/query.zip"
}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "query" {
  name               = "${var.name}-query"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

data "aws_iam_policy_document" "query" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [var.audit_table_arn]
  }
  statement {
    actions   = ["bedrock:Retrieve"]
    resources = [var.knowledge_base_arn]
  }
  statement {
    actions   = ["bedrock:InvokeModel"]
    resources = [var.model_arn]
  }
}

resource "aws_iam_role_policy" "query" {
  name = "query-runtime"
  role = aws_iam_role.query.id
  policy = data.aws_iam_policy_document.query.json
}

resource "aws_lambda_function" "query" {
  function_name = "${var.name}-query"
  role          = aws_iam_role.query.arn
  filename      = data.archive_file.query.output_path
  source_code_hash = data.archive_file.query.output_base64sha256
  handler       = "handler.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30
  memory_size   = 512
  reserved_concurrent_executions = 10
  environment {
    variables = {
      KNOWLEDGE_BASE_ID = var.knowledge_base_id
      MODEL_ARN         = var.model_arn
      GUARDRAIL_ID      = var.guardrail_id
      GUARDRAIL_VERSION = var.guardrail_version
      AUDIT_TABLE       = var.audit_table_name
    }
  }
}

output "function_arn" { value = aws_lambda_function.query.arn }
output "invoke_arn" { value = aws_lambda_function.query.invoke_arn }
