provider "aws" {
  region = "us-east-2"
}

# ===========================
# S3 Buckets (Raw and Curated already exist)
# ===========================
# Assuming you already have rawbt1 and finalbt1 buckets created

# ===========================
# IAM Role & Policy for Lambda
# ===========================
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
  name        = "lambda-glue-athena-policy"
  description = "Policy for Lambda to run Glue and Athena"

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
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:GetJob"
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
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::rawbt1",
          "arn:aws:s3:::rawbt1/*",
          "arn:aws:s3:::finalbt1",
          "arn:aws:s3:::finalbt1/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# ===========================
# Lambda Function
# ===========================
resource "aws_lambda_function" "glue_athena_lambda" {
  function_name = "glue-athena-runner"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_etl_athena.lambda_handler"
  runtime       = "python3.12"

  filename         = "lambda_etl_athena.zip"
  source_code_hash = filebase64sha256("lambda_etl_athena.zip")

  environment {
    variables = {
      GLUE_JOB_NAME   = "weather-etl-job"
      ATHENA_DATABASE = "weather_db"
      ATHENA_QUERY    = "SELECT * FROM transformed_weather LIMIT 10;"
      ATHENA_OUTPUT   = "s3://finalbt1/athena-results/"
    }
  }
}

# ===========================
# Step Functions
# ===========================
resource "aws_iam_role" "stepfn_role" {
  name = "stepfn-lambda-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "stepfn_lambda_attach" {
  role       = aws_iam_role.stepfn_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

resource "aws_cloudwatch_log_group" "stepfn_logs" {
  name              = "/aws/stepfunctions/glue-athena-workflow"
  retention_in_days = 14
}

resource "aws_sfn_state_machine" "glue_athena_stepfn" {
  name     = "glue-athena-workflow"
  role_arn = aws_iam_role.stepfn_role.arn

  definition = jsonencode({
    Comment = "Step Function to run Glue + Athena via Lambda",
    StartAt = "RunLambda",
    States = {
      RunLambda = {
        Type       = "Task",
        Resource   = aws_lambda_function.glue_athena_lambda.arn,
        End        = true
      }
    }
  })

  logging_configuration {
    level                    = "ALL"
    include_execution_data   = true
    log_destination          = aws_cloudwatch_log_group.stepfn_logs.arn
  }
}

# ===========================
# CloudWatch Logs for Lambda
# ===========================
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/glue-athena-runner"
  retention_in_days = 14
}

# ===========================
# SNS Topic & Subscription for Alerts
# ===========================
resource "aws_sns_topic" "alerts" {
  name = "pipeline-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "vamsi87870@gmail.com"  # replace with your email
}

# ===========================
# CloudWatch Alarms
# ===========================
# Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "LambdaGlueAthenaErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm if Lambda Glue-Athena fails"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    FunctionName = aws_lambda_function.glue_athena_lambda.function_name
  }
}

# Step Function failures
resource "aws_cloudwatch_metric_alarm" "stepfn_fail_alarm" {
  alarm_name          = "StepFnGlueAthenaFailures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm if Step Function fails"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    StateMachineArn = aws_sfn_state_machine.glue_athena_stepfn.arn
  }
}
