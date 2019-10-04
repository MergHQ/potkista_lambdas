
data "archive_file" "init" {
  type = "zip"
  source_dir = "${path.module}/src"
  output_path = "${path.module}/output/v5/src.zip"
}

provider "aws" {
  version = "~> 2.0"
  region  = "eu-central-1"
}

resource "aws_iam_role" "potkista_lambda_iam_role" {
  name = "potkista_lambda_iam_role"

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

resource "aws_lambda_function" "potkista_lambda" {
  filename      = "${path.module}/output/v5/src.zip"
  function_name = "potkista_lamda"
  role          = "${aws_iam_role.potkista_lambda_iam_role.arn}"
  handler       = "exports.handler"

  runtime = "nodejs10.x"
}

resource "aws_api_gateway_rest_api" "potkista_lambda_gateway" {
  name        = "potkistaRestGateway"
  description = "Routing to potkista lambda"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.potkista_lambda_gateway.id}"
  parent_id   = "${aws_api_gateway_rest_api.potkista_lambda_gateway.root_resource_id}"
  path_part   =  "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.potkista_lambda_gateway.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.potkista_lambda_gateway.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.potkista_lambda.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.potkista_lambda_gateway.id}"
  resource_id   = "${aws_api_gateway_rest_api.potkista_lambda_gateway.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.potkista_lambda_gateway.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.potkista_lambda.invoke_arn}"
}

resource "aws_api_gateway_deployment" "potkista_apigw_deployment" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.potkista_lambda_gateway.id}"
  stage_name  = "prod"
}

resource "aws_lambda_permission" "potkista_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.potkista_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.potkista_lambda_gateway.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.potkista_apigw_deployment.invoke_url}"
}
