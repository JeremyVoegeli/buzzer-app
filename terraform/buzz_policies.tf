# ---------- Role for Buzz Lambda ----------
resource "aws_iam_role" "buzz_role" {
    name = "buzz_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# ---------- DynamoDB Permissions ----------
data "aws_iam_policy_document" "dynamodb_buzz_permissions" {
    statement {
        effect = "Allow"
        actions = ["dynamodb:Query", "dynamodb:PutItem"]
        resources = [aws_dynamodb_table.buzz_in.arn]
    }

    statement {
        effect = "Allow"
        actions = ["dynamodb:Query", "dynamodb:DeleteItem"]
        resources = [aws_dynamodb_table.connected_users.arn]
    }
}

resource "aws_iam_policy" "buzz_dynamodb_policy" {
    name = "dynamodb_query_putitem_policies"
    policy = data.aws_iam_policy_document.dynamodb_buzz_permissions.json
}

resource "aws_iam_role_policy_attachment" "buzz_dynamodb_policy_attachment" {
    role = aws_iam_role.buzz_role.name
    policy_arn = aws_iam_policy.buzz_dynamodb_policy.arn
}

# ----------CloudWatch Logging Policy ----------
resource "aws_iam_role_policy_attachment" "attach_logging_policy_to_buzz" {
    role = aws_iam_role.buzz_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Attachment for API Gateway Policy ----------
resource "aws_iam_role_policy_attachment" "attach_apigateway_policy_to_buzz" {
    role = aws_iam_role.buzz_role.name
    policy_arn = aws_iam_policy.apigateway_policy.arn
}