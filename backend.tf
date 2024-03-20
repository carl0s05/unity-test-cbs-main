terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    region  = "us-east-1"
    profile = "cbs-non-prod-dev-xxxxx"
    key     = "dev-test"
    bucket  = "aqujesus-cbs-dev-eks-bucket-backend"
  }
}