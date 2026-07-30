data "archive_file" "buzz_zip" {
    type = "zip"
    source_file = "../lambdas/buzz.py"
    output_path = "../zip_archive/buzz.zip"
}

resource "aws_lambda_function" "buzz_lambda" {
    filename = data.archive_file.buzz_zip.output_path
    source_code_hash = data.archive_file.buzz_zip.output_base64sha256
    function_name = "buzz"
    role = aws_iam_role.buzz_role.arn
    runtime = "python3.13"
    handler = "buzz.lambda_handler"
}

resource "aws_lambda_permission" "buzz_invoke_permissions" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.buzz_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
}