resource "aws_dynamodb_table" "my_dynamo_table" {
    name = "buzzes"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "room_id"
    range_key = "timestamp"

    attribute {
        name = "room_id"
        type = "S"
    }

    attribute {
        name = "timestamp"
        type = "S"
    }
}