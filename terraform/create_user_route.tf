resource "aws_apigatewayv2_integration" "create_new_user_integration" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    integration_type = "AWS_PROXY"
    integration_uri = aws_lambda_function.create_new_user_lambda.invoke_arn
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "create_user_route" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    route_key = "create_user"
    target = "integrations/${aws_apigatewayv2_integration.create_new_user_integration.id}"
}