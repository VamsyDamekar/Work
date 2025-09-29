provider "aws" {
  region = "us-east-1"
}

#########################
# Section 1: S3 Buckets (raw + curated)
#########################
resource "aws_s3_bucket" "raw" {
  bucket = "rawbt1"
  acl    = "private"
}

resource "aws_s3_bucket" "curated" {
  bucket = "curatedbt1"
  acl    = "private"
}

#########################
# Section 5: SNS Topic for Alerts
#########################
resource "aws_sns_topic" "lambda_alerts" {
  name = "lambda-error-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.lambda_alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"  # Replace with your email
}

#########################
# Section 2: Lambda IAM Role
#########################
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw.arn,
          "${aws_s3_bucket.raw.arn}/*",
          aws_s3_bucket.curated.arn,
          "${aws_s3_bucket.curated.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.lambda_alerts.arn
      }
    ]
  })
}

#########################
# Section 2: Lambda Function
#########################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "transform" {
  function_name = "transform_raw_to_curated"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      RAW_BUCKET     = aws_s3_bucket.raw.bucket
      CURATED_BUCKET = aws_s3_bucket.curated.bucket
      SNS_TOPIC_ARN  = aws_sns_topic.lambda_alerts.arn
    }
  }
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transform.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw.arn
}

#########################
# Section 2: S3 Trigger for Lambda
#########################
resource "aws_s3_bucket_notification" "raw_to_lambda" {
  bucket = aws_s3_bucket.raw.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.transform.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

#########################
# Section 4: Step Functions for Orchestration
#########################
resource "aws_iam_role" "stepfunctions_role" {
  name = "stepfunctions_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "states.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "stepfunctions_policy" {
  name = "stepfunctions_policy"
  role = aws_iam_role.stepfunctions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.transform.arn
      }
    ]
  })
}

resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "batch_etl_pipeline"
  role_arn = aws_iam_role.stepfunctions_role.arn

  definition = jsonencode({
    Comment = "ETL pipeline: raw S3 → Lambda transform → curated S3"
    StartAt = "TransformData"
    States = {
      TransformData = {
        Type       = "Task"
        Resource   = aws_lambda_function.transform.arn
        End        = true
      }
    }
  })
}

#########################
# Section 4: Optional EventBridge Cron Trigger for Step Function
#########################
resource "aws_cloudwatch_event_rule" "stepfunctions_cron" {
  name                = "stepfunctions_15min"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "stepfunctions_target" {
  rule      = aws_cloudwatch_event_rule.stepfunctions_cron.name
  target_id = "stepfunctions_target"
  arn       = aws_sfn_state_machine.etl_pipeline.arn
}

resource "aws_lambda_permission" "allow_eventbridge_sfn" {
  statement_id  = "AllowEventBridgeInvokeSFN"
  action        = "states:StartExecution"
  function_name = aws_sfn_state_machine.etl_pipeline.name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stepfunctions_cron.arn
}

#########################
# Section 3: Athena Table
# Note: Athena table creation is usually manual or via Glue crawler
# You can optionally create via Terraform Glue/Athena resources
#########################
resource "aws_athena_database" "curated_db" {
  name   = "curated_data_db"
  bucket = aws_s3_bucket.curated.bucket
}

resource "aws_athena_table" "curated_orders" {
  name      = "curated_orders"
  database  = aws_athena_database.curated_db.name
  bucket    = aws_s3_bucket.curated.bucket
  force_destroy = true
  # Schema example - adapt to your CSV columns
  columns = [
    {
      name = "order_id"
      type = "string"
    },
    {
      name = "user_id"
      type = "string"
    },
    {
      name = "product_id"
      type = "string"
    },
    {
      name = "quantity"
      type = "int"
    },
    {
      name = "price"
      type = "double"
    },
    {
      name = "order_timestamp"
      type = "string"
    },
    {
      name = "ingestion_timestamp"
      type = "string"
    }
  ]
}
