data "terraform_remote_state" "tf_cloudflare" {
  backend = "s3"

  config = {
    bucket = "mdekort-tfstate-075673041815"
    key    = "tf-cloudflare.tfstate"
    region = "eu-west-1"
  }
}

# Management account state, for the generic KMS key that repos decrypt secrets
# with at plan time. Read from state rather than hardcoded so a key rotation or
# replacement flows through instead of silently breaking every plan role.
data "terraform_remote_state" "tf_aws" {
  backend = "s3"

  config = {
    bucket = "mdekort-tfstate-075673041815"
    key    = "tf-aws.tfstate"
    region = "eu-west-1"
  }
}
