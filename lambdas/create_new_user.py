import json
import uuid
import random
import string
import boto3

def lambda_handler(event, context):
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
    if "body" not in event or not event["body"]: #check that request body is present
        send_to_client({
            "message": "Missing request body",
            "status": "Error"
        })
        return {"statusCode": 400}

    try:
        username = event["body"]["username"]
        user_id = str(uuid.uuid4())
        is_host = False


        response_data = {
            "message": "Created new user (test).",
            "status": "success"
        }

        send_to_client(response_data)
        return {"statusCode": 200}
    
    except json.JSONDecodeError: #error for invalid json format
        send_to_client({
            "message": "Invalid JSON format",
            "status": "Error"
        })
        return {"StatusCode": 400}