variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "aws_account_id" {
  type    = string
  default = "552709242511"
}

variable "name_prefix" {
  type    = string
  default = "jjp6402"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.1.0.0/24"
}

variable "private_subnet_az2_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "eks_version" {
  type    = string
  default = "1.36"
}

variable "mongodb_version" {
  type    = string
  default = "5.0.21"
}

variable "mongodb_admin_user" {
  type    = string
  default = "mongo_admin"
}

variable "mongodb_app_user" {
  type    = string
  default = "tasky_app"
}

variable "mongodb_app_database" {
  type    = string
  default = "go-mongodb"
}

variable "allowed_ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
