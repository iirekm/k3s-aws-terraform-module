provider "aws" {
  region = "eu-north-1"
}

module "k3s" {
  source = "./.." // replace with git@github.com:iirekm/k3s-aws-terraform-module.git

  // override defaults here (see variable entries k3s.tf)
}
