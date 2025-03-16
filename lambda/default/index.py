import json
import boto3

apigatewaymanagementapi = boto3.client('apigatewaymanagementapi',
                                       endpoint_url='https://ay4vs1shl6.execute-api.us-east-1.amazonaws.com/development')


def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    message = json.loads(event['body']).get('message', '')
    print(f"Message received: {message} from connection ID: {connection_id}")

    # Optionally, you can broadcast the message to other connected clients or handle it in any way you want
    try:
        # Send a response message back to the client
        apigatewaymanagementapi.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps({'response': 'Message Received on the Server : ' + message})
        )
    except apigatewaymanagementapi.exceptions.GoneException:
        print(f"Connection {connection_id} no longer exists")

    return {
        'statusCode': 200,
        'body': 'Message processed'
    }
