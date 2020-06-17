# Terraform ApiGateway-SQS-Lambda integration
Example of a terraform script to setup an API Gateway endpoint that takes records and puts them into an SQS queue that will trigger an Event Source for AWS Lambda.

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




## License
This project is licensed under the MIT License - see the LICENSE.md file for details

## Acknowlegments
- [Andrew Loesch GitHub Gist](https://gist.github.com/afloesch/dc7d8865eeb91100648330a46967be25)
- https://www.terraform.io

## TO DO:

- [ ] Build project with different gitHub repo
- [ ] ApiGateway module with lambda
