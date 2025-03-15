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

variable "secret_username" {
  description = "Username for Secrets Manager credentials"
  type        = string
  default     = "myusername"

}

variable "secret_password" {
  description = "Password for Secrets Manager credentials"
  type        = string
  default     = "mypassword"
}