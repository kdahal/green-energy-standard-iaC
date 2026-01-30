variable "region" {
  description = "AWS Region for Stem workloads"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  default     = "dev"
}
