variable "s3_bucket" {}

resource "aws_cloudwatch_event_rule" "cron" {
  name                = "drift-detection-cron"
  schedule_expression = "rate(2 minutes)"
}

resource "aws_cloudwatch_event_rule" "s3_change" {
  name = "s3-tfstate-updated"
  event_pattern = jsonencode({
    source      = ["aws.s3"],
    detail-type = ["Object Created"],
    detail = {
      bucket = { name = [var.s3_bucket] }
    }
  })
}