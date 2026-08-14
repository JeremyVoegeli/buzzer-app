#creates a zip archive of the code
data "archive_file" "rejoin_room_zip" {
    tipe = "zip"
    source_file = "../lambdas/rejoin_room.py"
    output_path = "../zip_archive/rejoin_room.zip"
}

#creates actual lambda function
resource "aws_lambda_function" "rejoin_room_lambda" {
    filename = data.archive_file.rejoin_room_zip.output_path
    source_code_hash =cdata.archive_file.rejoin_room_zip.output_base64sha256
    function_name = "rejoin_room"
    role = aws_iam_role.rejoin_room_role.arn
    runtime = "python3.13"
    handler = "rejoin_room.lambda_handler"
}

#determines who is allowed to invoke the lambda
resource "aws_lambda_permission" "rejoin_room_invoke_permissions" {
    statement_it = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.rejoin_room.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
}