variable "hooky_container_commands" {
  type = string
  // Surprisingly this is valid
  default = false
}

variable "ecr_repo" {
  type = string
}

variable "container_version" {
  type = string
}

variable "db_hostname" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  // sensitive is available in terraform 14
  // sensitive = true
}

variable "db_name" {
  type = string
}

variable "job_thread_pool_size" {
  type = number
}

variable "max_webhook_retry_error_count" {
  type = number
}

variable "run_async_jobs" {
  type = string
  default = "False"
}

variable "request_timeout" {
  type = number
}

variable "cluster_id" {
  type = string
}

variable "alb_target_group_arn" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}