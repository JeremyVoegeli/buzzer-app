resource "aws_apigatewayv2_integration" "api_integration" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    integration_type = "AWS_PROXY"
    integration_uri = aws_lambda_function.remove_user_lambda.invoke_arn
    integration_method = "DELETE"
}

resource "aws_apigatewayv2_route" "remove_user_route" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    route_key = "remove_user"
    target = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}