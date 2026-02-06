# =============================================================================
# Runners Configuration for RUN-4022 Bug Bash Test Cases
# =============================================================================
# This file creates Docker runners for both test projects:
# - Ansible-Test: 2 ephemeral Docker runners (Runner A, Runner B)
# - Common-Job-Tests: 1 ephemeral Docker runner
# =============================================================================

# =============================================================================
# Ansible-Test Project Runners
# =============================================================================

# Runner A - For nodes tagged RUNNER1
resource "rundeck_project_runner" "ansible_runner_a" {
  project_name = rundeck_project.ansible_test.name
  name         = "Runner-Ansible-WS-A"
  description  = "Ephemeral Docker runner for Ansible tests - handles RUNNER1 tagged nodes"
  tag_names    = "ansible,runner-a,docker,ephemeral"

  installation_type      = "docker"
  replica_type           = "ephemeral"
  runner_as_node_enabled = true
  remote_node_dispatch   = true
  runner_node_filter     = "tags: ANSIBLE-RUNNER-A"
}

# Runner B - For nodes tagged RUNNER2
resource "rundeck_project_runner" "ansible_runner_b" {
  project_name = rundeck_project.ansible_test.name
  name         = "Runner-Ansible-WS-B"
  description  = "Ephemeral Docker runner for Ansible tests - handles RUNNER2 tagged nodes"
  tag_names    = "ansible,runner-b,docker,ephemeral"

  installation_type      = "docker"
  replica_type           = "ephemeral"
  runner_as_node_enabled = true
  remote_node_dispatch   = true
  runner_node_filter     = "tags: ANSIBLE-RUNNER-B"
}

# =============================================================================
# Common-Job-Tests Project Runner
# =============================================================================

# Runner for common job tests
resource "rundeck_project_runner" "common_runner" {
  project_name = rundeck_project.common_tests.name
  name         = "Runner-Common-Tests"
  description  = "Ephemeral Docker runner for common job execution tests"
  tag_names    = "common,docker,ephemeral"

  installation_type      = "docker"
  replica_type           = "ephemeral"
  runner_as_node_enabled = true
  remote_node_dispatch   = true
  runner_node_filter     = "tags: docker"
}

# =============================================================================
# Runner Outputs
# =============================================================================

output "ansible_runner_a" {
  description = "Ansible Runner A details"
  value = {
    id   = rundeck_project_runner.ansible_runner_a.runner_id
    name = rundeck_project_runner.ansible_runner_a.name
  }
}

output "ansible_runner_a_token" {
  description = "Ansible Runner A authentication token"
  value       = rundeck_project_runner.ansible_runner_a.token
  sensitive   = true
}

output "ansible_runner_b" {
  description = "Ansible Runner B details"
  value = {
    id   = rundeck_project_runner.ansible_runner_b.runner_id
    name = rundeck_project_runner.ansible_runner_b.name
  }
}

output "ansible_runner_b_token" {
  description = "Ansible Runner B authentication token"
  value       = rundeck_project_runner.ansible_runner_b.token
  sensitive   = true
}

output "common_runner" {
  description = "Common Tests Runner details"
  value = {
    id   = rundeck_project_runner.common_runner.runner_id
    name = rundeck_project_runner.common_runner.name
  }
}

output "common_runner_token" {
  description = "Common Tests Runner authentication token"
  value       = rundeck_project_runner.common_runner.token
  sensitive   = true
}

