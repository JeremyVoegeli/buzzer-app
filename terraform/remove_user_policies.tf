resource "aws_iam_role" "remove_user_role" {
    name = "remove_user_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

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

resource "aws_iam_policy_attachment" "dynamodb_delete_policy_attachment" {
    role = aws_iam_role.remove_user_role.name
    policy_arn = aws_iam_policy.dynamodb_delete_policy.arn
}