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


# Trigger lambda on message to SQS
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size       = 1
  event_source_arn =  aws_sqs_queue.queue.arn
  enabled          = true
  function_name    =  aws_lambda_function.lambda_sqs.arn
}