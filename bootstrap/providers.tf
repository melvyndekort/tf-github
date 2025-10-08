terraform {
  required_version = "~> 1.10"

  backend "s3" {
    bucket       = "mdekort.tfstate"
    key          = "tf-github-bootstrap.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}
