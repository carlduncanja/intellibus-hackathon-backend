import json
import os
from datetime import datetime

import boto3
from boto3.dynamodb.conditions import Attr

api_gateway = boto3.client(
    'apigatewaymanagementapi',
    endpoint_url=os.environ['WEBSOCKET_URL']
)

dynamodb = boto3.resource('dynamodb')
chat_table = dynamodb.Table("Chats")


# Chat Service (WEBSOCKET)
def sendMessage(data):
    """
    Send a message to an existing chat by appending it to the chat's Messages list.
    Expects `data` to contain 'ChatId' and a 'Text' dictionary representing the message.
    """
    print(f"Sending message: {data}")
    try:
        chat_id = data['ChatId']
        message_data = data

        if not chat_id or not message_data:
            raise ValueError("Both ChatId and Text (message) must be provided.")

        if 'DateCreated' not in message_data:
            message_data['DateCreated'] = datetime.now().isoformat()

        chat_table.update_item(
            Key={'Id': chat_id},
            UpdateExpression="SET Messages = list_append(if_not_exists(Messages, :empty), :msg)",
            ExpressionAttributeValues={
                ':msg': [message_data],
                ':empty': []
            },
            ReturnValues="UPDATED_NEW"
        )
        return True
    except Exception as e:
        print(f"Error sending message: {e}")
        return False


def getUserChats(user_id):
    """
    Retrieve chats that involve the given user.
    """
    print(f"Getting chats for user {user_id}")
    try:
        response = chat_table.scan(
            FilterExpression=Attr('Participants').contains(user_id)
        )
        return response['Items']
    except Exception as e:
        print(f"Error getting user chats: {e}")
        return []


def createChat(data):
    """
    Create a new chat entry in DynamoDB.
    """
    print(f"Creating chat: {data}")
    try:
        data['DateCreated'] = datetime.now().isoformat()

        if 'Messages' not in data or data['Messages'] is None:
            data['Messages'] = []

        if 'Participants' not in data or data['Participants'] is None:
            data['Participants'] = [data['AdminId']]

        chat_table.put_item(Item=data)
        return True
    except Exception as e:
        print(f"Error creating chat: {e}")
        return False


def leaveChat(chat_id, user_id):
    """
    Remove a user from an existing chat by updating the Participants list manually.
    """
    print(f"Leaving chat: {chat_id}")
    try:
        if not chat_id or not user_id:
            raise ValueError("Both ChatId and UserId must be provided.")

        response = chat_table.get_item(Key={'Id': chat_id})
        item = response.get('Item')

        if not item:
            raise ValueError("Chat not found")

        participants = item.get('Participants', [])

        if user_id in participants:
            participants.remove(user_id)

            chat_table.update_item(
                Key={'Id': chat_id},
                UpdateExpression="SET Participants = :p",
                ExpressionAttributeValues={
                    ':p': participants
                }
            )
        else:
            print(f"User {user_id} is not in Participants")

        return True

    except Exception as e:
        print(f"Error leaving chat: {e}")
        return False


def joinChat(chat_id, user_id):
    """
    Add a user to an existing chat by updating the Participants list manually.
    """
    print(f"Joining chat: {chat_id}")
    try:
        if not chat_id or not user_id:
            raise ValueError("Both ChatId and UserId must be provided.")

        response = chat_table.get_item(Key={'Id': chat_id})
        item = response.get('Item')

        if not item:
            raise ValueError("Chat not found")

        participants = item.get('Participants', [])

        if user_id not in participants:
            participants.append(user_id)

            chat_table.update_item(
                Key={'Id': chat_id},
                UpdateExpression="SET Participants = :p",
                ExpressionAttributeValues={
                    ':p': participants
                }
            )
        else:
            print(f"User {user_id} is already in Participants")

        return True

    except Exception as e:
        print(f"Error joining chat: {e}")
        return False


def reply(connection_id, response_data):
    try:
        api_gateway.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps({'response': response_data})
        )
    except api_gateway.exceptions.GoneException:
        print(f"Connection {connection_id} no longer exists")
    return {
        'statusCode': 200,
        'body': json.dumps(response_data)
    }
