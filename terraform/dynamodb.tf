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

resource "aws_dynamodb_table" "connected_users" {
    name = "connections"
    billing_mode = "PAY_PER_REQUEST"
    has_key = "room_id"
    range_key = "connection_id"

    attribute {
        name = "room_id"
        type = "S"
    }

    attribute {
        name = "connection_id"
        type = "S"
    }
}