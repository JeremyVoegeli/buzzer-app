# ---------- Lambda Trust Document ----------
data "aws_iam_policy_document" "lambda_trust" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
} #("Who can assume this role?")

# ---------- API Gateway Connection Policy ----------
data "aws_iam_policy_document" "apigateway_connection_permissions" {
    statement{
        effect = "Allow"
        actions = ["execute-api:ManageConnections"]
        resources = ["${aws_apigatewayv2_api.websocket_api.execution_arn}/*/POST/@connections/*"] #<execution_arn>/<stage>/<http_method>/@connections/<connection_id>
    }
}

resource "aws_iam_policy" "apigateway_policy" {
    name = "apigateway_send_response_through_connections"
    policy = data.aws_iam_policy_document.apigateway_connection_permissions.json
}