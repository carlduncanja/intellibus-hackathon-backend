variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "The AWS region to deploy into"
  default     = "us-west-2"
}

variable "openai_api_key" {
  description = "OpenAI API key"
}