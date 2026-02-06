# =============================================================================
# Project: Ansible-Test
# =============================================================================
# Test cases for Runner Automatic Workflow Step Assignment (Categories 1-8)
# =============================================================================

resource "rundeck_project" "ansible_test" {
  name        = local.ansible_project_name
  description = "RUN-4022 Bug Bash - Ansible Runner Automatic Workflow Step Tests"

  default_node_executor_plugin    = "com.batix.rundeck.plugins.AnsibleNodeExecutor"
  default_node_file_copier_plugin = "com.batix.rundeck.plugins.AnsibleFileCopier"

  resource_model_source {
    type   = "local"
    config = {}
  }

  resource_model_source {
    type = "docker-container-model-source"
    config = {
      attributes = "osFamily=linux username=rundeck ansible-ssh-auth-type=password ansible-ssh-password-storage-path=keys/project/${local.ansible_project_name}/ssh/node-password"
      filter     = "name=ansible-runner-test-ssh-node-a-*"
      mapping    = "nodename.selector=docker:Name,hostname.selector=docker:IPAddress"
      tags       = "ANSIBLE-RUNNER-A"
    }
  }

  resource_model_source {
    type = "docker-container-model-source"
    config = {
      attributes = "osFamily=linux username=rundeck ansible-ssh-auth-type=password ansible-ssh-password-storage-path=keys/project/${local.ansible_project_name}/ssh/node-password"
      filter     = "name=ansible-runner-test-ssh-node-b-*"
      mapping    = "nodename.selector=docker:Name,hostname.selector=docker:IPAddress"
      tags       = "ANSIBLE-RUNNER-B"
    }
  }

  resource_model_source {
    type = "docker-container-model-source"
    config = {
      attributes = "osFamily=linux username=rundeck ansible-ssh-auth-type=password ansible-ssh-password-storage-path=keys/project/${local.ansible_project_name}/ssh/node-password"
      filter     = "name=ansible-runner-test-ssh-node-local-*"
      mapping    = "nodename.selector=docker:Name,hostname.selector=docker:IPAddress"
      tags       = "ANSIBLE-LOCAL"
    }
  }

  extra_config = {
    "project.label"                                  = "Ansible Test - Runner Automatic"
    "project.ansible-executable"                     = "/bin/bash"
    "project.ansible-generate-inventory-nodes-auth"  = "true"
    "project.ansible-generate-inventory"             = "true"
    "project.ansible-ssh-user"                       = "rundeck"
    "project.ansible-config-file-path"               = "/home/runner/ansible/ansible.cfg"
  }
}

# =============================================================================
# SSH Key for Ansible-Test Project
# =============================================================================

resource "rundeck_private_key" "ansible_test_ssh_key" {
  path         = "project/${local.ansible_project_name}/ssh/id_rsa"
  key_material = file("${path.module}/docker-envs/ansible-runner-test/keys/id_rsa")
}

# Password for node authentication
resource "rundeck_password" "ansible_test_node_password" {
  path     = "project/${local.ansible_project_name}/ssh/node-password"
  password = "testpassword123"
}

# =============================================================================
# Category 1: Basic Automatic Runner Assignment
# =============================================================================

# TC-1.1: Ansible Playbook dispatched to correct Runner
resource "rundeck_job" "tc_1_1_ansible_single_runner" {
  name              = "TC-1.1 Ansible Single Runner"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-1-Basic-Runner-Assignment"
  description       = "Test: Ansible Playbook dispatched to correct Runner. Targets nodes associated with Runner A."
  node_filter_query = local.runner1_nodes
  
  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}

# TC-1.2: Multiple Runners with different node sets
resource "rundeck_job" "tc_1_2_ansible_multiple_runners" {
  name              = "TC-1.2 Ansible Multiple Runners"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-1-Basic-Runner-Assignment"
  description       = "Test: Multiple Runners with different node sets. Creates subworkflow for Runner A and Runner B."
  node_filter_query = "tags: ANSIBLE-RUNNER-A tags: ANSIBLE-RUNNER-B"
  
  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}

# TC-1.3: Nodes without Runner association run locally
resource "rundeck_job" "tc_1_3_ansible_local_execution" {
  name              = "TC-1.3 Ansible Local Execution"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-1-Basic-Runner-Assignment"
  description       = "Test: Nodes without Runner association run locally on Rundeck server."
  node_filter_query = local.local_nodes
  
  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}

# TC-1.4: Mixed environment - some nodes local, some remote
resource "rundeck_job" "tc_1_4_ansible_mixed_environment" {
  name              = "TC-1.4 Ansible Mixed Environment"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-1-Basic-Runner-Assignment"
  description       = "Test: Mixed environment with Runner-associated and local nodes."
  node_filter_query = "tags: docker"
  
  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}

# =============================================================================
# Category 2: Job Reference Steps with Runners
# =============================================================================

# Child job for job reference tests
resource "rundeck_job" "tc_2_child_ansible_job" {
  name              = "TC-2 Child Ansible Job"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-2-Job-References"
  description       = "Child job with Ansible step for job reference testing"
  node_filter_query = "tags: ANSIBLE-RUNNER-A tags: ANSIBLE-RUNNER-B"
  
  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}

# TC-2.1: Job reference with automatic Runner assignment
resource "rundeck_job" "tc_2_1_parent_job_reference" {
  name              = "TC-2.1 Parent Job Reference"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-2-Job-References"
  description       = "Test: Parent job referencing child job with Ansible workflow step"
  
  command {
    job {
      name       = rundeck_job.tc_2_child_ansible_job.name
      group_name = rundeck_job.tc_2_child_ansible_job.group_name
    }
  }
}

# Grandchild job for nested reference test
resource "rundeck_job" "tc_2_grandchild_job" {
  name              = "TC-2 Grandchild Ansible Job"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-2-Job-References"
  description       = "Grandchild job with Ansible step"
  node_filter_query = local.runner2_nodes
  
  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}

# Middle job for nested reference test
resource "rundeck_job" "tc_2_middle_job" {
  name              = "TC-2 Middle Job"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-2-Job-References"
  description       = "Middle job in 3-level hierarchy"
  
  command {
    job {
      name       = rundeck_job.tc_2_grandchild_job.name
      group_name = rundeck_job.tc_2_grandchild_job.group_name
    }
  }
}

# TC-2.2: Nested job references (3 levels)
resource "rundeck_job" "tc_2_2_nested_job_references" {
  name              = "TC-2.2 Nested Job References"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-2-Job-References"
  description       = "Test: 3-level job hierarchy (Parent -> Middle -> Grandchild with Ansible)"
  
  command {
    job {
      name       = rundeck_job.tc_2_middle_job.name
      group_name = rundeck_job.tc_2_middle_job.group_name
    }
  }
}

# TC-2.3: Job reference with overridden node filter
resource "rundeck_job" "tc_2_3_job_reference_node_override" {
  name              = "TC-2.3 Job Reference Node Override"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-2-Job-References"
  description       = "Test: Parent overrides child's node filter to target different Runner"
  
  command {
    job {
      name       = rundeck_job.tc_2_child_ansible_job.name
      group_name = rundeck_job.tc_2_child_ansible_job.group_name

      node_filters {
        filter = local.runner2_nodes
      }
    }
  }
}

# =============================================================================
# Category 3: Workflow Strategies with Runners
# =============================================================================

# TC-3.1: Sequential workflow strategy
resource "rundeck_job" "tc_3_1_sequential_strategy" {
  name              = "TC-3.1 Sequential Workflow Strategy"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-3-Workflow-Strategies"
  description       = "Test: Multiple Ansible steps with sequential strategy"
  node_filter_query = "tags: ANSIBLE-RUNNER-A tags: ANSIBLE-RUNNER-B"
  
  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }

  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}

# TC-3.3: Parallel execution (Note: Parallel is configured at job level)
resource "rundeck_job" "tc_3_3_parallel_execution" {
  name              = "TC-3.3 Parallel Execution"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-3-Workflow-Strategies"
  description       = "Test: Parallel execution across multiple Runners"
  node_filter_query = "tags: ANSIBLE-RUNNER-A tags: ANSIBLE-RUNNER-B"
  command_ordering_strategy = "parallel"
  
  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}

# =============================================================================
# Category 4: Node Steps
# =============================================================================
# Node steps execute on runners via normal node dispatch per-node.
# This is different from workflow steps which use the automatic workflow step
# runner association feature (wrapping into sub-workflows).

# TC-4.5: Non-Ansible node step (Command step)
resource "rundeck_job" "tc_4_5_non_ansible_step" {
  name              = "TC-4.5 Command Node Step"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-4-Node-Steps"
  description       = "Test: Command node step executes on runner via normal node dispatch (per-node execution)"
  node_filter_query = local.runner1_nodes
  
  command {
    description = "Command node step - runs on each node via runner"
    shell_command = "whoami"
  }

  command {
    description = "script step - runs on each node via runner"
    inline_script = <<EOT
#!/bin/bash
df -h
EOT
  }
}

# TC-4.6: Workflow Node Step - Inline Ansible Playbook
resource "rundeck_job" "tc_4_6_ansible_workflow_node_step" {
  name              = "TC-4.6 Ansible Workflow Node Step"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-4-Node-Steps"
  description       = "Test: Ansible Inline Playbook as Workflow Node Step - executes per-node"
  node_filter_query = "tags: ANSIBLE-RUNNER-A tags: ANSIBLE-RUNNER-B"
  
  command {
    description = "Ansible Playbook Workflow Node Step"
    node_step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowNodeStep"
      config = {
        ansible-become          = "false"
        ansible-playbook-inline = <<-EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
EOT
      }
    }
  }
}

# NOTE: Category 5 (Execution Output & State Tracking) removed - covered by other test cases

# =============================================================================
# Category 5: Other Cases
# =============================================================================

# TC-5.1: Non-Ansible workflow steps unaffected
resource "rundeck_job" "tc_5_1_mixed_workflow" {
  name              = "TC-5.1 Mixed Workflow Steps"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-5-Other-Cases"
  description       = "Test: Non-Ansible steps execute normally with feature enabled"
  node_filter_query = local.runner1_nodes
  
  command {
    shell_command = "whoami"
  }

  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }

  command {
    shell_command = "df -h"
  }
}

# TC-5.2: Scheduled job with automatic assignment
resource "rundeck_job" "tc_5_2_scheduled_job" {
  name              = "TC-5.2 Scheduled Job"
  project_name      = rundeck_project.ansible_test.name
  group_name        = "Category-5-Other-Cases"
  description       = "Test: Scheduled job with automatic Runner assignment"
  node_filter_query = local.runner1_nodes
  schedule_enabled  = false  # Disabled by default, enable for testing
  
  # Schedule for testing (disabled by default)
  schedule = "0 0/5 * * * ? *"

  command {
    description = "Ansible Workflow Step"
    step_plugin {
      type = "com.batix.rundeck.plugins.AnsiblePlaybookInlineWorkflowStep"
      config = {
        ansible-playbook-inline = <<EOT
---
- hosts: all
  become: false
  tasks:
    - name: Get Disk Space
      shell: "df -h && date && env"
      register: df
    - debug: var=df.stdout_lines
    - name: Check Process
      shell: "ps -a"
      register: pid
    - debug: var=pid.stdout_lines
        EOT
      }
    }

  }
}
