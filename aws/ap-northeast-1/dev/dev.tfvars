environment = ""
project = ""
aws_region = "ap-northeast-1"
costcenter = ""

provider "aws" {
  default_tags {
    tags = var.default_tags
  }
}
