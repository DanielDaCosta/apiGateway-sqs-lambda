# ApiGateway-SQS-Lambda integration
Repository for building the following pipeline: 
- API Gateway
- SQS
- Lambda

The goal of this repo is to build Terraform modules for users

## Usage

Go into dev/ folder and run:

```terraform init```

Run ```terraform plan``` to check changes before apply.

Run ```terraform apply``` to deploy your changes into your AWS account.

Run ```terraform apply -var-file="name_of_file.tfvars"``` for applying environment variables.

## TO DO:

- [ ] Build project with different gitHub repo
- [ ] ApiGateway module with lambda
