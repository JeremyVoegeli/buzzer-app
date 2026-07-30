resource "aws_apigatewayv2_api" "websocket_api" {
    name = "websocket_api"
    protocol_type = "WEBSOCKET"
    route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_deployment" "websocket_api_deployment" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    triggers = {
        redeployment = join(",", [
            aws_apigatewayv2_route.create_user_route.id,
            aws_apigatewayv2_route.remove_user_route.id,
            aws_apigatewayv2_route.clear_buzzes_route.id,
            aws_apigatewayv2_route.buzz_route.id
        ])
    }
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_apigatewayv2_stage" "websocket_api_stage" {
    api_id = aws_apigatewayv2_api.websocket_api.id
    name = "prod"
    deployment_id = aws_apigatewayv2_deployment.websocket_api_deployment.id
}