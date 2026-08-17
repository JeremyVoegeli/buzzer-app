import json
import boto3
from boto3.dynamodb.conditions import Key

"""
Expected Request format:
{
    "action": "clear_buzzes",
    "room_id": "ABCDE"
}
"""

dynamodb = boto3.resource("dynamodb")
buzz_table = dynamodb.Table("buzzes")
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

    # ---------- Actual Lambda Logic ----------
    if "body" not in event or not event["body"]: #check that request body is present
            send_to_client({
                "message": "Missing request body",
                "status": "Error"
            }, connection_id)
            return {"statusCode": 400}

    try:
        body = json.loads(event["body"])
        room_id = body["room_id"]

        #get list of all buzzes for given room
        response = buzz_table.query(
              KeyConditionExpression=Key("room_id").eq(room_id),
              ProjectionExpression="room_id, buzz_time"
        )

        items = response.get("Items", [])

        while "LastEvaluatedKey" in response:
              response = buzz_table.query(
                    KeyConditionExpression=Key("room_id").eq(room_id),
                    ProjectionExpression="room_id, buzz_time",
                    ExclusiveStartKey=response["LastEvaluatedKey"]
              )
              items.extend(response.get("Items", []))

        #check that buzzes are present
        if not items:
            send_to_client({
                "message": "No buzzes were found.",
                "status": "Error"
            }, connection_id)
            return {"statusCode": 404}

        #deletes all of the buzzes that were found
        with buzz_table.batch_writer() as batch:
             for item in items:
                  batch.delete_item(
                       Key={
                            "room_id": item["room_id"],
                            "buzz_time": item["buzz_time"]
                       }
                  )

        #gets a list of all connection IDs in the current room
        query_response = connections_table.query(KeyConditionExpression=Key("room_id").eq(room_id))
        items = query_response.get("Items", [])
        connection_ids = []
        for connection in items:
             connection_ids.append(connection["connection_id"])

        #sends the success message to every client in the room
        for c in connection_ids:
            send_to_client({
                "message": f"Successfully cleared all buzzes for room {room_id}.",
                "status": "success"
            }, c)

        return {"statusCode": 200}

    except (json.JSONDecodeError, KeyError): #error for invalid json format
            send_to_client({
                "message": "Invalid JSON format",
                "status": "Error"
            }, connection_id)
            return {"statusCode": 400}