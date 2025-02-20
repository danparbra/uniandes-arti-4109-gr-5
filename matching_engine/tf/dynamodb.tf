resource "aws_dynamodb_table" "libro_de_ordenes" {
  name         = "ordenes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ordenId"
  # range_key      = "timestamp"

  attribute {
    name = "ordenId"
    type = "S"
  }
}