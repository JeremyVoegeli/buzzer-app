data "archive_file" "clear_buzzes_zip" {
    type = "zip"
    source_file = "../lambdas/clear_buzzes.py"
    output_path = "../zip_archive/clear_buzzes.zip"
}

resource "aws_lambda_function" "clear_buzzes_lambda" {
    filename = data.archive_file.clear_buzzes_zip.output_path
    source_code_hash = data.archive_file.create_new_user_zip.output_base64sha256
    function_name = "clear_buzzes"
    role = 
    runtime = "python3.13"
    handler = "clear_buzzes.lambda_handler"
}

resource "aws_lambda_permission" "clear_buzzes_invoke_permissions" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.clear_buzzes_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
}