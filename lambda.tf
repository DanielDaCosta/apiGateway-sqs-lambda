data "archive_file" "lambda_with_dependencies" {
  source_dir  = "lambda/"
  output_path = "lambda/${var..app_name}-${var.lambda_name}.zip"
  type        = "zip"
}

resource "aws_lambda_function" "lambda_sqs" {
  function_name    = "${var.app_name}-${var.lambda_name}"
  handler          = "handler.lambda_handler"
  role             = aws_iam_role.lambda_exec_role.arn
  runtime          = "python3.7"

  filename         = data.archive_file.lambda_with_dependencies.output_path
  source_code_hash = data.archive_file.lambda_with_dependencies.output_base64sha256

  timeout          = 30
  memory_size      = 128
}

resource "aws_lambda_permission" "allows_sqs_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sqs.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.queue.arn
}
