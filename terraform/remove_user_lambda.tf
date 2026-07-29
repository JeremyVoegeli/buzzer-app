data "archive_file" "remove_user_zip" {
    type = "zip"
    source_file = "../lambdas/remove_user.py"
    output_path = "../zip_archive/remove_user.zip"
}

resource "aws_lambda_function" "remove_user_lambda" {
    filename = data.archive_file.remove_user_zip.output_path
    source_code_hash = data.archive_file.remove_user_zip.output_base64sha256
    function_name = "remove_user"
    role = aws_iam_role.remove_user_role.arn
    runtime = "python3.13"
    handler = "remove_user.lambda_handler"
}

resource "aws_lambda_permission" "remove_user_invoke_permissions"{
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.remove_user_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
}