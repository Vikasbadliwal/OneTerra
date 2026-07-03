terraform {
  backend "s3" {
    bucket       = "sonarbucket-oneclick"   
    key          = "sonarqube/prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}