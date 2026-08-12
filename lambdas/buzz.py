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

    #checks whether a connection with given connection_id is open
    def is_connection_open(connection_id):
         try:
              client.get_connection(ConnectionId=connection_id)
              return True
         except client.exceptions.GoneException:
              return False

    # ---------- Actual Lambda Logic ----------
    if "body" not in event or not event["body"]: #check that request body is present
            send_to_client({
                "message": "Missing request body",
                "status": "Error"
            }, connection_id)
            return {"statusCode": 400}
    try:
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
        query_response = buzzes_table.query(
            KeyConditionExpression=Key("room_id").eq(room_id),
            ScanIndexForward=True,
            Limit=1
            )
        
        items = query_response.get("Items", [])
        if items[0]["user_id"] == user_id:
            #get a list of all connection_ids in the current room
            query_response2 = connections_table.query(KeyConditionExpression=Key("room_id").eq(room_id))
            items2 = query_response2.get("Items", [])

            winning_username = items[0]["username"]
            connection_ids = []
            for connection in items2:
                #removes user if there is a closed connection - fallback for any stale connections left over
                if not is_connection_open(connection["connection_id"]):
                    response = connections_table.delete_item(Key={"room_id": room_id, "connection_id": connection["connection_id"]})
                    print(f"Removed {connection["user_id"]}")

                else:
                    connection_ids.append(connection["connection_id"])

            #send message to all connections for that room
            for c in connection_ids:
                send_to_client({
                    "message": f"{winning_username} buzzed first",
                    "status": "success"
                }, c)

        return {"statusCode": 200}

    except (json.JSONDecodeError, KeyError): #error for invalid json format
            send_to_client({
                "message": "Invalid JSON format",
                "status": "Error"
            }, connection_id)
            return {"statusCode": 400}