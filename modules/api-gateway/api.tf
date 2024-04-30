resource "aws_iam_role" "api_gateway_role" {
  name = "${var.account}-iam-${var.env}-${var.system}-api-gateway-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["apigateway.amazonaws.com", "events.amazonaws.com", "lambda.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
  tags = {
    Name        = "${var.account}-iam-${var.env}-${var.system}-api-gateway-role",
    Environment = var.env,
    System      = var.system
  }
}

resource "aws_api_gateway_account" "iam_apigateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_role.arn
  lifecycle {
    ignore_changes = [
      cloudwatch_role_arn
    ]
  }
}

resource "aws_iam_role_policy" "apigateway-role-policy" {
  name = "${var.account}-iam-${var.env}-${var.system}-api-gateway-role-policy"
  role = aws_iam_role.api_gateway_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : [
          "events:PutRule",
          "events:ListRules",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "sqs:SendMessage"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.account}-api-gateway-${var.env}-${var.system}"
  description = "${var.system} API Gateway."

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name        = "${var.account}-api-gateway-${var.env}-${var.system}"
    Environment = var.env
    System      = var.system
  }
}

# Define the resources
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "identifier" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "identifier"
}

resource "aws_api_gateway_resource" "identifier_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.identifier.id
  path_part   = "{identifier}"
}

resource "aws_api_gateway_resource" "home" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "home"
}

resource "aws_api_gateway_resource" "home_authenticated" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.home.id
  path_part   = "authenticated"
}

# Define the methods
resource "aws_api_gateway_method" "identifier_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.identifier.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "identifier_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.identifier_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "identifier_id_patch" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.identifier_id.id
  http_method   = "PATCH"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "home_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.home.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "home_authenticated_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.home_authenticated.id
  http_method   = "GET"
  authorization = "NONE"
}

# Define integrations

resource "aws_api_gateway_integration" "identifier_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.identifier.id
  http_method             = aws_api_gateway_method.identifier_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.invoke_lambda_arn
}

resource "aws_api_gateway_integration" "identifier_id_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.identifier_id.id
  http_method             = aws_api_gateway_method.identifier_id_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.invoke_lambda_arn
}

resource "aws_api_gateway_integration" "identifier_id_patch" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.identifier_id.id
  http_method             = aws_api_gateway_method.identifier_id_patch.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.invoke_lambda_arn
}

resource "aws_api_gateway_integration" "home_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.home.id
  http_method             = aws_api_gateway_method.home_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.invoke_lambda_arn
}

resource "aws_api_gateway_integration" "home_authenticated_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.home_authenticated.id
  http_method             = aws_api_gateway_method.home_authenticated_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.invoke_lambda_arn
}

# Link the methods and integrations
resource "aws_api_gateway_integration_response" "identifier_post_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.identifier.id
  http_method = aws_api_gateway_method.identifier_post.http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_resource.identifier, aws_api_gateway_method.identifier_post, aws_api_gateway_integration.identifier_post]
}

resource "aws_api_gateway_integration_response" "identifier_id_get_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.identifier_id.id
  http_method = aws_api_gateway_method.identifier_id_get.http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_resource.identifier_id, aws_api_gateway_method.identifier_id_get, aws_api_gateway_integration.identifier_id_get]
}

resource "aws_api_gateway_integration_response" "identifier_id_patch_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.identifier_id.id
  http_method = aws_api_gateway_method.identifier_id_patch.http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_resource.identifier_id, aws_api_gateway_method.identifier_id_patch, aws_api_gateway_integration.identifier_id_patch]
}

resource "aws_api_gateway_integration_response" "home_get_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.home.id
  http_method = aws_api_gateway_method.home_get.http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_resource.home, aws_api_gateway_method.home_get, aws_api_gateway_integration.home_get]
}

resource "aws_api_gateway_integration_response" "home_authenticated_get_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.home_authenticated.id
  http_method = aws_api_gateway_method.home_authenticated_get.http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_resource.home_authenticated, aws_api_gateway_method.home_authenticated_get, aws_api_gateway_integration.home_authenticated_get]
}

resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled    = true
    data_trace_enabled = true
    logging_level      = "INFO"

    # Limit the rate of calls to prevent abuse and unwanted charges
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}

resource "aws_api_gateway_deployment" "main" {
  depends_on  = [aws_api_gateway_integration.identifier_post, aws_api_gateway_integration.identifier_id_get, aws_api_gateway_integration.identifier_id_patch, aws_api_gateway_integration.home_get, aws_api_gateway_integration.home_authenticated_get]
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.stage_name
}

//lambda invoker
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_lambda_permission" "main" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  qualifier     = var.function_alias_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*"
}