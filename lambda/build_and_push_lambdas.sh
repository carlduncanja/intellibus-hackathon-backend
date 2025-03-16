#!/usr/bin/env bash

# ------------------------------
# Configuration
# ------------------------------
REGION="us-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ------------------------------
# Authenticate to ECR
# ------------------------------
echo "🔐 Logging in to Amazon ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# ------------------------------
# Connect Lambda
# ------------------------------
echo "🚀 Building Connect Lambda"
docker build --platform=linux/amd64 -t connect-lambda connect
docker tag connect-lambda:latest "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/connect-lambda-repo:latest"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/connect-lambda-repo:latest"
echo "✅ Pushed Connect Lambda"

# ------------------------------
# Disconnect Lambda
# ------------------------------
echo "🚀 Building Disconnect Lambda"
docker build --platform=linux/amd64 -t disconnect-lambda disconnect
docker tag disconnect-lambda:latest "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/disconnect-lambda-repo:latest"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/disconnect-lambda-repo:latest"
echo "✅ Pushed Disconnect Lambda"

# ------------------------------
# Default Lambda
# ------------------------------
echo "🚀 Building Default Lambda"
docker build --platform=linux/amd64 -t default-lambda default
docker tag default-lambda:latest "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/default-lambda-repo:latest"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/default-lambda-repo:latest"
echo "✅ Pushed Default Lambda"


# ------------------------------
# CreateVoice Lambda
# ------------------------------
echo "🚀 Building CreateVoice Lambda"
docker build --platform=linux/amd64 -t default-lambda create_voice
docker tag default-lambda:latest "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/create-voice-lambda-repo:latest"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/create-voice-lambda-repo:latest"
echo "✅ Pushed CreateVoice Lambda"

echo "🎉 All Lambda images built and pushed successfully."


# deploy the lambdas
aws lambda update-function-code --region $REGION --function-name ConnectLambda --image-uri "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/connect-lambda-repo:latest"

aws lambda update-function-code --region $REGION --function-name DisconnectLambda --image-uri "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/disconnect-lambda-repo:latest"

aws lambda update-function-code --region $REGION --function-name DefaultLambda --image-uri "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/default-lambda-repo:latest"

aws lambda update-function-code --region $REGION --function-name CreateVoiceLambda --image-uri "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/create-voice-lambda-repo:latest"
