terraform {
  required_version = "= 1.15.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.53.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.7.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "= 4.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 3.2.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 3.2.0"
    }
  }

  backend "s3" {
    bucket       = "jjp6402-terraform"
    key          = "environment/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
