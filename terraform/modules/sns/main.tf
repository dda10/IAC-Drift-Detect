resource "aws_sns_topic" "drift_alerts" {
  name = "iac-drift-alerts"
}

output "topic_arn" {
  value = aws_sns_topic.drift_alerts.arn
}