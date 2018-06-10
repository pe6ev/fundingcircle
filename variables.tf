variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "192.168.0.0/16"
}

variable "enable_dns_support" {
  default = "true"
}

variable "enable_dns_hostnames" {
  default = "true"
}

variable "environment" {
  description = "Environment tag, recommendation: <account name>_<region>, e.g. prod_us-west-2"
  default     = "dev"
}

variable "private_cidr" {
  description = "CIDR for private subnet"
  default     = "192.168.1.0/24"
}

variable "public_cidrs" {
  description = "CIDR for private subnet"
  default     = ["192.168.2.0/24", "192.168.3.0/24"]
}

variable "azs" {
  description = "A list of availability zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "alb_port" {
  description = "ALB port"
  default     = "80"
}

variable "alb_protocol" {
  description = "Protocol for ALB"
  default     = "HTTP"
}

variable "ssl_policy" {
  description = "SSl policy"
  default     = "ELBSecurityPolicy-2016-08"
}

variable "app_protocol" {
  description = "Application protocol"
  default     = "HTTP"
}

variable "alb_deregistration_delay" {
  description = "he amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default value is 60 seconds"
  default     = "60"
}

variable "app_health_check" {
  description = "Application health check URI"
  default     = "/_internal/health"
}

variable "app_health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of an individual target. Minimum value 5 seconds, Maximum value 300 seconds. Default 30 seconds"
  default     = "30"
}

variable "app_health_check_healthy_threshold" {
  description = "The number of consecutive health checks successes required before considering an healthy target healthy. Defaults to 3"
  default     = "3"
}

variable "app_health_check_unhealthy_threshold" {
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy. Defaults to "
  default     = "3"
}

variable "access_log_enabled" {
  description = "Set to true if you need to enable ALB access logs"
  default     = "false"
}

variable "db_ami" {
  description = "Ami id for db instance"
  default     = "ami-823e4efd"
}

variable "web_ami" {
  description = "Ami id for web instance"
  default     = "ami-aa7d0ad5"
}

variable "cert_arn" {
  description = "arn of ssl cert in aws"
  default     = ""
}
