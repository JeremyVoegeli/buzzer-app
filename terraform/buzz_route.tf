resource "aws_apigatewayv2_integration" "buzz_integration" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    integration_type = "AWS_PROXY"
    integration_uri = aws_lambda_function.buzz_lambda.invoke_arn
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "buzz_route" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    route_key = "buzz"
    target = "integrations/${aws_apigatewayv2_integration.buzz_integration.id}"
}