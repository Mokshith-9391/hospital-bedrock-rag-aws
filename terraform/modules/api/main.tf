resource "aws_dynamodb_table" "audit" {
  name         = "${var.name}-audit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"
  range_key    = "timestamp"
  attribute { name = "request_id" type = "S" }
  attribute { name = "timestamp" type = "N" }
  server_side_encryption { enabled = true }
}

resource "aws_apigatewayv2_api" "this" {
  name = "${var.name}-api"
  protocol_type = "HTTP"
}
