resource "aws_lambda_function" "matching_engine_lambda" {
  function_name                  = "matching_engine_lambda"
  filename                       = "../lambda.zip"
  role                           = aws_iam_role.matching_engine_lambda_role.arn
  source_code_hash               = data.archive_file.lambda_zip.output_base64sha256
  runtime                        = "python3.9"
  handler                        = "main.handler"
  reserved_concurrent_executions = -1
  timeout                        = 30
}

data "archive_file" "lambda_zip" {
  source_dir  = "../src/matching_engine_lambda/"
  output_path = "../lambda.zip"
  type        = "zip"
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn        = aws_sqs_queue.cola_peticiones_fifo.arn
  function_name           = aws_lambda_function.matching_engine_lambda.arn
  enabled                 = true
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
  scaling_config {
    maximum_concurrency = 3
  }
}

resource "aws_lambda_function_url" "matching_engine_lambda_url" {
  function_name      = aws_lambda_function.matching_engine_lambda.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allows_sqs_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.matching_engine_lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.cola_peticiones_fifo.arn
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
      "Resource": "arn:aws:sqs:${var.aws_region}:${var.aws_account_id}:*"
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