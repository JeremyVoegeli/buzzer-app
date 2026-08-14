resource "aws_apigatewayv2_integration" "rejoin_room_integration" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    integration_type = "AWS_PROXY"
    integration_uri = aws_lambda_function.rejoin_room_lambda.invoke_arn
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "rejoin_room_route" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    route_key = "rejoin_room"
    target = "integrations/${aws_apigatewayv2_integration.rejoin_room_integration.id}"
}