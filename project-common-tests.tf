# =============================================================================
# Project: Common-Job-Tests
# =============================================================================
# Test cases for Common Job Execution (Categories 9-20)
# =============================================================================

resource "rundeck_project" "common_tests" {
  name        = local.common_project_name
  description = "RUN-4022 Bug Bash - Common Job Execution Tests"

  resource_model_source {
    type = "local"
    config = {
      format                    = "resourceyaml"
      generateFileAutomatically = "true"
    }
  }

  resource_model_source {
    type = "docker-container-model-source"
    config = {
      attributes = "username=agent osFamily=linux ssh-authentication=privateKey ssh-key-storage-path=keys/project/${local.common_project_name}/ssh/id_rsa"
      filter     = "name=docker-runner-node-runner-*"
      mapping    = "nodename.selector=docker:Name,hostname.selector=docker:IPAddress"
    }
  }

  extra_config = {
    "project.label" = "Common Job Tests"
    
    # Project-level global variables for testing
    "project.globals.project_env"     = "bug-bash-testing"
    "project.globals.project_version" = "1.0.0"
    "project.globals.api_endpoint"    = "https://api.example.com/v1"
    "project.globals.max_retries"     = "3"
  }
}

# =============================================================================
# SSH Key for Common-Job-Tests Project
# =============================================================================

resource "rundeck_private_key" "common_tests_ssh_key" {
  path         = "project/${local.common_project_name}/ssh/id_rsa"
  key_material = file("${path.module}/docker-envs/docker-runner/data/keys/id_rsa")
}

# Password for secure option testing
resource "rundeck_password" "common_tests_password" {
  path     = "project/${local.common_project_name}/passwords/test-password"
  password = "SecureTestPassword123!"
}

# =============================================================================
# Category 9: Basic Job Execution
# =============================================================================

# TC-9.1: Simple command step execution
resource "rundeck_job" "tc_9_1_simple_command" {
  name         = "TC-9.1 Simple Command"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-9-Basic-Execution"
  description  = "Test: Simple command step execution - echo hello"

  command {
    shell_command = "echo 'hello'"
  }
}

# TC-9.2: Script step execution
resource "rundeck_job" "tc_9_2_script_step" {
  name         = "TC-9.2 Script Step"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-9-Basic-Execution"
  description  = "Test: Inline script step execution"

  command {
    inline_script = <<-EOT
#!/bin/bash
echo "Script step test"
echo "Current date: $(date)"
echo "Hostname: $(hostname)"
exit 0
EOT
  }
}

# TC-9.4: Multiple workflow steps
resource "rundeck_job" "tc_9_4_multiple_steps" {
  name         = "TC-9.4 Multiple Steps"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-9-Basic-Execution"
  description  = "Test: Multiple workflow steps execute in sequence"

  command {
    shell_command = "echo 'Step 1 of 5'"
  }

  command {
    shell_command = "echo 'Step 2 of 5'"
  }

  command {
    shell_command = "echo 'Step 3 of 5'"
  }

  command {
    shell_command = "echo 'Step 4 of 5'"
  }

  command {
    shell_command = "echo 'Step 5 of 5'"
  }
}

# =============================================================================
# Category 10: Node Steps & Node Dispatch
# =============================================================================

# TC-10.1: Command node step on single node
resource "rundeck_job" "tc_10_1_single_node" {
  name              = "TC-10.1 Single Node Step"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-10-Node-Steps"
  description       = "Test: Command node step on single node"
  node_filter_query = "name: localhost"

  command {
    shell_command = "echo 'Running on single node'"
  }
}

# TC-10.2: Command node step on multiple nodes
resource "rundeck_job" "tc_10_2_multiple_nodes" {
  name              = "TC-10.2 Multiple Nodes"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-10-Node-Steps"
  description       = "Test: Command node step on multiple nodes"
  node_filter_query = "tags: docker"

  command {
    shell_command = "echo 'Running on node: $(hostname)'"
  }
}

# TC-10.3: Node step with keepgoing=true
resource "rundeck_job" "tc_10_3_keepgoing_true" {
  name              = "TC-10.3 Keepgoing True"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-10-Node-Steps"
  description       = "Test: Node step continues on failure with keepgoing=true"
  node_filter_query = "tags: docker"

  command {
    inline_script = <<-EOT
#!/bin/bash

NODE="@node.name@"

echo "Running on node: $NODE"
if [ "$NODE" = "/docker-runner-node-runner-5" ]; then
  echo "Simulating failure on fail-node"
  exit 1
else
  echo "Success on $NODE"
fi

EOT
  }

  continue_next_node_on_error  = true
}

# TC-10.4: Node step with keepgoing=false
resource "rundeck_job" "tc_10_4_keepgoing_false" {
  name              = "TC-10.4 Keepgoing False"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-10-Node-Steps"
  description       = "Test: Node step stops on first failure"
  node_filter_query = "tags: docker"

  command {
      inline_script = <<-EOT
#!/bin/bash

NODE="@node.name@"

echo "Running on node: $NODE"
if [ "$NODE" = "/docker-runner-node-runner-5" ]; then
  echo "Simulating failure on fail-node"
  exit 1
else
  echo "Success on $NODE"
fi

EOT
    }

    continue_next_node_on_error  = false
}


# TC-10.5: Node step with thread count
resource "rundeck_job" "tc_10_5_thread_count" {
  name              = "TC-10.5 Thread Count"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-10-Node-Steps"
  description       = "Test: Node step with threadcount=3"
  node_filter_query = "tags: docker"
  max_thread_count  = 3

  command {
    shell_command = "echo 'Running with thread count 3'"
  }
}

# TC-10.6: Node step rank order ascending
resource "rundeck_job" "tc_10_6_rank_ascending" {
  name              = "TC-10.6 Rank Ascending"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-10-Node-Steps"
  description       = "Test: Nodes executed in ascending order"
  node_filter_query = "tags: docker"
  rank_attribute    = "hostname"
  rank_order        = "ascending"

  command {
    inline_script = <<-EOT
#!/bin/bash
IP=$(hostname -I | awk '{print $1}')
echo "Node IP: $IP"
EOT
  }
}

# TC-10.7: Node step rank order descending
resource "rundeck_job" "tc_10_7_rank_descending" {
  name              = "TC-10.7 Rank Descending"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-10-Node-Steps"
  description       = "Test: Nodes executed in descending order"
  node_filter_query = "tags: docker"
  rank_attribute    = "hostname"
  rank_order        = "descending"

  command {
    inline_script = <<-EOT
#!/bin/bash
IP=$(hostname -I | awk '{print $1}')
echo "Node IP: $IP"
EOT
  }
}

# =============================================================================
# Category 11: Workflow Strategies
# =============================================================================

# TC-11.1: Sequential strategy
resource "rundeck_job" "tc_11_1_sequential" {
  name         = "TC-11.1 Sequential Strategy"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-11-Workflow-Strategies"
  description  = "Test: Steps execute 1-2-3-4-5 in sequence"

  command {
    shell_command = "echo 'Step 1' && sleep 1"
  }

  command {
    shell_command = "echo 'Step 2' && sleep 1"
  }

  command {
    shell_command = "echo 'Step 3' && sleep 1"
  }

  command {
    shell_command = "echo 'Step 4' && sleep 1"
  }

  command {
    shell_command = "echo 'Step 5'"
  }
}

# TC-11.2: Node-first strategy
resource "rundeck_job" "tc_11_2_node_first" {
  name              = "TC-11.2 Node-First Strategy"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-11-Workflow-Strategies"
  description       = "Test: All steps on node1, then node2, then node3"
  node_filter_query = "tags: docker"

  command {
    shell_command = "echo 'Step 1 on $(hostname)'"
  }

  command {
    shell_command = "echo 'Step 2 on $(hostname)'"
  }

  command {
    shell_command = "echo 'Step 3 on $(hostname)'"
  }
}

# TC-11.3: Parallel strategy (step-first)
resource "rundeck_job" "tc_11_3_parallel" {
  name              = "TC-11.3 Parallel Strategy"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-11-Workflow-Strategies"
  description       = "Test: Step1 on all nodes in parallel, then Step2 on all nodes"
  node_filter_query = "tags: docker"
  max_thread_count  = 10

  command {
    inline_script = <<-EOT
#!/bin/bash
NODE="@node.name@"
echo "Step 1 starting on $NODE at $(date +%H:%M:%S)"
sleep 2
echo "Step 1 finished on $NODE at $(date +%H:%M:%S)"
EOT
  }

  command {
    inline_script = <<-EOT
#!/bin/bash
NODE="@node.name@"
echo "Step 2 starting on $NODE at $(date +%H:%M:%S)"
sleep 2
echo "Step 2 finished on $NODE at $(date +%H:%M:%S)"
EOT
  }
}

# TC-11.4: Parallel with high thread count
resource "rundeck_job" "tc_11_4_parallel_high_threads" {
  name              = "TC-11.4 Parallel High Threads"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-11-Workflow-Strategies"
  description       = "Test: Execute on all nodes simultaneously with high thread count"
  node_filter_query = "tags: docker"
  max_thread_count  = 50

  command {
    inline_script = <<-EOT
#!/bin/bash
NODE="@node.name@"
IP=$(hostname -I | awk '{print $1}')
echo "Parallel execution on $NODE (IP: $IP) at $(date +%H:%M:%S)"
sleep 3
echo "Completed on $NODE at $(date +%H:%M:%S)"
EOT
  }
}

# TC-11.5: Sequential with single thread
resource "rundeck_job" "tc_11_5_sequential_single_thread" {
  name              = "TC-11.5 Sequential Single Thread"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-11-Workflow-Strategies"
  description       = "Test: Execute on nodes one at a time (thread count 1)"
  node_filter_query = "tags: docker"
  max_thread_count  = 1

  command {
    inline_script = <<-EOT
#!/bin/bash
NODE="@node.name@"
echo "Sequential execution on $NODE at $(date +%H:%M:%S)"
sleep 2
echo "Completed on $NODE at $(date +%H:%M:%S)"
EOT
  }
}

# TC-11.6: Parallel with failure handling
resource "rundeck_job" "tc_11_6_parallel_with_failure" {
  name              = "TC-11.6 Parallel With Failure"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-11-Workflow-Strategies"
  description       = "Test: Parallel execution continues on other nodes when one fails"
  node_filter_query = "tags: docker"
  max_thread_count  = 10

  command {
    inline_script = <<-EOT
#!/bin/bash
NODE="@node.name@"
echo "Running on $NODE at $(date +%H:%M:%S)"
# Simulate random failure on one node
if [ "$NODE" = "/docker-runner-node-runner-3" ]; then
  echo "Simulating failure on $NODE"
  exit 1
fi
sleep 2
echo "Success on $NODE"
EOT
  }

  continue_next_node_on_error = true
}

# =============================================================================
# Category 12: Job Options
# =============================================================================

# TC-12.1: Text option input
resource "rundeck_job" "tc_12_1_text_option" {
  name         = "TC-12.1 Text Option"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-12-Job-Options"
  description  = "Test: Text option input substitution"

  option {
    name        = "message"
    label       = "Message"
    description = "A text message to display"
  }

  command {
    shell_command = "echo 'Message: $${option.message}'"
  }
}

# TC-12.2: Required option without default
resource "rundeck_job" "tc_12_2_required_option" {
  name         = "TC-12.2 Required Option"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-12-Job-Options"
  description  = "Test: Required option blocks execution if not provided"

  option {
    name        = "required_value"
    label       = "Required Value"
    description = "This value is required"
    required    = true
  }

  command {
    shell_command = "echo 'Required value: $${option.required_value}'"
  }
}

# TC-12.3: Option with default value
resource "rundeck_job" "tc_12_3_default_option" {
  name         = "TC-12.3 Default Option"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-12-Job-Options"
  description  = "Test: Option with default value"

  option {
    name          = "environment"
    label         = "Environment"
    description   = "Target environment"
    default_value = "development"
  }

  command {
    shell_command = "echo 'Environment: $${option.environment}'"
  }
}

# TC-12.4: Secure option (password)
resource "rundeck_job" "tc_12_4_secure_option" {
  name         = "TC-12.4 Secure Option"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-12-Job-Options"
  description  = "Test: Secure option masked in logs - uses password from key storage"

  option {
    name                 = "password"
    label                = "Password"
    description          = "A secure password from key storage"
    obscure_input        = true
    exposed_to_scripts   = true
    storage_path         = "keys/project/${local.common_project_name}/passwords/test-password"
  }

  command {
    shell_command = "echo 'Password received $RD_OPTION_PASSWORD'"
  }
}

# TC-12.6: Option with allowed values list
resource "rundeck_job" "tc_12_6_allowed_values" {
  name         = "TC-12.6 Allowed Values"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-12-Job-Options"
  description  = "Test: Option restricted to specific values"

  option {
    name                      = "color"
    label                     = "Color"
    description               = "Select a color"
    value_choices             = ["red", "green", "blue"]
    default_value             = "blue"
    require_predefined_choice = true
  }

  command {
    shell_command = "echo 'Selected color: $${option.color}'"
  }
}

# TC-12.7: Option with regex validation
resource "rundeck_job" "tc_12_7_regex_validation" {
  name         = "TC-12.7 Regex Validation"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-12-Job-Options"
  description  = "Test: Option with regex pattern validation"

  option {
    name             = "email"
    label            = "Email"
    description      = "Enter a valid email address"
    validation_regex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
  }

  command {
    shell_command = "echo 'Email: $${option.email}'"
  }
}

# TC-12.8: Multi-valued option
resource "rundeck_job" "tc_12_8_multi_valued" {
  name         = "TC-12.8 Multi-Valued Option"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-12-Job-Options"
  description  = "Test: Multi-select option"

  option {
    name                      = "servers"
    label                     = "Servers"
    description               = "Select multiple servers"
    value_choices             = ["server1", "server2", "server3", "server4"]
    allow_multiple_values     = true
    multi_value_delimiter     = ","
    require_predefined_choice = true
  }

  command {
    shell_command = "echo 'Selected servers: $${option.servers}'"
  }
}

# =============================================================================
# Category 13: Job References (Standard)
# =============================================================================

# Child job for reference tests (simple)
resource "rundeck_job" "tc_13_child_job" {
  name         = "TC-13 Child Job Simple"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Simple child job for job reference testing"

  option {
    name        = "command"
    label       = "Command"
    description = "A parameter passed from parent"
    default_value = "hostname"
  }

  command {
    inline_script = <<-EOT
#!/bin/bash
echo "Executing command from option"
@option.command@
EOT
  }
}

# Child job with multiple steps
resource "rundeck_job" "tc_13_child_multi_step" {
  name         = "TC-13 Child Job Multi-Step"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Child job with multiple workflow steps"

  option {
    name        = "environment"
    label       = "Environment"
    description = "Target environment"
  }

  command {
    shell_command = "echo 'Step 1: Initializing for $${option.environment}'"
  }

  command {
    shell_command = "echo 'Step 2: Processing...'; sleep 1"
  }

  command {
    shell_command = "echo 'Step 3: Validating...'; sleep 1"
  }

  command {
    shell_command = "echo 'Step 4: Completed for $${option.environment}'"
  }
}

# Child job that dispatches to nodes
resource "rundeck_job" "tc_13_child_node_dispatch" {
  name              = "TC-13 Child Job Node Dispatch"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-13-Job-References"
  description       = "Child job that dispatches to nodes"
  node_filter_query = "tags: docker"

  option {
    name        = "command"
    label       = "Command"
    description = "Command to run on nodes"
    default_value = "hostname"
  }

  command {
    inline_script = <<-EOT
#!/bin/bash
NODE="@node.name@"
echo "Executing on node: $NODE"
@option.command@
EOT
  }
}

# Second child job for multiple references
resource "rundeck_job" "tc_13_child_job_b" {
  name         = "TC-13 Child Job B"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Second child job for multiple reference testing"

  option {
    name        = "task"
    label       = "Task"
    description = "Task name to execute"
  }

  command {
    shell_command = "echo 'Child B executing task: $${option.task}'"
  }
}

# TC-13.1: Simple job reference
resource "rundeck_job" "tc_13_1_simple_reference" {
  name         = "TC-13.1 Simple Job Reference"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Test: Parent job references child job"

  command {
    job {
      name       = rundeck_job.tc_13_child_job.name
      group_name = rundeck_job.tc_13_child_job.group_name
    }
  }
}

# TC-13.2: Job reference with arguments
resource "rundeck_job" "tc_13_2_reference_with_args" {
  name         = "TC-13.2 Reference With Arguments"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Test: Parent passes options to child job"

  command {
    job {
      name       = rundeck_job.tc_13_child_job.name
      group_name = rundeck_job.tc_13_child_job.group_name
      args       = "-command 'echo value_from_parent'"
    }
  }
}

# TC-13.3: Job reference to multi-step child
resource "rundeck_job" "tc_13_3_multi_step_child" {
  name         = "TC-13.3 Multi-Step Child Reference"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Test: Parent calls child job with multiple workflow steps"

  command {
    shell_command = "echo 'Parent: Starting multi-step child job'"
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_multi_step.name
      group_name = rundeck_job.tc_13_child_multi_step.group_name
      args       = "-environment 'production'"
    }
  }

  command {
    shell_command = "echo 'Parent: Multi-step child job completed'"
  }
}

# TC-13.4: Job reference with node filter override
resource "rundeck_job" "tc_13_4_node_override" {
  name              = "TC-13.4 Node Filter Override"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-13-Job-References"
  description       = "Test: Parent dispatches to nodes and overrides child's node filter"
  node_filter_query = "name: /docker-runner-node-runner-1"

  command {
    inline_script = <<-EOT
#!/bin/bash
NODE="@node.name@"
echo "Parent: Running on node $NODE, will call child with overridden filter"
EOT
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_node_dispatch.name
      group_name = rundeck_job.tc_13_child_node_dispatch.group_name
      args       = "-command 'echo Child override test on $hostname'"

      node_filters {
        filter = "name: /docker-runner-node-runner-1"
      }
    }
  }

  command {
    inline_script = <<-EOT
#!/bin/bash
NODE="@node.name@"
echo "Parent: Completed on node $NODE"
EOT
  }
}

# TC-13.5: Parent calls multiple child jobs
resource "rundeck_job" "tc_13_5_multiple_children" {
  name         = "TC-13.5 Multiple Child Jobs"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Test: Parent executes multiple different child jobs in sequence"

  command {
    shell_command = "echo 'Parent: Starting workflow with multiple child jobs'"
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_job.name
      group_name = rundeck_job.tc_13_child_job.group_name
      args       = "-command 'echo first_child'"
    }
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_job_b.name
      group_name = rundeck_job.tc_13_child_job_b.group_name
      args       = "-task 'second_child'"
    }
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_multi_step.name
      group_name = rundeck_job.tc_13_child_multi_step.group_name
      args       = "-environment 'staging'"
    }
  }

  command {
    shell_command = "echo 'Parent: All child jobs completed'"
  }
}

# TC-13.6: Nested job references (grandchild)
resource "rundeck_job" "tc_13_6_nested_reference" {
  name         = "TC-13.6 Nested Job Reference"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Test: Parent calls child which calls grandchild (nested references)"

  command {
    shell_command = "echo 'Grandparent: Starting nested execution'"
  }

  command {
    job {
      name       = rundeck_job.tc_13_5_multiple_children.name
      group_name = rundeck_job.tc_13_5_multiple_children.group_name
    }
  }

  command {
    shell_command = "echo 'Grandparent: Nested execution completed'"
  }
}

# TC-13.7: Job reference with fail on child error
resource "rundeck_job" "tc_13_7_fail_on_error" {
  name         = "TC-13.7 Fail On Child Error"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Test: Parent fails if child job fails"

  command {
    shell_command = "echo 'Parent: Calling child that may fail'"
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_job.name
      group_name = rundeck_job.tc_13_child_job.group_name
      args       = "-command 'echo \"test_failure_handling\" && exit 1'"
    }
  }

  command {
    shell_command = "echo 'Parent: This runs only if child succeeds'"
  }
}

# TC-13.8: Same child job called multiple times with different args
resource "rundeck_job" "tc_13_8_repeated_child" {
  name         = "TC-13.8 Repeated Child Calls"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-13-Job-References"
  description  = "Test: Parent calls same child job multiple times with different arguments"

  command {
    shell_command = "echo 'Parent: Calling child job 3 times with different params'"
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_multi_step.name
      group_name = rundeck_job.tc_13_child_multi_step.group_name
      args       = "-environment 'development'"
    }
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_multi_step.name
      group_name = rundeck_job.tc_13_child_multi_step.group_name
      args       = "-environment 'staging'"
    }
  }

  command {
    job {
      name       = rundeck_job.tc_13_child_multi_step.name
      group_name = rundeck_job.tc_13_child_multi_step.group_name
      args       = "-environment 'production'"
    }
  }

  command {
    shell_command = "echo 'Parent: All environments processed'"
  }
}

# =============================================================================
# Category 14: Error Handlers
# =============================================================================

# TC-14.1: Step error handler executed
resource "rundeck_job" "tc_14_1_error_handler" {
  name         = "TC-14.1 Error Handler"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-14-Error-Handlers"
  description  = "Test: Error handler executes on step failure"

  command {
    shell_command = "exit 1"

    error_handler {
      shell_command = "echo 'Error handler executed'"
    }
  }
}

# TC-14.2: Error handler success continues workflow
resource "rundeck_job" "tc_14_2_handler_continues" {
  name              = "TC-14.2 Handler Continues Workflow"
  project_name      = rundeck_project.common_tests.name
  group_name        = "Category-14-Error-Handlers"
  description       = "Test: Workflow continues after successful error handler"
  continue_on_error = true

  command {
    shell_command = "exit 1"

    error_handler {
      shell_command = "echo 'Handler succeeded'"
      keep_going_on_success = true
    }
  }

  command {
    shell_command = "echo 'This step should execute'"
  }
}

# =============================================================================
# Category 15: Scheduling & Triggers
# =============================================================================

# TC-15.1: Cron schedule execution (disabled by default)
resource "rundeck_job" "tc_15_1_cron_schedule" {
  name             = "TC-15.1 Cron Schedule"
  project_name     = rundeck_project.common_tests.name
  group_name       = "Category-15-Scheduling"
  description      = "Test: Job with cron schedule (disabled by default)"
  schedule         = "0/30 * * * * ? *"
  schedule_enabled = false

  command {
    shell_command = "echo 'Scheduled job executed at $(date)'"
  }
}

# TC-15.4: Disable schedule test
resource "rundeck_job" "tc_15_4_disabled_schedule" {
  name             = "TC-15.4 Disabled Schedule"
  project_name     = rundeck_project.common_tests.name
  group_name       = "Category-15-Scheduling"
  description      = "Test: Job with disabled schedule"
  schedule         = "0 30 0 * * ? *"
  schedule_enabled = false

  command {
    shell_command = "echo 'This should not execute on schedule'"
  }
}

# =============================================================================
# Category 17: Execution Control
# =============================================================================

# TC-17.1: Long running job for kill test
resource "rundeck_job" "tc_17_1_long_running" {
  name         = "TC-17.1 Long Running Job"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-17-Execution-Control"
  description  = "Test: Long running job for testing kill functionality"

  command {
    shell_command = "echo 'Starting long job...'; sleep 300; echo 'Done'"
  }
}


# TC-17.4: Retry on failure
# NOTE: Removed due to provider bug with retry attribute format
# resource "rundeck_job" "tc_17_4_retry" {
#   name         = "TC-17.4 Retry on Failure"
#   project_name = rundeck_project.common_tests.name
#   group_name   = "Category-17-Execution-Control"
#   description  = "Test: Step retried up to 3 times"
#   command {
#     shell_command = "echo 'Attempt'; exit 1"
#   }
# }

# TC-17.6: Execution limit (concurrent)
resource "rundeck_job" "tc_17_6_execution_limit" {
  name                        = "TC-17.6 Execution Limit"
  project_name                = rundeck_project.common_tests.name
  group_name                  = "Category-17-Execution-Control"
  description                 = "Test: Job with max concurrent=1"
  allow_concurrent_executions = false

  command {
    shell_command = "echo 'Only one execution at a time'; sleep 30"
  }
}

# =============================================================================
# Category 18: Log Output & Filtering
# =============================================================================

# TC-18.2: Log level filtering
resource "rundeck_job" "tc_18_2_log_levels" {
  name         = "TC-18.2 Log Levels"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-18-Log-Output"
  description  = "Test: Debug level output included"
  log_level    = "DEBUG"

  command {
    shell_command = "echo 'Debug logging enabled'"
  }
}

# TC-18.7: Live log streaming test
resource "rundeck_job" "tc_18_7_live_streaming" {
  name         = "TC-18.7 Live Log Streaming"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-18-Log-Output"
  description  = "Test: Live log streaming in UI"

  command {
    inline_script = <<-EOT
#!/bin/bash
for i in $(seq 1 10); do
  echo "Log line $i of 10"
  sleep 2
done
echo "Streaming complete"
EOT
  }
}

# =============================================================================
# Category 19: Data Passing Between Steps
# =============================================================================

# TC-19.2: Key-Value Data Log Filter
resource "rundeck_job" "tc_19_2_key_value_filter" {
  name         = "TC-19.2 Key-Value Log Filter"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-19-Data-Passing"
  description  = "Test: Key-value data capture using log filter plugin"

  option {
    name     = "input_value"
    label    = "Input Value"
    description = "Value to pass between steps"
    default_value = "test_data_123"
  }

  command {
    description = "Step 1: Capture data using RUNDECK:DATA format"
    inline_script = <<-EOT
#!/bin/bash
# Capture multiple key-value pairs using RUNDECK:DATA format
echo "RUNDECK:DATA:captured_value=$${option.input_value}"
echo "RUNDECK:DATA:timestamp=$(date +%s)"
echo "RUNDECK:DATA:hostname=$(hostname)"
echo "RUNDECK:DATA:status=success"
EOT

    plugins {
      log_filter_plugin {
        type = "key-value-data"
        config = {
          regex             = "^RUNDECK:DATA:\\s*([^\\s]+?)\\s*=\\s*(.+)$"
          logData           = "true"
          invalidKeyPattern = "\\s|\\$|\\{|\\}|\\\\"
        }
      }
    }
  }

  command {
    description = "Step 2: Use captured data from previous step"
    inline_script = <<-EOT
#!/bin/bash
echo "Reading captured data from Step 1:"
echo "  Captured Value: @data.captured_value@"
echo "  Timestamp: @data.timestamp@"
echo "  Hostname: @data.hostname@"
echo "  Status: @data.status@"
EOT
  }
}

# TC-19.3: Multi-line Data Capture
resource "rundeck_job" "tc_19_3_multiline_data" {
  name         = "TC-19.3 Multi-line Data Capture"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-19-Data-Passing"
  description  = "Test: Capture and use multiple data values across steps"

  command {
    description = "Step 1: Generate list of items"
    inline_script = <<-EOT
#!/bin/bash
# Simulate finding environments or resources
items="env1,env2,env3"
count=3
echo "RUNDECK:DATA:item_list=$items"
echo "RUNDECK:DATA:item_count=$count"
EOT

    plugins {
      log_filter_plugin {
        type = "key-value-data"
        config = {
          regex   = "^RUNDECK:DATA:\\s*([^\\s]+?)\\s*=\\s*(.+)$"
          logData = "true"
        }
      }
    }
  }

  command {
    description = "Step 2: Process the captured list"
    inline_script = <<-EOT
#!/bin/bash
echo "Processing @data.item_count@ items: @data.item_list@"
IFS=',' read -ra ITEMS <<< "@data.item_list@"
for item in "$${ITEMS[@]}"; do
  echo "  Processing: $item"
done
EOT
  }

  command {
    description = "Step 3: Final summary"
    shell_command = "echo 'Completed processing @data.item_count@ items'"
  }
}

# =============================================================================
# Category 20: Execution Lifecycle Plugins
# =============================================================================

# TC-20.1/20.2: Lifecycle plugin test job with Result Data
resource "rundeck_job" "tc_20_lifecycle_test" {
  name         = "TC-20 Lifecycle Plugin Test"
  project_name = rundeck_project.common_tests.name
  group_name   = "Category-20-Lifecycle-Plugins"
  description  = "Test: Data passing with Result Data lifecycle plugin"

  command {
    description = "Step 1: Generate data using key-value log filter"
    inline_script = <<-EOT
#!/bin/bash
echo "=== Generating execution data ==="
echo "RUNDECK:DATA:execution_status=success"
echo "RUNDECK:DATA:items_processed=42"
echo "RUNDECK:DATA:start_time=$(date +%Y-%m-%dT%H:%M:%S)"
echo "RUNDECK:DATA:hostname=$(hostname)"
EOT

    plugins {
      log_filter_plugin {
        type = "key-value-data"
        config = {
          regex   = "^RUNDECK:DATA:\\s*([^\\s]+?)\\s*=\\s*(.+)$"
          logData = "true"
        }
      }
    }
  }

  command {
    description = "Step 2: Process and add more data"
    inline_script = <<-EOT
#!/bin/bash
echo "Processing completed..."
echo "RUNDECK:DATA:end_time=$(date +%Y-%m-%dT%H:%M:%S)"
echo "RUNDECK:DATA:result_message=All items processed successfully"
EOT

    plugins {
      log_filter_plugin {
        type = "key-value-data"
        config = {
          regex   = "^RUNDECK:DATA:\\s*([^\\s]+?)\\s*=\\s*(.+)$"
          logData = "true"
        }
      }
    }
  }

  command {
    description = "Step 3: Display captured data"
    inline_script = <<-EOT
#!/bin/bash
echo "=== Execution Summary ==="
echo "Status: @data.execution_status@"
echo "Items Processed: @data.items_processed@"
echo "Start Time: @data.start_time@"
echo "End Time: @data.end_time@"
echo "Hostname: @data.hostname@"
echo "Result: @data.result_message@"
EOT
  }


  execution_lifecycle_plugin{
    type = "result-data-json-template"
    config = {
      jsonTemplate = <<-EOT
{
  "export": {
    "execution_status":"$${data.execution_status*}",
    "items_processed":"$${data.items_processed*}",
    "start_time":"$${data.start_time*}"
  }
}
      EOT
    }
  }
}
