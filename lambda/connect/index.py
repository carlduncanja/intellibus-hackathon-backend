import json
import boto3

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
connections_table = dynamodb.Table('WebSocketConnections')


def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    print(f"New connection: {connection_id}")

    # Store the connection ID in DynamoDB
    connections_table.put_item(
        Item={
            'id': connection_id
        }
    )

    return {
        'statusCode': 200,
        'body': 'Connected'
    }
