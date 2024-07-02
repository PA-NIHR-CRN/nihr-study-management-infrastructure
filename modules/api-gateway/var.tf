variable "env" {
  description = "environment name"
  type        = string
}

variable "system" {
  type = string
}

variable "account" {
  description = "account name"
  type        = string
  default     = "nihrd"
}

variable "invoke_lambda_arn" {

}

variable "stage_name" {

}

variable "function_name" {

}
variable "function_alias_name" {

}

//lambda authorizer
variable "wso2_service_audiences" {
  description = "Audience for the WSO2 service"
  type        = string
}

variable "wso2_service_issuer" {
  description = "Issuer for the WSO2 service"
  type        = string
}

variable "wso2_service_token_endpoint" {
  description = "Token endpoint for the WSO2 service"
  type        = string
}

variable "retention_in_days" {
  description = "Log retention in days"
}