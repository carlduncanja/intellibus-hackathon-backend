variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "The AWS region to deploy into"
  default     = "us-west-2"
}

variable "elevenlabs_api_key" {
  description = "API key for Eleven Labs"
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