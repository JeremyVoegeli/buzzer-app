#creates JSON document ("Who can assume this role?")
data "aws_iam_policy_document" "lambda_trust" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

#actual IAM role in AWS account, plugs in policy from block above
resource "aws_iam_role" "lambda_role" {
    name = "lambda_write_connected_users_db_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

#creates another JSON document ("What items are allowed on what resource?")
data "aws_iam_policy_document" "dynamodb_write_permissions" {
    statement {
        effect = "Allow"
        actions = ["dynamodb:PutItem"]
        resources = [aws_dynamodb_table.connected_users.arn]
    }
}

#creates IAM policy out of block above
resource "aws_iam_policy" "dynamodb_policy" {
    name = "dynamodb_allow_lambda_writes_to_table"
    policy = data.aws_iam_policy_document.dynamodb_write_permissions.json
}

#link, attaches policy to role
resource "aws_iam_role_policy_attachment" "attach_lambda_policy_to_dynamodb" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.dynamodb_policy.arn
}

#another link, attaches pre-defined AWS policy to same role
resource "aws_iam_role_policy_attachment" "attach_lambda_logging_policy" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

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
    role = aws_iam_role.lambda_role.arn
    runtime = "python3.13"
    handler = "create_new_user.lambda_handler"
}

#determines who is allowed to invoke the lambda
resource "aws_lambda_permission" "lambda_invoke_permissions" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.create_new_user_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = 
}