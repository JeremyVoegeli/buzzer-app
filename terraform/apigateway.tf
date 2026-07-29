resource "aws_apigatewayv2_api" "websocket_api" {
    name = "websocket_api"
    protocol_type = "WEBSOCKET"
    route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_deployment" "websocket_api_deployment" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    depends_on = [ #<- says, "don't create this resource until create_user_route is created"
        aws_apigatewayv2_route.create_user_route,
        aws_apigatewayv2_route.remove_user_route
        ]
}

resource "aws_apigatewayv2_stage" "websocket_api_stage" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    name = "prod"
    deployment_id = aws_apigatewayv2_deployment.websocket_api_deployment.id
}