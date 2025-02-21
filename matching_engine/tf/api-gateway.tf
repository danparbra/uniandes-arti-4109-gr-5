resource "aws_api_gateway_rest_api" "matching_engine_api" {
  name = "matching_engine_api"
  body = jsonencode({
    "openapi" : "3.0.1",
    "info" : {
      "title" : "matching_engine_api",
      "version" : "2022-03-03T00:00:00Z"
    },
    "servers" : [{
      "variables" : {
        "basePath" : {
          "default" : "/default"
        }
      }
    }],
    "paths" : {
      "/submit" : {
        "post" : {
          "responses" : {
            "200" : {
              "description" : "200 response",
              "content" : {
                "application/json" : {
                  "schema" : {
                    "$ref" : "#/components/schemas/Empty"
                  }
                }
              }
            }
          },
          "x-amazon-apigateway-integration" : {
            "type" : "aws",
            "credentials" : "${aws_iam_role.matching_engine_api_role.arn}",
            "httpMethod" : "POST",
            "uri" : "arn:aws:apigateway:${var.aws_region}:sqs:path/${var.aws_account_id}/${aws_sqs_queue.cola_peticiones_fifo.name}",
            "responses" : {
              "default" : {
                "statusCode" : "200"
              }
            },
            "requestParameters" : {
              "integration.request.header.Content-Type" : "'application/x-www-form-urlencoded'"
            },
            "requestTemplates" : {
              "application/json" : "Action=SendMessage&MessageBody=$input.body&MessageGroupId=$input.json('$.MessageGroupId')"
            },
            "passthroughBehavior" : "never"
          }
        }
      }
    },
    "components" : {
      "schemas" : {
        "Empty" : {
          "title" : "Empty Schema",
          "type" : "object"
        }
      }
    }
  })
}

resource "aws_api_gateway_deployment" "rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.matching_engine_api.id
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "default"
  rest_api_id   = aws_api_gateway_rest_api.matching_engine_api.id
  deployment_id = aws_api_gateway_deployment.rest_api_deployment.id
}