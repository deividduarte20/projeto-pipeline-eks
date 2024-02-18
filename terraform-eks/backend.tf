terraform {
  backend "s3" {
    bucket         = "$buck" # Insira nome do bucket
    key            = "state/terraform.tfstate" # Insira o nome do arquivo para state
    region         = "us-east-1"
  }
}