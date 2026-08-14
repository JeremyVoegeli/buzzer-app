# ---------- Role for rejoin_room Lambda ----------
resource "aws_iam_role" "rejoin_room_role" {
    name = "rejoin_room_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# ---------- DynamoDB Permissions ----------
data "aws_iam_policy_document" "dynamodb_rejoin_room_permissions"{
    statement {
        effect = "Allow"
        actions = ["dynamodb:Query", "dynamodb:PutItem", "dynamodb:DeleteItem"]
        resources = [aws_dynamodb_table.connected_users.arn]
    }
}

resource "aws_iam_policy" "rejoin_room_dynamodb_policy" {
    name = "dynamodb_query_putitem_delete_policies"
    policy = data.aws_iam_policy_document.dynamodb_rejoin_room_permissions.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_rejoin_room_policy_attachment" {
    role = aws_iam_role.rejoin_room_role.name
    policy_arn = aws_iam_policy.dynamodb_write_policy.arn
}

# ---------- CloudWatch Logging Policy ----------
resource "aws_iam_role_policy_attachment" "attach_logging_policy_to_rejoin_room" {
    role = aws_iam_role.rejoin_room_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Attachment for API Gateway Policy ----------
resource "aws_iam_role_policy_attachment" "attach_apigateway_policy_to_rejoin_room" {
    role = aws_iam_role.rejoin_room_role.name
    policy_arn = aws_iam_policy.apigateway_policy.arn
}