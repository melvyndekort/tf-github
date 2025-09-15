data "aws_kms_secrets" "secrets" {
  secret {
    name    = "secrets"
    payload = file("secrets.yaml.encrypted")

    context = {
      target = "tf-github"
    }
  }
}

locals {
  secrets = yamldecode(data.aws_kms_secrets.secrets.plaintext["secrets"])
}
