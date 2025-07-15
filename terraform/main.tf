module "s3" {
  source = "./modules/s3"
}

module "sns" {
  source = "./modules/sns"
}

module "aws_config" {
  source = "./modules/aws_config"
  s3_bucket = module.s3.bucket_name 
}

module "lambda" {
  source = "./modules/lambda"
  sns_topic_arn = module.sns.topic_arn
  s3_bucket = module.s3.bucket_name
}

module "evenbridge" {
  source = "./modules/eventbridge"
  lambda_arn = module.lambda.lambda_arn
  s3_bucket = module.s3.bucket_name  
}