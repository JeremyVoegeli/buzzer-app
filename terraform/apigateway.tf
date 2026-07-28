resource "aws_apigatewayv2_api" "websocket_api" {
    name = "websocket_api"
    protocol_type = "WEBSOCKET"
    route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_integration" "api_integration" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    integration_type = "AWS_PROXY"
    integration_uri = aws_lambda_function.create_new_user_lambda.invoke_arn
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "create_user_route" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    route_key = "create_user"
    target = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}

resource "aws_apigatewayv2_deployment" "websocket_api_deployment" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    depends_on = [aws_apigatewayv2_route.create_user_route] #<- says, "don't create this resource until create_user_route is created"
}