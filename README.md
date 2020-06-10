# aws-terraform
Repository for mananging modules with Terraform in AWS

## Usage

Go into dev/ folder and run:

```terraform init```

Run ```terraform plan``` to check changes before apply.

Run ```terraform apply``` to deploy your changes into your AWS account.

Run ```terraform apply -var-file="name_of_file.tfvars"``` for applying environment variables.

## TO DO:

- [ ] Build project with different gitHub repo
- [ ] ApiGateway module with lambda
