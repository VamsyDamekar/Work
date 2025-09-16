provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "glue_service_role" {
  name = "glue_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_attach" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_job" "example" {
  name     = "example-glue-job"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name           = "glueetl"
    script_location = "s3://aws-s3-etl-demo-repo/scripts/glue-script.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"

  default_arguments = {
    "--TempDir"                           = "s3://aws-s3-etl-demo-repo/temp/"
    "--job-language"                      = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"

    "--SOURCE_BUCKET" = "aws-s3-etl-demo-repo"
    "--OUTPUT_BUCKET" = "aws-s3-etl-demo-repo"
  }

  max_retries = 1
  timeout     = 10
  description = "A Glue job for ETL demo using aws-s3-etl-demo-repo bucket"
}

