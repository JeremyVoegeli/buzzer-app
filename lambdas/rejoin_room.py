import json
import boto3
import time
from boto3.dynamodb.conditions import Key

"""
Expected Request format:
{
    "action": "rejoin_room",
    "room_id": "ABCDE",
    "user_id": 329d22fd-fea3-4497-b45d-973fdb579b49
}
"""

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("connections")

def lambda_handler(event, context):
    # ---------- Lambda Logistics ----------
    print("event: ", event)

    #establish variables from request
    connection_id = event["requestContext"]["connectionId"]
    domain = event["requestContext"]["domainName"]
    stage = event["requestContext"]["stage"]
    endpoint_url = f"https://{domain}/{stage}"

    #establish connection to the client
    client = boto3.client("apigatewaymanagementapi", endpoint_url=endpoint_url)

    #sends msg (JSON) back to client
    def send_to_client(msg):
        client.post_to_connection(ConnectionId=connection_id, Data=json.dumps(msg))

    #returns a list of all users in the room the new user is joining
    def get_all_users_in_room(room_id):
        all_users = []
        exclusive_start_key = None

        while True:

            query_kwargs = {"KeyConditionExpression": Key("room_id").eq(room_id)}

            if exclusive_start_key:
                query_kwargs["ExclusiveStartKey"] = exclusive_start_key

            response = table.query(**query_kwargs)

            all_users.extend(response.get("Items", []))

            exclusive_start_key = response.get("LastEvaluatedKey")
            if not exclusive_start_key: break

        return all_users

    # ---------- Actual Lambda Logic ----------
    if "body" not in event or not event["body"]: #check that request body is present
            send_to_client({
                "message": "Missing request body",
                "status": "Error"
            })
            return {"statusCode": 400}
    
    try:
        body = json.loads(event["body"])
        room_id = body["room_id"]
        user_id = body["user_id"]

        #verify this user exists
        response = table.query(KeyConditionExpression=Key("room_id").eq(room_id))
        items = response.get("Items", [])

        reconnecting_user = None
        username = None
        is_host = None
        old_connection_id = None

        for user in items:
              if user["user_id"] == user_id:
                    reconnecting_user = user
                    username = user["username"]
                    is_host = user["is_host"]
                    old_connection_id = user["connection_id"]
                    break

        if not reconnecting_user:
            send_to_client({
                "message": "User not found in database.",
                "status": "Error"
            })
            return {"statusCode": 404}

        #replace connection with a new one in connections table
        delete_response = table.delete_item(Key={"room_id": room_id, "connection_id": old_connection_id})

        
        put_response = table.put_item(
            Item = {
                "room_id": room_id,
                "connection_id": connection_id,
                "username": username,
                "user_id": user_id,
                "is_host": is_host,
                "expires_at": int(time.time()) + 21600
            }
        )

        all_users = get_all_users_in_room(room_id)
        roster = []

        for user in all_users:
             roster.append({"username": user["username"], "is_host": user["is_host"]})

        send_to_client({
                        "message": f"{username} has rejoined the room",
                        "status": "success",
                        "user_id": user_id,
                        "room_id": room_id,
                        "username": username,
                        "is_host": is_host,
                        "roster": roster
                    })
        return {"statusCode": 200}

    except (json.JSONDecodeError, KeyError): #error for invalid json format
            send_to_client({
                "message": "Invalid JSON format",
                "status": "Error"
            })
            return {"statusCode": 400}