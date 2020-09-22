# Terraform ApiGateway-SQS-Lambda integration
Example of a terraform script to setup an API Gateway endpoint that takes records and puts them into an SQS queue that will trigger an Event Source for AWS Lambda.

When deployed, you'll have a public endpoint that will write to SQS with a Lambda function that will consume from it

For more informations check the [Medium post](https://medium.com/@danieldacosta_75030/building-an-apigateway-sqs-lambda-integration-using-terraform-5617cc0408ad).

## Getting Started

This project follows the following file structure:

```
├── LICENSE
├── README.md
├── apiGateway.tf
├── iam.tf
├── lambda: folder for lambda code
│   ├── handler.py
│   └── sqs-integration-dev-lambda.zip
├── lambda.tf
├── main.tf
├── policies: all policies created
│   ├── api-gateway-permission.json
│   └── lambda-permission.json
├── sqs.tf
├── terraform.tfstate
├── terraform.tfstate.backup
├── variables.tf: defining variables that will be used inside terraform templates
└── variables.tfvars: input variables
```

## Usage
Run ```terraform init``` to initialize the working directory containing Terraform configuration files.

Run ```terraform apply -var-file="variables.tfvars"``` for applying environment variables.

## Details

### SQS

Building SQS

```
resource "aws_sqs_queue" "queue" {
  name                      = "apigateway-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = {
    Product = local.app_name
  }
}
```

### IAM

Defining permissions so that API Gateway has the necessary permissions to SendMessage to SQS queue.

```
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
```

Add a Lambda permission that allows the specific SQS to invoke it

```
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
```

### ApiGateway

Creating ApiGateway resource

```
resource "aws_api_gateway_rest_api" "apiGateway" {
  name        = "api-gateway-SQS"
  description = "POST records to SQS queue"
}
```
Adding a resource to our root with a path of ```form_score```. Adding and validating a *query_string_parameter*.

```
resource "aws_api_gateway_resource" "form_score" {
    rest_api_id = aws_api_gateway_rest_api.apiGateway.id
    parent_id   = aws_api_gateway_rest_api.apiGateway.root_resource_id
    path_part   = "form-score"
}

resource "aws_api_gateway_request_validator" "validator_query" {
  name                        = "queryValidator"
  rest_api_id                 = aws_api_gateway_rest_api.apiGateway.id
  validate_request_body       = false
  validate_request_parameters = true
}

resource "aws_api_gateway_method" "method_form_score" {
    rest_api_id   = aws_api_gateway_rest_api.apiGateway.id
    resource_id   = aws_api_gateway_resource.form_score.id
    http_method   = "POST"
    authorization = "NONE"

    request_parameters = {
      "method.request.path.proxy"        = false
      "method.request.querystring.unity" = true
  }

  request_validator_id = aws_api_gateway_request_validator.validator_query.id
}
```
Defining an ApiGateway integration with SQS. A *request_template* was added in order to pass the Method, Body, QueryParameters and path Parameters in the SQS message.

```
resource "aws_api_gateway_integration" "api" {
  rest_api_id             = aws_api_gateway_rest_api.apiGateway.id
  resource_id             = aws_api_gateway_resource.form_score.id
  http_method             = aws_api_gateway_method.method_form_score.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  credentials             = aws_iam_role.apiSQS.arn
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${aws_sqs_queue.queue.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  # Request Template for passing Method, Body, QueryParameters and PathParams to SQS messages
  request_templates = {
    "application/json" = <<EOF
Action=SendMessage&MessageBody={
  "method": "$context.httpMethod",
  "body-json" : $input.json('$'),
  "queryParams": {
    #foreach($param in $input.params().querystring.keySet())
    "$param": "$util.escapeJavaScript($input.params().querystring.get($param))" #if($foreach.hasNext),#end
  #end
  },
  "pathParams": {
    #foreach($param in $input.params().path.keySet())
    "$param": "$util.escapeJavaScript($input.params().path.get($param))" #if($foreach.hasNext),#end
    #end
  }
}"
EOF
  }

  depends_on = [
    aws_iam_role_policy_attachment.api_exec_role
  ]
}
```
 Define a basic 200 handler for successful requests.
 ```
 # Mapping SQS Response
resource "aws_api_gateway_method_response" "http200" {
  rest_api_id = aws_api_gateway_rest_api.apiGateway.id
  resource_id = aws_api_gateway_resource.form_score.id
  http_method = aws_api_gateway_method.method_form_score.http_method
  status_code = 200
}

resource "aws_api_gateway_integration_response" "http200" {
  rest_api_id       = aws_api_gateway_rest_api.apiGateway.id
  resource_id       = aws_api_gateway_resource.form_score.id
  http_method       = aws_api_gateway_method.method_form_score.http_method
  status_code       = aws_api_gateway_method_response.http200.status_code
  selection_pattern = "^2[0-9][0-9]"                                       // regex pattern for any 200 message that comes back from SQS

  depends_on = [
    aws_api_gateway_integration.api
    ]
}
 ```
Finally, we can add the API Gateway REST Deployment in order to deploy our endpoint. A redeployment trigger was added. This configuration calculates a hash of the API's Terraform resources to determine changes that should trigger a new deployment.
 ```
 resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.apiGateway.id
  stage_name  = var.environment

  depends_on = [
    aws_api_gateway_integration.api,
  ]

  # Redeploy when there are new updates
  triggers = {
    redeployment = sha1(join(",", list(
      jsonencode(aws_api_gateway_integration.api),
    )))
  }

  lifecycle {
    create_before_destroy = true
  }
}
 ```

### Lambda
```
data "archive_file" "lambda_with_dependencies" {
  source_dir  = "lambda/"
  output_path = "lambda/${local.app_name}-${var.lambda_name}.zip"
  type        = "zip"
}

resource "aws_lambda_function" "lambda_sqs" {
  function_name    = "${local.app_name}-${var.lambda_name}"
  handler          = "handler.lambda_handler"
  role             = aws_iam_role.lambda_exec_role.arn
  runtime          = "python3.7"

  filename         = data.archive_file.lambda_with_dependencies.output_path
  source_code_hash = data.archive_file.lambda_with_dependencies.output_base64sha256

  timeout          = 30
  memory_size      = 128

  depends_on = [
    aws_iam_role_policy_attachment.lambda_role_policy
  ]
}
```
Lastly, adding a permission so that SQS can invoke the lambda and adding an event source so that SQS can trigger the lambda.
```
resource "aws_lambda_permission" "allows_sqs_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sqs.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.queue.arn
}

# Trigger lambda on message to SQS
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size       = 1
  event_source_arn =  aws_sqs_queue.queue.arn
  enabled          = true
  function_name    =  aws_lambda_function.lambda_sqs.arn
}
```

## License
This project is licensed under the MIT License - see LICENSE.md file for details

## References & Acknowlegments

- Special thanks to [Andrew Loesch GitHub Gist](https://gist.github.com/afloesch/dc7d8865eeb91100648330a46967be25)
- https://www.terraform.io
- https://medium.com/appetite-for-cloud-formation/setup-lambda-to-event-source-from-sqs-in-terraform-6187c5ac2df1
