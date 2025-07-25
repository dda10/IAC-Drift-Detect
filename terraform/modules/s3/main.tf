resource "aws_s3_bucket" "tfstate" {
  bucket = "statetf-bucket"
  # force_destroy = true
}

output "bucket_name" {
    description = "S3 bucket name."
    value = aws_s3_bucket.tfstate.bucket
}

output "bucket_arn" {
    description = "S3 bucket ARN."
    value = aws_s3_bucket.tfstate.arn
}