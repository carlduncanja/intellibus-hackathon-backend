terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

##########################
# AWS Account Information
##########################

data "aws_caller_identity" "current" {}

##############################
# DynamoDB Table for Storage #
##############################

resource "aws_dynamodb_table" "connections" {
  name           = "WebSocketConnections"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  tags = var.tags
}

##########################################
# IAM Role and Policy for Lambda Execution
##########################################

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = [
          aws_dynamodb_table.connections.arn,
          aws_dynamodb_table.user_chats.arn,
          aws_dynamodb_table.chats.arn,
          aws_dynamodb_table.itineraries.arn,
          aws_dynamodb_table.schedule.arn,
          aws_dynamodb_table.socket_connections.arn,
          aws_dynamodb_table.promotions.arn
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["apigatewaymanagementapi:PostToConnection"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = "execute-api:ManageConnections",
        Resource = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.websocket_api.id}/*/@connections/*"
      },
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:intellibus_hackathon_2-credentials*"
      }
    ]
  })
}

#########################################################
# KMS Key and Secrets Manager for Basic Auth Credentials
#########################################################

resource "aws_kms_key" "intellibus_hackathon_2_key" {
  description             = "KMS key for encrypting intellibus hackathon credentials"
  deletion_window_in_days = 10
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid: "Allow administration of the key",
        Effect: "Allow",
        Principal: {
          AWS: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action: "kms:*",
        Resource: "*"
      },
      {
        Sid: "Allow Lambda to decrypt secrets",
        Effect: "Allow",
        Principal: {
          AWS: "${aws_iam_role.lambda_execution_role.arn}"
        },
        Action: [
          "kms:Decrypt"
        ],
        Resource: "*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_kms_alias" "intellibus_hackathon_2_key_alias" {
  name          = "alias/intellibus_hackathon_2"  # New alias name
  target_key_id = aws_kms_key.intellibus_hackathon_2_key.key_id
}

resource "aws_secretsmanager_secret" "intellibus_hackathon_2" {
  name        = "intellibus_hackathon_2-credentials"
  description = "Credentials for API Gateway"
  kms_key_id  = aws_kms_key.intellibus_hackathon_2_key.arn
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "intellibus_hackathon_2_version" {
  secret_id     = aws_secretsmanager_secret.intellibus_hackathon_2.id
  secret_string = jsonencode({
    username = var.secret_username
    password = var.secret_password
  })
}

##########################################
# Lambda Functions (Code from S3 bucket) #
##########################################

resource "aws_lambda_function" "connect_lambda" {
  function_name = "ConnectLambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.connect_lambda_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_execution_role.arn
  tags          = var.tags

  environment {
    variables = {
      WEBSOCKET_URL         = "https://${aws_apigatewayv2_api.websocket_api.id}.execute-api.${var.region}.amazonaws.com/${aws_apigatewayv2_stage.websocket_stage.name}"
      BASIC_AUTH_SECRET_ARN = aws_secretsmanager_secret.intellibus_hackathon_2.arn
    }
  }
}

resource "aws_lambda_function" "disconnect_lambda" {
  function_name = "DisconnectLambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.disconnect_lambda_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_execution_role.arn
  tags          = var.tags
}

resource "aws_lambda_function" "default_lambda" {
  function_name = "DefaultLambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.default_lambda_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_execution_role.arn
  tags          = var.tags

  # Attach the custom Lambda layer using the variable (if still needed; note that layers are not supported for image packages)
  # If you need the layer functionality, you might need to incorporate it into your container image.
  # layers = [
  #   var.openai_layer_arn
  # ]

  environment {
    variables = {
      WEBSOCKET_URL         = "https://${aws_apigatewayv2_api.websocket_api.id}.execute-api.${var.region}.amazonaws.com/${aws_apigatewayv2_stage.websocket_stage.name}"
      BASIC_AUTH_SECRET_ARN = aws_secretsmanager_secret.intellibus_hackathon_2.arn
    }
  }
}


#####################################################
# CloudWatch Log Groups for Lambda Function Logging #
#####################################################

resource "aws_cloudwatch_log_group" "connect_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.connect_lambda.function_name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "disconnect_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.disconnect_lambda.function_name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "default_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.default_lambda.function_name}"
  retention_in_days = 14
  tags              = var.tags
}

#######################################
# API Gateway V2 WebSocket API Config #
#######################################

resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "WebSocketAPI"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  tags                       = var.tags
}

resource "aws_apigatewayv2_integration" "connect_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.connect_lambda.arn}/invocations"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "disconnect_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.disconnect_lambda.arn}/invocations"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "default_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.default_lambda.arn}/invocations"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect_integration.id}"
}

resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect_integration.id}"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.default_integration.id}"
}

resource "aws_apigatewayv2_deployment" "websocket_deployment" {
  api_id = aws_apigatewayv2_api.websocket_api.id

  triggers = {
    redeployment = sha1(join(",", [
      aws_apigatewayv2_route.connect_route.id,
      aws_apigatewayv2_route.disconnect_route.id,
      aws_apigatewayv2_route.default_route.id
    ]))
  }

  depends_on = [
    aws_apigatewayv2_route.connect_route,
    aws_apigatewayv2_route.disconnect_route,
    aws_apigatewayv2_route.default_route
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  name        = "development"
  auto_deploy = true

  lifecycle {
    ignore_changes = [deployment_id]
  }

  tags = var.tags
}

#############################################
# Lambda Permissions for API Gateway Invoke #
#############################################

resource "aws_lambda_permission" "apigw_invoke_connect" {
  statement_id  = "AllowAPIGatewayInvokeConnect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.connect_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$connect"
}

resource "aws_lambda_permission" "apigw_invoke_disconnect" {
  statement_id  = "AllowAPIGatewayInvokeDisconnect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disconnect_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$disconnect"
}

resource "aws_lambda_permission" "apigw_invoke_default" {
  statement_id  = "AllowAPIGatewayInvokeDefault"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.default_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$default"
}

###################
# Output the WebSocket URL
###################

output "websocket_url" {
  description = "The WebSocket API URL"
  value       = "wss://${aws_apigatewayv2_api.websocket_api.id}.execute-api.${var.region}.amazonaws.com/${aws_apigatewayv2_stage.websocket_stage.name}"
}

###########################################
# Additional DynamoDB Tables for New Entities
###########################################

# UserChats table for the many-to-many relationship between Users and Chats.
resource "aws_dynamodb_table" "user_chats" {
  name           = "UserChats"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "UserId"
  range_key      = "ChatId"

  attribute {
    name = "UserId"
    type = "S"
  }
  attribute {
    name = "ChatId"
    type = "S"
  }

  tags = var.tags
}

# Chats table.
resource "aws_dynamodb_table" "chats" {
  name           = "Chats"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = var.tags
}

# Itineraries table.
resource "aws_dynamodb_table" "itineraries" {
  name           = "Itineraries"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = var.tags
}

# Schedule table.
resource "aws_dynamodb_table" "schedule" {
  name           = "Schedule"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = var.tags
}

# SocketConnections table.
resource "aws_dynamodb_table" "socket_connections" {
  name           = "SocketConnections"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = var.tags
}

# Promotions table.
resource "aws_dynamodb_table" "promotions" {
  name           = "Promotions"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = var.tags
}

############################################
# ECR Repositories for Lambda Function Code
############################################


resource "aws_ecr_repository" "connect_lambda_repo" {
  name = "connect-lambda-repo"
  tags = var.tags
}

resource "aws_ecr_repository" "disconnect_lambda_repo" {
  name = "disconnect-lambda-repo"
  tags = var.tags
}

resource "aws_ecr_repository" "default_lambda_repo" {
  name = "default-lambda-repo"
  tags = var.tags
}
