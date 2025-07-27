environment = "staging"
project = "clearmind"
aws_region = "ap-northeast-1"
costcenter = "devteam"

provider "aws" {
  default_tags {
    tags = var.default_tags
  }
}
