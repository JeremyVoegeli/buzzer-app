import json
import uuid
import random
import time
import string
import boto3
from boto3.dynamodb.conditions import Key

"""
Expected Request format:
{
    "action": "create_user",
    "username": "John Doe",
    "room_id": "ABCDE" (<- optional)
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
    def send_to_client(msg, c_id):
        client.post_to_connection(ConnectionId=c_id, Data=json.dumps(msg))

    #generates a 6-digit uppercase-only string to represent the room code
    def generate_room_id():
        allowed_chars = string.ascii_uppercase
        random_id = "".join(random.choices(allowed_chars, k=6))
        return random_id

    #returns true if there is a collision in the room_id, false otherwise
    def has_room_id_collision(room_id):
        response = table.query(KeyConditionExpression=Key("room_id").eq(room_id))

        items = response.get("Items", [])

        if items:
            return True
        else:
            return False

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
        }, connection_id)
        return {"statusCode": 400}

    try:
        body = json.loads(event["body"])

        username = body["username"]
        user_id = str(uuid.uuid4())
        is_host = False

        if "room_id" in body:
            room_id = body["room_id"]
        else:
            is_host = True
            room_id = generate_room_id()

            i = 0
            while (i < 50):
                if not has_room_id_collision(room_id):
                    break
                room_id = generate_room_id()
                i += 1

            if (i == 50):
                send_to_client({
                    "message": "Couldn't generate room id. Please try again later.",
                    "status": "Error"
                }, connection_id)
                return {"statusCode": 400}

        response = table.put_item(
            Item = {
                "room_id": room_id,
                "connection_id": connection_id,
                "username": username,
                "user_id": user_id,
                "is_host": is_host,
                "expires_at": int(time.time()) + 7200
            }
        )

        put_item_status_code = response["ResponseMetadata"]["HTTPStatusCode"]
        if put_item_status_code != 200:
            send_to_client({
                "message": "Couldn't add new user to the database",
                "status": "Error"
            }, connection_id)
            return {"statusCode": put_item_status_code}

        #create a roster of every username and is_host value in the room
        all_users = get_all_users_in_room(room_id)
        roster = []
        all_conection_ids = []

        for user in all_users:
            roster.append({"username": user["username"], "is_host": user["is_host"]})
            if user["user_id"] != user_id:
                all_conection_ids.append(user["connection_id"])

        for c in all_conection_ids:
            send_to_client({
                "message": "Created new user.",
                "status": "success",
                "roster": roster
            }, c)

        send_to_client({
                        "message": "Created new user.",
                        "status": "success",
                        "user_id": user_id,
                        "room_id": room_id,
                        "is_host": is_host,
                        "roster": roster
                    }, connection_id)
        return {"statusCode": 200}
    
    except (json.JSONDecodeError, KeyError): #error for invalid json format
        send_to_client({
            "message": "Invalid JSON format",
            "status": "Error"
        }, connection_id)
        return {"statusCode": 400}