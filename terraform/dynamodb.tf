resource "aws_dynamodb_table" "buzz_in" {
    name = "buzzes"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "room_id"
    range_key = "buzz_time"

    attribute {
        name = "room_id"
        type = "S"
    }

    attribute {
        name = "buzz_time"
        type = "S"
    }
}