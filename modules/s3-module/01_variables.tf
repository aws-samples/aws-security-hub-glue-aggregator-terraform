variable "region" {
  description = "Default Region for Cloud Analytics Platform"
  default     = "eu-west-1"
}

variable "s3_bucket_name" {
  description = "Name of the bucket"
}

variable "s3_bucket_acl" {
  description = "Private or log-delivery-write"
  default     = "private"
}

variable "versioning_enabled" {
  default = false
}

variable "tags_s3" {
  description = "Instance specific Tags for s3 bucket"
  type        = map(string)
  default = {
  }
}

