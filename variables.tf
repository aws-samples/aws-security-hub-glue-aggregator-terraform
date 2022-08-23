variable "region" {
  description = "AWS Region in which resource are deployed in"
  type        = string
  default     = "eu-west-1"
}

variable "profile" {
  description = "Name of the AWS profile in ~/.aws/config"
  type        = string
  default     = "default"
}
