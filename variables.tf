variable "environment" {
    description = "Env"
    default     = "dev"
}

variable "name" {
    description = "Application Name"
    type        = string
}

variable {
    description = "Aplication Name - ENV"
    app_name = "${var.name}-${var.environment}"
}

variable "region" {
    default = "us-east-1"
}

variable "lambda_name" {
    description = "Name for lambda function"
    default = "lambda"
}
