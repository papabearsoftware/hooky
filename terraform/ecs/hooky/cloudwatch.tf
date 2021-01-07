resource "aws_cloudwatch_log_group" "hooky" {
  name              = "hooky"
  retention_in_days = 1
}