# =============================================================================
# Variables for RUN-4022 Bug Bash Test Cases
# =============================================================================

variable "rundeck_url" {
  description = "The URL of the Rundeck server"
  type        = string
  default     = "http://localhost:4440"
}

variable "rundeck_api_version" {
  description = "The API version to use (requires 56+ for project runners)"
  type        = string
  default     = "56"
}

variable "rundeck_auth_token" {
  description = "The API authentication token"
  type        = string
  sensitive   = true
}

variable "runner_image" {
  description = "The image to use for the runners"
  type        = string
  default     = "rundeckpro/runner:latest"
}