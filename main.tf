variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
    default = "us-east-1"
}

variable "bucket_name" {}

variable "acl" {
    default = "private"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}

data "aws_ami" "aws-linux2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_default_vpc" "default" {
  
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH access"
  vpc_id = aws_default_vpc.default.id
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = -1
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mydockerapplication" {
    ami = data.aws_ami.aws-linux2.id
    instance_type = "t2.micro"
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]

    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = file(var.private_key_path)
    }

    provisioner "remote-exec" {
        inline = [
            "sudo yum install nginx -y",
            "sudo service nginx start"
        ]
    }
}

output "mydockerapplication_public_ip" {
    value = aws_instance.mydockerapplication.public_ip
}

resource "aws_s3_bucket" "application_s3_bucket" {
    bucket = "${var.bucket_name}" 
    acl = "${var.acl}"
       
}

output "s3_output" {
    value = aws_s3_bucket.application_s3_bucket.bucket
}

