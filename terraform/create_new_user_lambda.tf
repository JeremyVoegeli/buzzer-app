#creates zip archive of code
data "archive_file" "create_new_user_zip" {
    type = "zip"
    source_file = "../lambdas/create_new_user.py"
    output_path = "../zip_archive/create_new_user.zip"
}

#creates the actual lambda function
resource "aws_lambda_function" "create_new_user_lambda" {
    filename = data.archive_file.create_new_user_zip.output_path
    source_code_hash = data.archive_file.create_new_user_zip.output_base64sha256
    function_name = "create_new_user"
    role = aws_iam_role.create_new_user_role.arn
    runtime = "python3.13"
    handler = "create_new_user.lambda_handler"
}

#determines who is allowed to invoke the lambda
resource "aws_lambda_permission" "create_new_user_invoke_permissions" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.create_new_user_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
}