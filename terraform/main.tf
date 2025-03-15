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
