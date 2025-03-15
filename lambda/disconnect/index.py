import boto3

dynamodb = boto3.resource('dynamodb')
connections_table = dynamodb.Table('WebSocketConnections')


def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    print(f"Connection closed: {connection_id}")

    # Remove the connection ID from DynamoDB
    connections_table.delete_item(
        Key={
            'id': connection_id
        }
    )

    return {
        'statusCode': 200,
        'body': 'Disconnected'
    }
