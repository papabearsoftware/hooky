variable "alb_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "assign_public_ip" {
  type = bool
}

variable "asg_subnets" {
  type = list(string)
}

variable "enable_container_insights" {
  type = bool
  default = true
}