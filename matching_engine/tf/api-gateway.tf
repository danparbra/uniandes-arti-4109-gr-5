resource "aws_api_gateway_rest_api" "matching_engine_api" {
  name = "matching_engine_api"
}

resource "aws_api_gateway_resource" "matching_engine_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.matching_engine_api.id
  parent_id   = aws_api_gateway_rest_api.matching_engine_api.root_resource_id
  path_part   = "match"
}

resource "aws_api_gateway_method" "matching_engine_api_method" {
  rest_api_id      = aws_api_gateway_rest_api.matching_engine_api.id
  resource_id      = aws_api_gateway_resource.matching_engine_api_resource.id
  api_key_required = false
  http_method      = "POST"
  authorization    = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.matching_engine_api.id
  resource_id             = aws_api_gateway_resource.matching_engine_api_resource.id
  http_method             = aws_api_gateway_method.matching_engine_api_method.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"
  credentials             = aws_iam_role.matching_engine_api_role.arn
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${aws_sqs_queue.cola_peticiones_fifo.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

resource "aws_api_gateway_deployment" "rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.matching_engine_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.matching_engine_api_resource.id,
      aws_api_gateway_method.matching_engine_api_method.id,
      aws_api_gateway_integration.lambda_integration.id
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.matching_engine_api.id
  deployment_id = aws_api_gateway_deployment.rest_api_deployment.id
}

# resource "aws_lambda_permission" "allow_api_gw_matching_engine" {
#     statement_id  = "AllowExecutionFromAPIGateway"
#     action        = "lambda:InvokeFunction"
#     function_name = aws_lambda_function.matching_engine_lambda.function_name
#     principal     = "apigateway.amazonaws.com"
#     source_arn    = "${aws_api_gateway_rest_api.matching_engine_api.execution_arn}/*/*"
# }