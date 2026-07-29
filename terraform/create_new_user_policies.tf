resource "aws_iam_role" "create_new_user_role" {
    name = "create_new_user_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

#creates another JSON document ("What actions are allowed on what resource?")
data "aws_iam_policy_document" "dynamodb_write_permissions" {
    statement {
        effect = "Allow"
        actions = ["dynamodb:PutItem"]
        resources = [aws_dynamodb_table.connected_users.arn]
    }
}

#creates IAM policy out of block above
resource "aws_iam_policy" "dynamodb_write_policy" {
    name = "dynamodb_allow_lambda_writes_to_table"
    policy = data.aws_iam_policy_document.dynamodb_write_permissions.json
}

#link, attaches policy to role
resource "aws_iam_role_policy_attachment" "dynamodb_write_policy_attachment" {
    role = aws_iam_role.create_new_user_role.name
    policy_arn = aws_iam_policy.dynamodb_write_policy.arn
}