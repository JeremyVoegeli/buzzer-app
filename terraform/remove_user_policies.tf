# ---------- Role for remove_user Lambda ----------
resource "aws_iam_role" "remove_user_role" {
    name = "remove_user_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# ---------- DynamoDB Delete Permissions ----------
data "aws_iam_policy_document" "dynamodb_delete_permissions" {
    statement {
        effect = "Allow"
        actions = ["dynamodb:DeleteItem"]
        resources = [aws_dynamodb_table.connected_users.arn]
    }
}

resource "aws_iam_policy" "dynamodb_delete_policy" {
    name = "dynamodb_allow_deleting_entries"
    policy = data.aws_iam_policy_document.dynamodb_delete_permissions.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_delete_policy_attachment" {
    role = aws_iam_role.remove_user_role.name
    policy_arn = aws_iam_policy.dynamodb_delete_policy.arn
}

# ----------CloudWatch Logging Policy ----------
resource "aws_iam_role_policy_attachment" "attach_logging_policy_to_remove_user" {
    role = aws_iam_role.remove_user_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Attachment for API Gateway Policy ----------
resource "aws_iam_role_policy_attachment" "attach_apigateway_policy_to_remove_user" {
    role = aws_iam_role.remove_user_role.name
    policy_arn = aws_iam_policy.apigateway_policy.arn
}