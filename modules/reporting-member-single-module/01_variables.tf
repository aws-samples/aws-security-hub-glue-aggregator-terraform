variable "name_prefix" {
  description = "Prefix used in the name of all created resources"
  type        = string
}

variable "custom_tags" {
  description = "Tags applied to created resources"
  type        = map(string)
  default     = {}
}

variable "admin_events_bus_arn" {
  description = "ARN of admin account event bus, where to send Security Hub findings events copy"
  type        = string
}
