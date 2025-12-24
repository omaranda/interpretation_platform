variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}
