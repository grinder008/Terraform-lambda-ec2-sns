provider "aws" {
  region = "eu-north-1"
}
#Creating the s3 bucket for cloudtrail
resource "aws_s3_bucket" "cloud_trail" {
  bucket = "demo-cloudtrail-bucket-88771098"
}
data "aws_caller_identity" "current" {}
#Setting the bucket policy
resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.cloud_trail.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "cloudtrail.amazonaws.com"
            }
            Action = "s3:GetBucketAcl"
            Resource = aws_s3_bucket.cloud_trail.arn
        },
        {
            Effect = "Allow"
            Principal = {
                Service = "cloudtrail.amazonaws.com"
            }
            Action = "s3:PutObject"
            Resource = "${aws_s3_bucket.cloud_trail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
            Condition = {
                StringEquals = {
                    "s3:x-amz-acl" = "bucket-owner-full-control"
                }
            }
        }
    ]
  })
}
#Creating the sns topic
resource "aws_sns_topic" "topic" {
  name = "demo-sns-topic"
}
resource "aws_sns_topic_subscription" "subs" {
  topic_arn = aws_sns_topic.topic.arn
  protocol = "email"
  endpoint = "karoudriadh@gmail.com"
}
#Creating the eventbridge event rule
resource "aws_cloudwatch_event_rule" "rule" {
  name = "demo-eventbridge-rule-ec2-launch"
  description = "Capture any launch of an ec2 instance!"
  event_pattern = jsonencode({
    source = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
        eventSource = ["ec2.amazonaws.com"]
        eventName = ["RunInstances"]
    }
  })
}
#Creating the lambda func
resource "aws_lambda_function" "func" {
  function_name = "demo-lambda-ec2-event"
  runtime = "python3.12"
  handler = "lambda.handler"
  filename = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  role = aws_iam_role.role.arn
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.topic.arn
    }
  }
}
#Setting the lambda permission
resource "aws_lambda_permission" "perm" {
  function_name = aws_lambda_function.func.function_name
  principal = "events.amazonaws.com"
  action = "lambda:InvokeFunction"
  source_arn = aws_cloudwatch_event_rule.rule.arn
}
#Setting the iam role for lambda
resource "aws_iam_role" "role" {
  name = "demo-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "lambda.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }
    ]
  })
}
#Setting the iam policy actions
resource "aws_iam_policy" "policy" {
  name = "demo-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = ["sns:Publish"]
            Resource = aws_sns_topic.topic.arn
        }
    ]
  })
}
#attaching the iam policy
resource "aws_iam_role_policy_attachment" "attach_shit" {
  role = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
#attaching the iam policy
resource "aws_iam_role_policy_attachment" "attach" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
#Setting the eventbridge target
resource "aws_cloudwatch_event_target" "target" {
  rule = aws_cloudwatch_event_rule.rule.name
  arn = aws_lambda_function.func.arn
  target_id = "TriggerLambda"
}
#Setting the cloudtrail
resource "aws_cloudtrail" "cloud" {
  name = "demo-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloud_trail.bucket
  include_global_service_events = true
  is_multi_region_trail = true
  event_selector {
    read_write_type = "WriteOnly"
    include_management_events = true
  }
}