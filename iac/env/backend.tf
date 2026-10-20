# State is stored locally for now.
# For shared use, switch to a remote S3 backend:
#
# terraform {
#   backend "s3" {
#     bucket       = "my-terraform-state-bucket"
#     key          = "lambda-template/terraform.tfstate"
#     region       = "us-east-1"
#     use_lockfile = true
#     encrypt      = true
#   }
# }
