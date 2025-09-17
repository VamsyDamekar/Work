provider "aws" {
  region = "us-east-2"
}

# --------------------------
# S3 Buckets
# --------------------------
resource "aws_s3_bucket" "raw" {
  bucket = "rawbt1"
}

resource "aws_s3_bucket" "curated" {
  bucket = "finalbt1"
}

# --------------------------
# Kinesis Stream
# --------------------------
resource "aws_kinesis_stream" "weather_stream" {
  name             = "weather-stream"
  shard_count      = 1
  retention_period = 24
}

# --------------------------
# IAM Role for Lambda (Kinesis → S3 → Glue → Athena)
# --------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda-kinesis-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-kinesis-s3-policy"
  description = "Policy for Lambda to access Kinesis, S3, Glue, Athena, CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.raw.arn,
          "${aws_s3_bucket.raw.arn}/*",
          aws_s3_bucket.curated.arn,
          "${aws_s3_bucket.curated.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "glue:StartCrawler",
          "glue:GetCrawler",
          "glue:GetDatabase",
          "glue:GetTable"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# --------------------------
# Lambda Function (Data Transformation)
# --------------------------
resource "aws_lambda_function" "kinesis_to_s3_lambda" {
  function_name = "weather-kinesis-to-s3"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_kinesis_to_s3.lambda_handler"
  runtime       = "python3.12"

  filename         = "lambda_kinesis_to_s3.zip"
  source_code_hash = filebase64sha256("lambda_kinesis_to_s3.zip")

  environment {
    variables = {
      RAW_BUCKET     = aws_s3_bucket.raw.bucket
      CURATED_BUCKET = aws_s3_bucket.curated.bucket
    }
  }
}

# --------------------------
# Kinesis → Lambda Event Source
# --------------------------
resource "aws_lambda_event_source_mapping" "kinesis_event" {
  event_source_arn  = aws_kinesis_stream.weather_stream.arn
  function_name     = aws_lambda_function.kinesis_to_s3_lambda.arn
  starting_position = "LATEST"
  batch_size        = 100
}

# --------------------------
# Glue Crawler
# --------------------------
resource "aws_glue_crawler" "weather_curated_crawler" {
  name         = "weather_curated_crawler"
  role         = aws_iam_role.lambda_role.arn
  database_name = "weather_db"
  targets {
    s3_targets {
      path = aws_s3_bucket.curated.arn
    }
  }
  schedule = "" # run on-demand
}

# --------------------------
# Lambda to run Glue + Athena
# --------------------------
resource "aws_lambda_function" "glue_athena_lambda" {
  function_name = "glue-athena-runner"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_etl_athena.lambda_handler"
  runtime       = "python3.12"

  filename         = "lambda_etl_athena.zip"
  source_code_hash = filebase64sha256("lambda_etl_athena.zip")

  environment {
    variables = {
      GLUE_CRAWLER   = aws_glue_crawler.weather_curated_crawler.name
      ATHENA_DATABASE = "weather_db"
      ATHENA_QUERY    = "SELECT * FROM transformed_weather LIMIT 10;"
      ATHENA_OUTPUT   = "s3://${aws_s3_bucket.curated.bucket}/athena-results/"
    }
  }
}

# --------------------------
# SNS Topic for Alerts
# --------------------------
resource "aws_sns_topic" "alerts" {
  name = "weather-pipeline-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com" # Replace with your email
}

# --------------------------
# IAM Role for Step Functions
# --------------------------
resource "aws_iam_role" "stepfn_role" {
  name = "stepfn-kinesis-lambda-glue-athena-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "stepfn_lambda_attach" {
  role       = aws_iam_role.stepfn_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

# --------------------------
# Step Functions State Machine
# --------------------------
resource "aws_sfn_state_machine" "weather_pipeline" {
  name     = "weather-etl-pipeline"
  role_arn = aws_iam_role.stepfn_role.arn

  definition = jsonencode({
    Comment = "Weather ETL: Kinesis → Lambda → Glue → Athena → Alerts",
    StartAt = "LambdaTransform",
    States = {
      LambdaTransform = {
        Type       = "Task",
        Resource   = aws_lambda_function.kinesis_to_s3_lambda.arn,
        Next       = "RunGlueCrawler",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "SendAlert"
        }]
      },
      RunGlueCrawler = {
        Type       = "Task",
        Resource   = "arn:aws:states:::glue:startCrawler.sync",
        Parameters = { Name = aws_glue_crawler.weather_curated_crawler.name },
        Next       = "RunAthenaLambda",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "SendAlert"
        }]
      },
      RunAthenaLambda = {
        Type       = "Task",
        Resource   = aws_lambda_function.glue_athena_lambda.arn,
        End        = true,
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "SendAlert"
        }]
      },
      SendAlert = {
        Type       = "Task",
        Resource   = "arn:aws:states:::sns:publish",
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn,
          Message  = "Weather ETL pipeline failed!"
        },
        End = true
      }
    }
  })
}

# --------------------------
# CloudWatch Log Group for Lambda
# --------------------------
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/weather-kinesis-to-s3"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "glue_athena_logs" {
  name              = "/aws/lambda/glue-athena-runner"
  retention_in_days = 14
}

# --------------------------
# CloudWatch Alarm Example
# --------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "weather-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggered if Lambda has any errors"
  dimensions = {
    FunctionName = aws_lambda_function.kinesis_to_s3_lambda.function_name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}
