data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Package the Lambda function code
data "archive_file" "example" {
  type        = "zip"
  source_file = "../lambda_function/main.py"
  output_path = "${path.root}/lambda_function_payload.zip"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "cloudtrail_lookup" {
  name = "lambda_cloudtrail_lookup_policy"
  role = aws_iam_role.example.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "cloudtrail:LookupEvents"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda_s3_access_policy"
  role = aws_iam_role.example.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}",
          "arn:aws:s3:::${var.s3_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "drift_detector" {
  function_name = "iac-drift-detector"
  role          = aws_iam_role.example.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.10"
  filename         = data.archive_file.example.output_path
  source_code_hash = data.archive_file.example.output_base64sha256

  environment { 
    variables = {
      TFSTATE_BUCKET = var.s3_bucket
    }
  }
}
