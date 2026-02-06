# =============================================================================
# Terraform Configuration for RUN-4022 Bug Bash Test Cases
# =============================================================================
# This configuration creates two Rundeck projects with test jobs:
# 1. Ansible-Test - For Runner automatic workflow step tests (Categories 1-8)
# 2. Common-Job-Tests - For common job execution tests (Categories 9-20)
# =============================================================================

terraform {
  required_providers {
    rundeck = {
      source  = "rundeck/rundeck"
      version = ">= 1.1.1"
    }
  }
}

# =============================================================================
# Provider Configuration
# =============================================================================

provider "rundeck" {
  url         = var.rundeck_url
  api_version = var.rundeck_api_version
  auth_token  = var.rundeck_auth_token
}

# =============================================================================
# Local Values
# =============================================================================

locals {
  ansible_project_name = "Ansible-Test-Bug-Bash"
  common_project_name  = "Common-Job-Tests-Bug-Bash"
  
  # Node definitions for testing
  runner1_nodes = "tags: ANSIBLE-RUNNER-A"
  runner2_nodes = "tags: ANSIBLE-RUNNER-B"
  local_nodes   = "tags: ANSIBLE-LOCAL"
  ansible_runner_nodes = "tags: runner:tag:ANSIBLE"
  all_nodes     = ".*"
}
