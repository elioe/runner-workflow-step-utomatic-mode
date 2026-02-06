# =============================================================================
# Outputs
# =============================================================================

output "ansible_test_project" {
  description = "Ansible Test project details"
  value = {
    name        = rundeck_project.ansible_test.name
    description = rundeck_project.ansible_test.description
  }
}

output "common_tests_project" {
  description = "Common Tests project details"
  value = {
    name        = rundeck_project.common_tests.name
    description = rundeck_project.common_tests.description
  }
}

output "ansible_test_jobs" {
  description = "List of jobs created in Ansible-Test project"
  value = {
    # Category 1
    "TC-1.1" = rundeck_job.tc_1_1_ansible_single_runner.name
    "TC-1.2" = rundeck_job.tc_1_2_ansible_multiple_runners.name
    "TC-1.3" = rundeck_job.tc_1_3_ansible_local_execution.name
    "TC-1.4" = rundeck_job.tc_1_4_ansible_mixed_environment.name
    # Category 2
    "TC-2.1" = rundeck_job.tc_2_1_parent_job_reference.name
    "TC-2.2" = rundeck_job.tc_2_2_nested_job_references.name
    "TC-2.3" = rundeck_job.tc_2_3_job_reference_node_override.name
    # Category 3
    "TC-3.1" = rundeck_job.tc_3_1_sequential_strategy.name
    "TC-3.3" = rundeck_job.tc_3_3_parallel_execution.name
    # Category 4
    "TC-4.5" = rundeck_job.tc_4_5_non_ansible_step.name
    "TC-4.6" = rundeck_job.tc_4_6_ansible_workflow_node_step.name
    # Category 5
    "TC-5.1" = rundeck_job.tc_5_1_mixed_workflow.name
    "TC-5.2" = rundeck_job.tc_5_2_scheduled_job.name
  }
}

output "common_test_jobs" {
  description = "List of jobs created in Common-Job-Tests project"
  value = {
    # Category 9
    "TC-9.1"  = rundeck_job.tc_9_1_simple_command.name
    "TC-9.2"  = rundeck_job.tc_9_2_script_step.name
    "TC-9.4"  = rundeck_job.tc_9_4_multiple_steps.name
    # Category 10
    "TC-10.1" = rundeck_job.tc_10_1_single_node.name
    "TC-10.2" = rundeck_job.tc_10_2_multiple_nodes.name
    "TC-10.3" = rundeck_job.tc_10_3_keepgoing_true.name
    "TC-10.4" = rundeck_job.tc_10_4_keepgoing_false.name
    "TC-10.5" = rundeck_job.tc_10_5_thread_count.name
    "TC-10.6" = rundeck_job.tc_10_6_rank_ascending.name
    "TC-10.7" = rundeck_job.tc_10_7_rank_descending.name
    # Category 11
    "TC-11.1" = rundeck_job.tc_11_1_sequential.name
    "TC-11.2" = rundeck_job.tc_11_2_node_first.name
    # Category 12
    "TC-12.1" = rundeck_job.tc_12_1_text_option.name
    "TC-12.2" = rundeck_job.tc_12_2_required_option.name
    "TC-12.3" = rundeck_job.tc_12_3_default_option.name
    "TC-12.4" = rundeck_job.tc_12_4_secure_option.name
    "TC-12.6" = rundeck_job.tc_12_6_allowed_values.name
    "TC-12.7" = rundeck_job.tc_12_7_regex_validation.name
    "TC-12.8" = rundeck_job.tc_12_8_multi_valued.name
    # Category 13
    "TC-13.1" = rundeck_job.tc_13_1_simple_reference.name
    "TC-13.2" = rundeck_job.tc_13_2_reference_with_args.name
    # Category 14
    "TC-14.1" = rundeck_job.tc_14_1_error_handler.name
    "TC-14.2" = rundeck_job.tc_14_2_handler_continues.name
    # Category 15
    "TC-15.1" = rundeck_job.tc_15_1_cron_schedule.name
    "TC-15.4" = rundeck_job.tc_15_4_disabled_schedule.name
    # Category 17
    "TC-17.1" = rundeck_job.tc_17_1_long_running.name
    # "TC-17.2" = rundeck_job.tc_17_2_timeout.name  # Removed
    # "TC-17.4" = rundeck_job.tc_17_4_retry.name  # Removed due to provider bug
    "TC-17.6" = rundeck_job.tc_17_6_execution_limit.name
    # Category 18
    # "TC-18.1" = rundeck_job.tc_18_1_log_output.name  # Removed
    "TC-18.2" = rundeck_job.tc_18_2_log_levels.name
    "TC-18.7" = rundeck_job.tc_18_7_live_streaming.name
    # Category 19
    # "TC-19.1" = rundeck_job.tc_19_1_global_variables.name  # Removed
    # Category 20
    "TC-20.1" = rundeck_job.tc_20_lifecycle_test.name
  }
}
