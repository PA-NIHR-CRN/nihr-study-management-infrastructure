resource "aws_lambda_function" "authorizer" {
  filename         = "./modules/.build/lambda_auth/lambda_auth.zip"
  function_name    = "${var.account}-lambda-authorizer-${var.env}-${var.system}"
  timeout          = 60
  role             = aws_iam_role.lambda_auth_role.arn
  handler          = "NIHR.StudyManagement.Api.Authorizer::NIHR.StudyManagement.Api.Authorizer.Function::FunctionHandler"
  publish          = true # don't need this if updating code outside of terrafrom
  runtime          = "dotnet6"
  source_code_hash = filebase64sha256("./modules/.build/lambda_auth/lambda_auth.zip")

  environment {
    variables = {
      WSO2_SERVICE_AUDIENCES      = var.wso2_service_audiences
      WSO2_SERVICE_ISSUER         = var.wso2_service_issuer
      WSO2_SERVICE_TOKEN_ENDPOINT = var.wso2_service_token_endpoint
    }
  }
  lifecycle {
    ignore_changes = [
      version,
      qualified_arn,
      memory_size
    ]
  }
  tags = {
    Name        = "${var.account}-lambda-authorizer-${var.env}-${var.system}"
    Environment = var.env
    System      = var.system
  }
}

# lambda logging
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.authorizer.function_name}"
  retention_in_days = var.retention_in_days
  tags = {
    Name        = "${var.account}-lambda-authorizer-${var.env}-${var.system}"
    Environment = var.env
    System      = var.system
  }
}

resource "aws_iam_role" "lambda_auth_role" {
  name               = "${var.account}-iam-${var.env}-${var.system}-lambda-auth-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_auth_role_assume_role_policy.json
  tags = {
    Name        = "${var.account}-iam-${var.env}-${var.system}-lambda-auth-role"
    Environment = var.env
    System      = var.system
  }
}

resource "aws_iam_role_policy_attachment" "lambda" {
  policy_arn = aws_iam_policy.lambda.arn
  role       = aws_iam_role.lambda_auth_role.name
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.account}-iam-${var.env}-${var.system}-lambda-auth-role-policy"
  policy = data.aws_iam_policy_document.lambda.json
  tags = {
    Name        = "${var.account}-iam-${var.env}-${var.system}-lambda-auth-role-policy"
    Environment = var.env
    System      = var.system
  }
}

data "aws_iam_policy_document" "lambda_auth_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"]
    actions   = ["lambda:InvokeFunction"]
  }

  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    actions = [
      "logs:CreateLogGroup",
    ]
  }

  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
  }

  statement {
    sid    = "CognitoIdenitity"
    effect = "Allow"
    actions = [
      "cognito-identity:*",
      "cognito-idp:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "GetSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    sid    = "ListSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }
}


output "function_name" {
  value = aws_lambda_function.authorizer.function_name
}


