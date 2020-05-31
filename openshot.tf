# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
}

# data "aws_ami" "openshot_ami" {
#     most_recent = true
#     owners = ["aws-marketplace"]

#     filter {
#         name = "name"
#         values = ["*OpenShot*"]
#     }
# }

resource "aws_security_group" "openshot_allow_http_ssh" {
  name        = "allow_tls"
  description = "Allow HTTP and SSH inbound traffic"

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-01d025118d8e760db"
  instance_type = "t2.micro"
  security_groups =["${aws_security_group.openshot_allow_http_ssh.name}"]
  key_name = "MyKeyPair"

  tags = {
    Name = "HelloWorld"
  }
}