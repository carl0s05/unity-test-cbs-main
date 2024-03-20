provider "aws" {
  profile = var.profile
  region  = "us-east-1"

  default_tags {
    tags = {
      "Project"          = "CBS"
      "Owner"            = "aqujesus"
      "Environment"      = var.environment
      "Business Unit"    = "Unidad"
      "Cost Center"      = 0345
      "Service Name"     = var.appname
      "Application Role" = "Prueba"

    }
  }
}