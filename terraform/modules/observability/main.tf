resource "aws_cloudwatch_log_group" "app" {
  name = "/hospital-rag/${var.name}"
  retention_in_days = 30
}
