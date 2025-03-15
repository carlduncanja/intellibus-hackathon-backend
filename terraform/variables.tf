variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "The AWS region to deploy into"
  default     = "us-west-1"
}