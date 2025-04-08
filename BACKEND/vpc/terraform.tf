provider "aws" {
  region = "us-east-1" # Specify your AWS region
}

# S3 Bucket for Test Logs and Results
resource "aws_s3_bucket" "infra_guard_logs" {
  bucket = "infra-guard-logs-${random_string.suffix.result}"
  acl    = "private"

  tags = {
    Name        = "InfraGuardLogs"
    Environment = "Dev"
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
}

# DynamoDB Table for Test Configurations
resource "aws_dynamodb_table" "test_configurations" {
  name         = "infra_guard_test_configurations"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "test_id"
    type = "S" # String
  }

  hash_key = "test_id"

  tags = {
    Name        = "TestConfigurations"
    Environment = "Dev"
  }
}

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_execution_role" {
  name = "infra_guard_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda Execution Role
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "infra_guard_lambda_policy"
  role   = aws_iam_role.lambda_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.infra_guard_logs.arn}/*"
      },
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.test_configurations.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda Function for Inspec Execution
resource "aws_lambda_function" "inspec_executor" {
  function_name    = "infra_guard_inspec_executor"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "inspec_executor.zip" # Upload the ZIP of your Lambda code here
  source_code_hash = filebase64sha256("inspec_executor.zip")

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.infra_guard_logs.bucket
      DYNAMODB_TABLE = aws_dynamodb_table.test_configurations.name
    }
  }
}

# API Gateway for Frontend Integration
resource "aws_api_gateway_rest_api" "infra_guard_api" {
  name        = "InfraGuardAPI"
  description = "API for InfraGuard backend services"
}

resource "aws_api_gateway_resource" "inspec_endpoint" {
  rest_api_id = aws_api_gateway_rest_api.infra_guard_api.id
  parent_id   = aws_api_gateway_rest_api.infra_guard_api.root_resource_id
  path_part   = "run-inspec"
}

resource "aws_api_gateway_method" "inspec_post" {
  rest_api_id   = aws_api_gateway_rest_api.infra_guard_api.id
  resource_id   = aws_api_gateway_resource.inspec_endpoint.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.infra_guard_api.id
  resource_id             = aws_api_gateway_resource.inspec_endpoint.id
  http_method             = aws_api_gateway_method.inspec_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.inspec_executor.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.infra_guard_api.id
  stage_name  = "dev"
}

# Output Resources
output "s3_bucket_name" {
  value = aws_s3_bucket.infra_guard_logs.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.test_configurations.name
}

output "lambda_function_name" {
  value = aws_lambda_function.inspec_executor.function_name
}

output "api_gateway_url" {
  value = "${aws_api_gateway_rest_api.infra_guard_api.execution_arn}/dev/run-inspec"
}
