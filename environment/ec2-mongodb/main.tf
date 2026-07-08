variable "name_prefix" { type = string }
variable "subnet_id" { type = string }
variable "vpc_id" { type = string }
variable "allowed_ssh_cidr" { type = string }
variable "eks_security_group_id" { type = string }
variable "instance_profile_name" { type = string }
variable "backup_bucket_name" { type = string }
variable "mongodb_version" { type = string }
variable "admin_user" { type = string }
variable "admin_password" { type = string, sensitive = true }
variable "app_user" { type = string }
variable "app_password" { type = string, sensitive = true }
variable "app_database" { type = string }

data "aws_ami" "ubuntu_1804" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "mongodb" {
  name        = "${var.name_prefix}-mongodb-sg"
  description = "MongoDB VM security group."
  vpc_id      = var.vpc_id

  ingress {
    description = "public ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description     = "mongodb from eks"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-mongodb-sg" }
}

data "aws_region" "current" {}

locals {
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    mongodb_version = var.mongodb_version
    admin_user      = var.admin_user
    admin_password  = var.admin_password
    app_user        = var.app_user
    app_password    = var.app_password
    app_database    = var.app_database
    backup_bucket   = var.backup_bucket_name
    aws_region      = data.aws_region.current.name
  })
}

resource "aws_instance" "mongodb" {
  ami                         = data.aws_ami.ubuntu_1804.id
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mongodb.id]
  iam_instance_profile        = var.instance_profile_name
  user_data                   = local.user_data

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "${var.name_prefix}-mongodb-vm" }
}

output "private_ip" { value = aws_instance.mongodb.private_ip }
output "public_ip" { value = aws_instance.mongodb.public_ip }
output "security_group_id" { value = aws_security_group.mongodb.id }
