resource "aws_cognito_user_pool" "this" {
  name = "${var.name}-users"
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]
}
resource "aws_cognito_user_pool_client" "web" {
  name = "${var.name}-web"
  user_pool_id = aws_cognito_user_pool.this.id
  generate_secret = false
}
