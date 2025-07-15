variable "s3_bucket" {}
variable "sns_topic_arn" {}

resource "aws_iam_role" "drift_lambda" {
  name = "drift-checker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "drift_lambda_policy" {
  role       = aws_iam_role.drift_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_lambda_function" "drift_checker" {
  filename         = "${path.module}/code/drift_checker.zip"
  function_name    = "iac-drift-checker"
  role             = aws_iam_role.drift_lambda.arn
  handler          = "lambda_function_drift_checker.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = filebase64sha256("${path.module}/code/drift_checker.zip")
  environment {
    variables = {
      TFSTATE_BUCKET = var.s3_bucket
    }
  }
}

resource "aws_iam_role_policy" "bedrock_invoke" {
  name = "bedrock-invoke"
  role = aws_iam_role.drift_lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["bedrock:InvokeModel"],
      Resource = "*"  # You can scope this to a specific model ARN
    }]
  })
}

output "lambda_arn" {
  value = aws_lambda_function.drift_checker.arn
}
