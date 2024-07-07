terraform {
    backend "s3" {
        bucket = "qnt-clouds-for-pe-tfstate"
        key = "nikita-stepanenko/terraform.tfstate"
        region = "us-east-2"
    }
}

data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
    owners = ["099720109477"]
}

resource "aws_instance" "ec2_nikita_stepanenko" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t3a.small"
    subnet_id = "subnet-07549c87757e073ea"
    associate_public_ip_address = true
    user_data = <<-EOF
                #!/bin/bash
                apt-get update -y
                apt-get install -y docker.io
                systemctl start docker
                systemctl enable docker
                docker login -u ${var.dockerhub_username} -p ${var.dockerhub_password}
                docker pull ${var.dockerhub_username}/${var.dockerhub_repository}:${var.image_tag}
                docker run -d -p 80:5000 ${var.dockerhub_username}/${var.dockerhub_repository}:${var.image_tag}
                EOF
    security_groups = [aws_security_group.my_sg.id]
    tags = {
        Name = "ec2_nikita.stepanenko"
        env = "dev"
        owner = "nikita.stepanenko@quantori.com"
        project = "INFRA"
    }
}

resource "aws_ec2_instance_state" "stop_ec2_nikita_stepanenko" {
    instance_id = aws_instance.ec2_nikita_stepanenko.id
    state = "stopped"
}

resource "aws_security_group" "my_sg" {
    name = "sg_nikita.stepanenko"
    vpc_id = "vpc-024cf058980b63412"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["165.225.206.148/32"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_s3_bucket" "my_bucket" {
    bucket = "qnt-bucket-tf-nikita.stepanenko"
}


resource "aws_iam_role" "ec2_role" {
    name = "EC2_Role_nikita.stepanenko"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Action = "sts:AssumeRole",
            Principal = {
                Service = "ec2.amazonaws.com",
            },
            Effect = "Allow",
            Sid = "",
        },
        ]
    })
}

resource "aws_iam_policy" "s3_policy" {
    name   = "s3_nikita.stepanenko"
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Action   = "s3:*",
            Resource = "arn:aws:s3:::qnt-bucket-tf-nikita.stepanenko/*",
            Effect   = "Allow",
        },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
    name = "InstanceProfile_nikita.stepanenko"
    role = aws_iam_role.ec2_role.name
}
