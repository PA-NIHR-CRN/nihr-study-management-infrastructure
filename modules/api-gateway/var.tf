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