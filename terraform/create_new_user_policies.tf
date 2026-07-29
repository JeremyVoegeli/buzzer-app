# ---------- Role for create_new_user Lambda ----------
resource "aws_iam_role" "create_new_user_role" {
    name = "create_new_user_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# ---------- DynamoDB Write Permissions ----------
data "aws_iam_policy_document" "dynamodb_write_permissions" {
    statement {
        effect = "Allow"
        actions = ["dynamodb:PutItem"]
        resources = [aws_dynamodb_table.connected_users.arn]
    }
}

resource "aws_iam_policy" "dynamodb_write_policy" {
    name = "dynamodb_allow_lambda_writes_to_table"
    policy = data.aws_iam_policy_document.dynamodb_write_permissions.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_write_policy_attachment" {
    role = aws_iam_role.create_new_user_role.name
    policy_arn = aws_iam_policy.dynamodb_write_policy.arn
}

# ---------- CloudWatch Logging Policy ----------
resource "aws_iam_role_policy_attachment" "attach_logging_policy_to_create_new_user" {
    role = aws_iam_role.create_new_user_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Attachment for API Gateway Policy ----------
resource "aws_iam_role_policy_attachment" "attach_apigateway_policy_to_lambda" {
    role = aws_iam_role.create_new_user_role.name
    policy_arn = aws_iam_policy.apigateway_policy.arn
}