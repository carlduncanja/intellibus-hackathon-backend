############################################
# ECR Repository for CreateVoiceLambda Code
############################################

resource "aws_ecr_repository" "create_voice_lambda_repo" {
  name = "create-voice-lambda-repo"
  tags = var.tags
}

##########################################
# Lambda Function: CreateVoiceLambda
##########################################

resource "aws_lambda_function" "create_voice_lambda" {
  function_name = "CreateVoiceLambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.create_voice_lambda_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_execution_role.arn
  tags          = var.tags

  environment {
    variables = {
      ELEVENLABS_API_KEY = var.elevenlabs_api_key
      # URL to which the Lambda will make the POST request
      ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1/voices/add"
      # Any additional environment variables (such as a default name or other config) can be added here
    }
  }
}

############################################
# API Gateway V2 HTTP API for CreateVoiceLambda
############################################

resource "aws_apigatewayv2_api" "create_voice_http_api" {
  name          = "CreateVoiceHTTPAPI"
  protocol_type = "HTTP"
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "create_voice_http_integration" {
  api_id                 = aws_apigatewayv2_api.create_voice_http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.create_voice_lambda.arn}/invocations"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_voice_http_route" {
  api_id    = aws_apigatewayv2_api.create_voice_http_api.id
  route_key = "POST /create-voice"
  target    = "integrations/${aws_apigatewayv2_integration.create_voice_http_integration.id}"
}

resource "aws_apigatewayv2_stage" "create_voice_http_stage" {
  api_id      = aws_apigatewayv2_api.create_voice_http_api.id
  name        = "production"
  auto_deploy = true
  tags        = var.tags
}

############################################
# Lambda Permission for API Gateway Invoke (CreateVoiceLambda)
############################################

resource "aws_lambda_permission" "apigw_invoke_create_voice_http" {
  statement_id  = "AllowAPIGatewayInvokeCreateVoiceHTTP"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_voice_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.create_voice_http_api.execution_arn}/*/POST/create-voice"
}

output "create_voice_lambda_url" {
  description = "CreateVoiceLambda URL"
  value       = "${aws_apigatewayv2_api.create_voice_http_api.api_endpoint}/create-voice"
}