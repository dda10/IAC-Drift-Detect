variable "s3_bucket" {}

resource "aws_iam_role" "aws_config" {
  name = "AWSConfigServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = { Service = "config.amazonaws.com" },
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "aws_config_attach" {
  role       = aws_iam_role.aws_config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "config" {
  name     = "default"
  role_arn = aws_iam_role.aws_config.arn
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "channel" {
  name           = "default"
  s3_bucket_name = var.s3_bucket
  depends_on     = [aws_config_configuration_recorder.config]
}

resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true
}
