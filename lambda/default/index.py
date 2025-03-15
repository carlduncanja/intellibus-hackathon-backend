import json

from constants import ACTION_SEND_MESSAGE, ACTION_GET_USER_CHATS, ACTION_CREATE_CHAT, ACTION_JOIN_CHAT, \
    ACTION_LEAVE_CHAT
from utils import sendMessage, getUserChats, createChat, joinChat, reply, leaveChat


def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']

    try:
        body = json.loads(event['body'])
    except json.JSONDecodeError:
        return reply(connection_id, {'error': 'Invalid JSON'})

    print(f"Action received: {body.get('Action')} from connection ID: {connection_id}")

    if 'Action' not in body:
        return reply(connection_id, {'error': 'Missing Action'})

    action = body['Action']

    if action == ACTION_SEND_MESSAGE:
        if 'Message' not in body:
            return reply(connection_id, {'error': 'Missing Message'})
        response_data = {'result': sendMessage(body['Message'])}

    elif action == ACTION_GET_USER_CHATS:
        if 'UserId' not in body:
            return reply(connection_id, {'error': 'Missing UserId'})
        response_data = getUserChats(body['UserId'])

    elif action == ACTION_CREATE_CHAT:
        if 'Chat' not in body:
            return reply(connection_id, {'error': 'Missing Chat'})
        response_data = {'result': createChat(body['Chat'])}

    elif action == ACTION_JOIN_CHAT:
        if 'ChatId' not in body or 'UserId' not in body:
            return reply(connection_id, {'error': 'Missing ChatId or UserId'})
        response_data = {'result': joinChat(body['ChatId'], body['UserId'])}

    elif action == ACTION_LEAVE_CHAT:
        if 'ChatId' not in body or 'UserId' not in body:
            return reply(connection_id, {'error': 'Missing Chat or UserId'})
        response_data = {'result': leaveChat(body['ChatId'], body['UserId'])}

    else:
        response_data = {'error': 'Unknown action'}

    return reply(connection_id, response_data)
