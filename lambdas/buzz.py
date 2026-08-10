import json
import boto3
from boto3.dynamodb.conditions import Key
from datetime import datetime, timezone

"""
Expected Request Format:
{
    "action": "buzz",
    "user_id: a1a4dc35-c81b-4d35-8aca-0600a9f95e02,
    "room_id: "ABCDE
}
"""

dynamodb = boto3.resource("dynamodb")
buzzes_table = dynamodb.Table("buzzes")
connections_table = dynamodb.Table("connections")

def lambda_handler(event, context):
    # ---------- Lambda Logistics ----------
    print(event)

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

    #returns true if this buzz was first in the buzzes table (requires a list of all dynamodb buzz items, and the current buzz time)
    def was_first_buzz(buzzes, cur_buzz: str):
        if (not buzzes):
            return True

        for buzz in buzzes:
            if datetime.fromisoformat(buzz["buzz_time"]) < datetime.fromisoformat(cur_buzz):
                return False

        return True

    # ---------- Actual Lambda Logic ----------

    #add buzz item into "buzzes" table
    body = json.loads(event["body"])
    room_id = body["room_id"]
    user_id = body["user_id"]
    buzz_time = str(datetime.now(timezone.utc))
    put_response = buzzes_table.put_item(
        Item = {
            "room_id": room_id,
            "user_id": user_id,
            "buzz_time": buzz_time
        }
    )

    #check if the buzz was first in the room
    query_response = buzzes_table.query(KeyConditionExpression=Key("room_id").eq(room_id))
    items = query_response.get("Items", [])

    if was_first_buzz(items, buzz_time):
        #get a list of all connection_ids in the current room
        query_response2 = connections_table.query(KeyConditionExpression=Key("room_id").eq(room_id))
        items2 = query_response2.get("Items", [])

        connection_ids = []
        for connection in items2:
            if (connection["connection_id"] != connection_id):
                connection_ids.append(connection["connection_id"])

        #send message to all connections for that room
        for c in connection_ids:
            send_to_client({
                "message": f"{user_id} buzzed first",
                "status": "success"
            }, c)


    send_to_client({
        "message": "You didn't buzz first in the room.",
        "status": "success"
    }, connection_id)

    return {"statusCode": 200}