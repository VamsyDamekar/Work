provider "aws" {
  region = "us-east-2"
}

# -------------------------
# S3 Buckets
# -------------------------
resource "aws_s3_bucket" "raw" {
  bucket = "rawbt1"
}

resource "aws_s3_bucket" "curated" {
  bucket = "finalbt1"
}

# -------------------------
# Kinesis Stream
# -------------------------
resource "aws_kinesis_stream" "weather_stream" {
  name             = "weather-stream"
  shard_count      = 1
  retention_period = 24
}

# -------------------------
# IAM Role for Lambda
# -------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda_weather_role"

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

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_weather_policy"
  description = "Allow Lambda to read Kinesis and write to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::rawbt1/*",
          "arn:aws:s3:::finalbt1/*",
          "arn:aws:s3:::rawbt1",
          "arn:aws:s3:::finalbt1"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:DescribeStream", "kinesis:ListStreams"]
        Resource = aws_kinesis_stream.weather_stream.arn
      }
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# -------------------------
# Lambda Function
# -------------------------
resource "aws_lambda_function" "weather_lambda" {
  function_name = "weather_kinesis_to_s3"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  # Zip file containing your lambda_function.py
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      RAW_BUCKET     = "rawbt1"
      CURATED_BUCKET = "finalbt1"
    }
  }
}

# -------------------------
# Event Source Mapping (Kinesis → Lambda)
# -------------------------
resource "aws_lambda_event_source_mapping" "kinesis_to_lambda" {
  event_source_arn  = aws_kinesis_stream.weather_stream.arn
  function_name     = aws_lambda_function.weather_lambda.arn
  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true
}
