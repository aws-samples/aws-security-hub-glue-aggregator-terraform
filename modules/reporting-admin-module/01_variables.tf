variable "name_prefix" {
  description = "Prefix used in the name of all created resources"
  type        = string
}

variable "custom_tags" {
  description = "Tags applied to created resources"
  type        = map(string)
  default     = {}
}

variable "firehose_logs_retention_days" {
  type        = string
  description = "Firehose Logs Retention in Days"
  default     = "14"
}

variable "allowed_member_accounts" {
  type        = list(string)
  description = "The account numbers that are allowed to send their events"
}

