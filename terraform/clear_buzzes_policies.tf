# ---------- Role for clear_buzzes Lambda ----------
resource "aws_iam_role" "clear_buzzes_role" {
    name = "clear_buzzes_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# ---------- DynamoDB Permissions ----------
data "aws_iam_policy_document" "dynamodb_clear_buzzes_permissions" {
    statement {
        effect = "Allow"
        actions = ["dynamodb:Query", "dynamodb:BatchWriteItem"]
        resources = [aws_dynamodb_table.buzz_in.arn]
    }
}

resource "aws_iam_policy" "clear_buzzes_dynamodb_policy" {
    name = "dynamodb_query_batch_write_policies"
    policy = data.aws_iam_policy_document.dynamodb_clear_buzzes_permissions.json
}

resource "aws_iam_role_policy_attachment" "clear_buzzes_dynamodb_policy_attachment" {
    role = aws_iam_role.clear_buzzes_role.name
    policy_arn = aws_iam_policy.clear_buzzes_dynamodb_policy.arn
}

# ----------CloudWatch Logging Policy ----------
resource "aws_iam_role_policy_attachment" "attach_logging_policy_to_clear_buzzes" {
    role = aws_iam_role.clear_buzzes_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Attachment for API Gateway Policy ----------
resource "aws_iam_role_policy_attachment" "attach_apigateway_policy_to_clear_buzzes" {
    role = aws_iam_role.clear_buzzes_role.name
    policy_arn = aws_iam_policy.apigateway_policy.arn
}