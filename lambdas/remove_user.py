import json
import boto3
from boto3.dynamodb.conditions import Key

"""
Expected Request Format:
{
    "action": "remove_user",
    "connection_id: gVuFMK6MpQAYKEjXpA==
}
"""

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("connections")

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
    def send_to_client(msg):
        client.post_to_connection(ConnectionId=connection_id, Data=json.dumps(msg))

    # ---------- Actual Lambda Logic ----------

    #retrieve connection_id from request
    body = json.loads(event["body"])
    connection_id_to_remove = body["connection_id"]

    #query for room_id of user
    query_response = table.query(IndexName="index_by_connection_id", KeyConditionExpression=Key("connection_id").eq(connection_id_to_remove))
    items = query_response.get("Items", [])

    #check that user exists in db
    if not items:
        send_to_client({
            "message": "User isn't currently in database",
            "status": "Error"
        })
        return {"statusCode": 404}

    #delete the user from the db based on their room_id
    for item in items:
        room_id = item["room_id"]
        table.delete_item(Key={
            "room_id": room_id,
            "connection_id": connection_id_to_remove
        })

    send_to_client({
        "message": f"removed user: {items}",
        "status": "success"
    })
    return {"statusCode": 200}