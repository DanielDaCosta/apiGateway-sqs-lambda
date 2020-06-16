# IAM role so API Gateway has the necessary permissions to SendMessage to SQS queue

resource "aws_iam_role" "apiSQS" {
  name = "apigateway_sqs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "template_file" "gateway_policy" {
  template = file("policies/api-gateway-permission.json")

  vars = {
    sqs_arn   = aws_sqs_queue.queue.arn
  }
}

resource "aws_iam_policy" "api_policy" {
  name = "api-sqs-cloudwatch-policy"

  policy = data.template_file.gateway_policy.rendered
}


resource "aws_iam_role_policy_attachment" "api_exec_role" {
  role       =  aws_iam_role.apiSQS.name
  policy_arn =  aws_iam_policy.api_policy.arn
}

# Add a Lambda permission that allows the specific SQS to invoke it

data "template_file" "lambda_policy" {
  template = file("policies/lambda-permission.json")

  vars = {
    sqs_arn   = aws_sqs_queue.queue.arn
  }
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda_policy_db"
  description = "IAM policy for lambda Being invoked by SQS"

  policy = data.template_file.lambda_policy.rendered
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "${var.name}-lambda-db"
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

resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}