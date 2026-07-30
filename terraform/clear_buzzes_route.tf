resource "aws_apigatewayv2_integration" "clear_buzzes_integration" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    integration_type = "AWS_PROXY"
    integration_uri = aws_lambda_function.remove_user_lambda.invoke_arn
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "clear_buzzes_route" {
    api_id = aws_apigatewayv2_api,websocket_api.id
    route_key = "clear_buzzes"
    tagret = "integrations/${aws_apigatewayv2_integration.clear_buzzes_integration.id}"
}