import json
import boto3

def lambda_handler(event, context):
    connection_id = event["requestContext"]["connectionId"]
    domain = event["requestContext"]["domainName"]
    stage = event["requestContext"]["stage"]
    endpoint_url = f"https://{domain}/{stage}"

    client = boto3.client("apigatewaymanagementapi", endpoinet_url=endpoint_url)

    response_data = {
        "message": "This is a message.",
        "status": "success"
    }

    client.post_to_connection(
        ConnectionId=connection_id,
        Data=json.dumps(response_data)
    )

    return {"statusCode": 200,}