resource "aws_lambda_function" "matching_engine_lambda" {
  function_name                  = "matching_engine_lambda"
  filename                       = "matching_engine_lambda.zip"
  role                           = aws_iam_role.matching_engine_lambda_role.arn
  source_code_hash               = filebase64sha256("../matching_engine_lambda.zip")
  runtime                        = "python3.6"
  handler                        = "main.handler"
  reserved_concurrent_executions = 1000
  timeout                        = 60
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.cola_peticiones_fifo.arn
  function_name    = aws_lambda_function.matching_engine_lambda.arn
  enabled          = true
  batch_size       = 10
}

resource "aws_iam_role" "matching_engine_lambda_role" {
  name               = "matching-engine-lambda-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "matching_engine_lambda_policy" {
  name   = "matching-engine-lambda-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sqs_queue.cola_peticiones_fifo.arn}"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "matching_engine_lambda_policy_attachment" {
  policy_arn = aws_iam_policy.matching_engine_lambda_policy.arn
  role       = aws_iam_role.matching_engine_lambda_role.name
}