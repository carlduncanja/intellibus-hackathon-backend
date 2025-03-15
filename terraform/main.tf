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

#######################################
# API Gateway V2 WebSocket API Config #
#######################################

resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "WebSocketAPI"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  tags                       = var.tags
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