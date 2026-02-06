# Bug Bash Test Plan: RUN-4022 - Runner Workflow Step Automatic Mode

**Version:** 1.0  
**Date:** January 26, 2026  
**Target Release:** 5.20.0  
**PRs Under Test:**
- [PR #9935: rundeck/rundeck](https://github.com/rundeck/rundeck/pull/9935) - Core execution lifecycle enhancements
- [PR #4531: rundeckpro/rundeckpro](https://github.com/rundeckpro/rundeckpro/pull/4531) - Runner automatic workflow step implementation

** Use the PR https://github.com/rundeckpro/rundeckpro/pull/4531 to start rundeck 
---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Feature Overview](#feature-overview)
3. [Prerequisites](#prerequisites)
4. [Test Scenarios - New Feature](#test-scenarios---new-feature)
5. [Test Scenarios - Common Job Execution](#test-scenarios---common-job-execution)
6. [Test Environment Matrix](#test-environment-matrix)
7. [Risk Areas](#risk-areas)

---

## Executive Summary

This test plan covers the **Automatic Runner Assignment for Workflow Steps** feature, which enables workflow steps (specifically Ansible Playbook steps initially) to be automatically dispatched to Runners based on node associations. This eliminates the need for manual Runner selection in job definitions.

### Key Changes

1. **New Execution Lifecycle Hook:** `beforeWorkflowIsSet()` - triggers before workflow execution items are configured
2. **Runner Node Support:** Workflow steps can now be assigned to specific Runner nodes
3. **SubWorkflow Execution:** Support for wrapping workflow steps with sub-workflows for multi-Runner dispatch
4. **Workflow Modification:** Lifecycle plugins can now replace/transform workflows dynamically

---

## Feature Overview

### How It Works

1. When a job with eligible workflow steps (e.g., Ansible Playbook) starts execution
2. The `RunnerAutomaticExecutionLifecycleComponent` intercepts via `beforeWorkflowIsSet()`
3. Node associations are evaluated to determine which Runners handle which nodes
4. Eligible workflow steps are transformed into sub-workflows with Runner-specific steps
5. Each sub-step executes on its assigned Runner, targeting the associated nodes

### Feature Flags Required

```properties

rundeck.feature.runner.enabled = true

# Optional
rundeck.feature.runnerReplicas.enabled = true

# Primary feature flag (required)
rundeck.feature.distributedAutomation.enabled=true

# Workflow step automatic assignment flag (required)
rundeck.feature.runnerAutomaticWorkflowStepAssociation.enabled=true
```

### Project Configuration

- Runner configuration must be set to "automatic" mode for the project
- Node-to-Runner associations must be configured via node dispatch settings

---

## Prerequisites

### Environment Setup

1. **Rundeck Enterprise instance** with Runner support
2. **At least 2 Runners** configured and in healthy status
3. **Ansible plugin** installed (v4.0.14+)
4. **Nodes configured** with different tags for Runner association
5. **SSH access** configured for remote nodes
6. **Docker** installed for running the test environments
7. **Terraform** installed (v1.0+) for provisioning test resources

### Test Environment - Automated Setup

This test plan includes Terraform scripts and Docker Compose environments for automated setup.

#### Quick Setup Steps

```bash
# 1. Navigate to runner-workflow-step-automatic-mode-bug-bush directory
cd runner-workflow-step-automatic-mode-bug-bush

# 2. Configure your Rundeck API token in terraform.tfvars
#    Edit: rundeck_auth_token = "your-api-token"

# 3. Initialize and apply Terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# 4. Start Docker environments (Terraform generates .env files automatically)
cd docker-envs/ansible-runner-test && docker compose up -d
cd ../docker-runner && docker compose up -d
```

#### What Terraform Creates

| Resource Type | Description |
|---------------|-------------|
| **Projects** | `Ansible-Test-Bug-Bash` (Categories 1-8), `Common-Job-Tests-Bug-Bash` (Categories 9-20) |
| **Runners** | 3 project runners with auto-generated tokens |
| **Jobs** | All test case jobs organized by category |
| **Key Storage** | SSH keys and passwords for node authentication |
| **Docker .env files** | Auto-generated with runner tokens for Docker Compose |

### Test Data Requirements

#### Projects

| Project | Purpose | Categories |
|---------|---------|------------|
| `Ansible-Test-Bug-Bash` | Runner automatic workflow step tests | 1-8 |
| `Common-Job-Tests-Bug-Bash` | Common job execution tests | 9-20 |

#### Runners

| Runner | Project | Tags | Description |
|--------|---------|------|-------------|
| `Runner-Ansible-WS-A` | Ansible-Test | `RUNNER1` | Handles nodes tagged `ANSIBLE-RUNNER-A` |
| `Runner-Ansible-WS-B` | Ansible-Test | `RUNNER2` | Handles nodes tagged `ANSIBLE-RUNNER-B` |
| `Runner-Common-Tests` | Common-Job-Tests | `docker` | General job execution on docker nodes |

#### Docker Environments

**Ansible Runner Test** (`docker-envs/ansible-runner-test/`):
| Container | Purpose |
|-----------|---------|
| `runner-a` | Runner for nodes tagged `ANSIBLE-RUNNER-A` |
| `runner-b` | Runner for nodes tagged `ANSIBLE-RUNNER-B` |
| `ssh-node-a-1` to `ssh-node-a-5` | 5 SSH nodes for Runner A |
| `ssh-node-b-1` to `ssh-node-b-5` | 5 SSH nodes for Runner B |
| `ssh-node-local` | Local SSH node (no Runner association) |

**Docker Runner** (`docker-envs/docker-runner/`):
| Container | Purpose |
|-----------|---------|
| `runner` | Runner for Common-Job-Tests project |
| `docker-runner-node-runner-1` to `docker-runner-node-runner-10` | 10 demo nodes tagged `docker` |

#### Key Storage

| Path | Type | Project | Purpose |
|------|------|---------|---------|
| `project/Ansible-Test-Bug-Bash/ssh/id_rsa` | Private Key | Ansible-Test | SSH authentication for nodes |
| `project/Ansible-Test-Bug-Bash/ssh/node-password` | Password | Ansible-Test | Password authentication (`testpassword123`) |
| `project/Common-Job-Tests-Bug-Bash/ssh/id_rsa` | Private Key | Common-Job-Tests | SSH authentication for nodes |
| `project/Common-Job-Tests-Bug-Bash/passwords/test-password` | Password | Common-Job-Tests | Test password (`SecureTestPassword123!`) |

#### Node Configuration

| Node Pattern | Tags | Runner Association |
|--------------|------|-------------------|
| `ansible-runner-test-ssh-node-a-*` | `ANSIBLE-RUNNER-A` | Runner-Ansible-WS-A |
| `ansible-runner-test-ssh-node-b-*` | `ANSIBLE-RUNNER-B` | Runner-Ansible-WS-B |
| `docker-runner-node-runner-*` | `docker` | Runner-Common-Tests |
| `ssh-node-local` | (none) | Local execution |

### Manual Configuration Required

**Resource Model Source - Runner Filter:**

The Terraform provider does not support configuring the Runner filter for Resource Model Sources. Configure manually in Rundeck UI:

1. Go to **Project Settings > Edit Nodes**
2. For each Resource Model Source that needs to run on a specific Runner:
   - Click **Edit** on the source
   - Scroll to **Runner Settings**
   - Enable **Execute on Runner**
   - Set **Runner Filter Mode** to "Tags"
   - Enter the Runner tag (e.g., `RUNNER1` or `RUNNER2`)

**Project Runner Mode:**

Set Runner mode to "automatic" for the Ansible-Test project:
- Go to Project Settings > Edit Configuration
- Set Runner Dispatch Mode to "Automatic"

### Test Jobs Created by Terraform

All test jobs are created automatically. See the [TEST_ENVIRONMENT_SETUP.md](./TEST_ENVIRONMENT_SETUP.md) for the complete list.

---

## Test Scenarios - New Feature

### Category 1: Basic Automatic Runner Assignment

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-1.1 | **Ansible Playbook dispatched to correct Runner** | 1. Create job with Ansible Inline Playbook workflow step<br>2. Configure node filter targeting nodes associated with Runner A<br>3. Run job | Step executes on Runner A, logs show "Running plugin ... in runner [Runner A ID]" | ☐ |
| TC-1.2 | **Multiple Runners with different node sets** | 1. Create job with Ansible step<br>2. Use node filter matching nodes from both Runner A and Runner B<br>3. Run job | Step creates subworkflow with separate executions on each Runner | ☐ |
| TC-1.3 | **Nodes without Runner association run locally** | 1. Create job with Ansible step<br>2. Use node filter with nodes NOT associated with any Runner<br>3. Run job | Step executes locally on Rundeck server, no Runner dispatch | ☐ |
| TC-1.4 | **Mixed environment: some nodes local, some remote** | 1. Create job with nodes: some with Runner association, some without<br>2. Run job | Subworkflow created: Runner steps + local server step, all succeed | ☐ |

### Category 2: Job Reference Steps with Runners

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-2.1 | **Job reference with automatic Runner assignment** | 1. Create parent job that references child job<br>2. Child job has Ansible workflow step<br>3. Run parent job | Child job's Ansible step dispatched to correct Runner | ☐ |
| TC-2.2 | **Nested job references** | 1. Create 3-level job hierarchy: Job A → Job B → Job C<br>2. Job C has Ansible step with runner-associated nodes<br>3. Run Job A | Ansible step in Job C executes on correct Runner | ☐ |
| TC-2.3 | **Job reference with overridden node filter** | 1. Parent job overrides child job's node filter<br>2. New node filter targets different Runner<br>3. Run parent job | Step dispatches to Runner matching the overridden node filter | ☐ |

### Category 3: Workflow Strategies with Runners

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-3.1 | **Sequential workflow strategy** | 1. Create job with multiple Ansible steps<br>2. Set workflow strategy to "Sequential"<br>3. Run job | Steps execute in order, each on appropriate Runner | ☐ |
| TC-3.2 | **Node-first workflow strategy** | 1. Job with multiple workflow steps<br>2. Multiple nodes targeting different Runners<br>3. Run with node-first strategy | Execution completes successfully for each node grouping | ☐ |
| TC-3.3 | **Parallel execution** | 1. Job with parallel workflow execution<br>2. Steps targeting multiple Runners<br>3. Run job | Parallel execution across Runners completes successfully | ☐ |

### Category 4: Node Steps

Node steps execute on runners via normal node dispatch (per-node execution). This is different from workflow steps which use the automatic workflow step runner association feature.

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-4.5 | **Command Node Step** | 1. Use Command node step<br>2. Target nodes associated with a Runner<br>3. Run job | Node step executes on runner via normal node dispatch (per-node) | ☐ |
| TC-4.6 | **Ansible Workflow Node Step** | 1. Use Ansible Inline Playbook as Workflow Node Step<br>2. Target nodes associated with a Runner<br>3. Run job | Ansible node step executes per-node via runner dispatch | ☐ |

### Category 5: Other Cases

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-5.1 | **Mixed Workflow Steps** | 1. Job with Command step + Ansible step<br>2. Run with feature enabled | Non-Ansible steps execute normally, Ansible steps use Runner dispatch | ☐ |
| TC-5.2 | **Scheduled Job** | 1. Schedule job with automatic Runner assignment<br>2. Wait for trigger | Scheduled execution uses correct Runner association | ☐ |

---

## Test Scenarios - Common Job Execution

### Category 9: Basic Job Execution

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-9.1 | **Simple command step execution** | 1. Create job with single Command step (`echo "hello"`)<br>2. Run job | Job succeeds, output shows "hello" | ☐ |
| TC-9.2 | **Script step execution** | 1. Create job with inline Script step (bash/powershell)<br>2. Run job | Script executes, output captured | ☐ |
| TC-9.3 | **Script file step execution** | 1. Create job with script file from URL or storage<br>2. Run job | Script downloaded and executed successfully | ☐ |
| TC-9.4 | **Multiple workflow steps** | 1. Create job with 5+ different steps<br>2. Run job | All steps execute in sequence | ☐ |
| TC-9.5 | **Job with no steps** | 1. Create job with empty workflow<br>2. Run job | Job completes (no-op or error based on config) | ☐ |

### Category 10: Node Steps & Node Dispatch

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-10.1 | **Command node step on single node** | 1. Create job with node step<br>2. Target single node<br>3. Run job | Command executes on target node | ☐ |
| TC-10.2 | **Command node step on multiple nodes** | 1. Create job with node step<br>2. Target 5+ nodes<br>3. Run job | Command executes on all nodes | ☐ |
| TC-10.3 | **Node step with keepgoing=true** | 1. Job with node step that fails on one node<br>2. Set keepgoing=true<br>3. Run job | Continues on remaining nodes, job marked partial success/failure | ☐ |
| TC-10.4 | **Node step with keepgoing=false** | 1. Job with node step that fails on first node<br>2. Set keepgoing=false<br>3. Run job | Stops on first failure | ☐ |
| TC-10.5 | **Node step with thread count** | 1. Job with node step, threadcount=3<br>2. Target 10 nodes<br>3. Run job | Executes on 3 nodes at a time | ☐ |
| TC-10.6 | **Node step rank order ascending** | 1. Job with rank attribute "hostname"<br>2. Rank order ascending<br>3. Run job | Nodes executed in alphabetical order by hostname | ☐ |
| TC-10.7 | **Node step rank order descending** | 1. Job with rank attribute "hostname"<br>2. Rank order descending<br>3. Run job | Nodes executed in reverse alphabetical order | ☐ |
| TC-10.8 | **Remote command via SSH** | 1. Configure SSH node executor<br>2. Run command on remote node | SSH connection established, command succeeds | ☐ |
| TC-10.9 | **File copy to remote node** | 1. Job with script requiring file copy<br>2. Run on remote node | File copied successfully, script executes | ☐ |

### Category 11: Workflow Strategies (Non-Runner)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-11.1 | **Sequential strategy** | 1. Job with 5 steps, sequential strategy<br>2. Run job | Steps execute 1→2→3→4→5 | ☐ |
| TC-11.2 | **Node-first strategy** | 1. Job with 3 node steps on 3 nodes<br>2. Node-first strategy<br>3. Run job | All steps on node1, then node2, then node3 | ☐ |
| TC-11.3 | **Step-first strategy** | 1. Job with 3 node steps on 3 nodes<br>2. Step-first strategy<br>3. Run job | Step1 on all nodes, then step2 on all, then step3 | ☐ |
| TC-11.4 | **Parallel strategy** | 1. Job with steps configured for parallel<br>2. Run job | Steps execute concurrently | ☐ |
| TC-11.5 | **Ruleset strategy** | 1. Job with ruleset workflow strategy<br>2. Define conditional rules<br>3. Run job | Steps execute based on rule conditions | ☐ |

### Category 12: Job Options

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-12.1 | **Text option input** | 1. Job with text option<br>2. Run with value provided<br>3. Check option used in step | Option value substituted correctly | ☐ |
| TC-12.2 | **Required option without default** | 1. Job with required option, no default<br>2. Try to run without providing value | Job blocked, prompts for required option | ☐ |
| TC-12.3 | **Option with default value** | 1. Job with option having default<br>2. Run without overriding | Default value used | ☐ |
| TC-12.4 | **Secure option (password)** | 1. Job with secure option<br>2. Run with password value | Password masked in logs, available to step | ☐ |
| TC-12.5 | **Secure option from Key Storage** | 1. Job with secure option sourced from Key Storage<br>2. Run job | Secret retrieved and used correctly | ☐ |
| TC-12.6 | **Option with allowed values list** | 1. Job with option restricted to specific values<br>2. Try to run with invalid value | Validation prevents invalid value | ☐ |
| TC-12.7 | **Option with regex validation** | 1. Job with option having regex pattern<br>2. Test valid and invalid inputs | Regex validation enforced | ☐ |
| TC-12.8 | **Multi-valued option** | 1. Job with multi-select option<br>2. Select multiple values<br>3. Run job | All selected values available to step | ☐ |
| TC-12.9 | **Cascading options (remote URL)** | 1. Job with option that depends on another<br>2. Select first option<br>3. Verify second option loads | Cascading works, dependent values load | ☐ |
| TC-12.10 | **File upload option** | 1. Job with file upload option<br>2. Upload file and run | File accessible during execution | ☐ |

### Category 13: Job References (Standard)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-13.1 | **Simple job reference** | 1. Parent job references child job<br>2. Run parent | Child job executes as step | ☐ |
| TC-13.2 | **Job reference with arguments** | 1. Parent passes options to child job<br>2. Run parent | Child receives option values | ☐ |
| TC-13.3 | **Job reference by UUID** | 1. Reference child job by UUID<br>2. Run parent | Child found and executed by UUID | ☐ |
| TC-13.4 | **Job reference by name/group** | 1. Reference child job by group/name<br>2. Run parent | Child found and executed by path | ☐ |
| TC-13.5 | **Cross-project job reference** | 1. Parent in Project A references job in Project B<br>2. Run parent | Cross-project reference works | ☐ |
| TC-13.6 | **Job reference with node override** | 1. Parent overrides child's node filter<br>2. Run parent | Child uses parent's node filter | ☐ |
| TC-13.7 | **Job reference failOnDisable** | 1. Reference disabled child job<br>2. Set failOnDisable=true<br>3. Run parent | Parent fails when child is disabled | ☐ |
| TC-13.8 | **Job reference ignoreNotifications** | 1. Child has notifications configured<br>2. Parent ignores child notifications<br>3. Run parent | Child notifications suppressed | ☐ |
| TC-13.9 | **Recursive job reference (circular)** | 1. Job A references Job B<br>2. Job B references Job A<br>3. Attempt to run | Circular reference detected/prevented | ☐ |
| TC-13.10 | **Job reference with childNodes option** | 1. Parent references child with childNodes=true<br>2. Run parent | Child uses nodes from parent context | ☐ |

### Category 14: Error Handlers

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-14.1 | **Step error handler executed** | 1. Step configured with error handler<br>2. Step fails<br>3. Observe | Error handler executes | ☐ |
| TC-14.2 | **Error handler success continues workflow** | 1. Step with error handler, keepgoing=true<br>2. Step fails, handler succeeds | Workflow continues | ☐ |
| TC-14.3 | **Error handler failure stops workflow** | 1. Step with error handler<br>2. Both step and handler fail | Workflow stops | ☐ |
| TC-14.4 | **Error handler access to failure data** | 1. Error handler uses `${result.message}`<br>2. Step fails | Error message available in handler | ☐ |
| TC-14.5 | **Node step error handler per node** | 1. Node step with error handler<br>2. Fails on specific node | Handler runs for failed node only | ☐ |

### Category 15: Scheduling & Triggers

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-15.1 | **Cron schedule execution** | 1. Schedule job with cron expression<br>2. Wait for trigger time | Job auto-executes on schedule | ☐ |
| TC-15.2 | **Multiple schedules per job** | 1. Job with 3 different schedules<br>2. Wait for triggers | Job executes on each schedule | ☐ |
| TC-15.3 | **Schedule with timezone** | 1. Schedule in specific timezone<br>2. Verify execution time | Executes at correct time for timezone | ☐ |
| TC-15.4 | **Disable schedule** | 1. Disable job's schedule<br>2. Wait past trigger time | Job does not execute | ☐ |
| TC-15.5 | **Schedule on cluster member** | 1. Schedule job on specific cluster member<br>2. Wait for trigger | Executes only on specified server | ☐ |
| TC-15.6 | **Webhook trigger** | 1. Configure webhook for job<br>2. Call webhook URL | Job executes via webhook | ☐ |
| TC-15.7 | **API trigger (run now)** | 1. Call `/job/{id}/run` API<br>2. Check execution | Job executes immediately | ☐ |

### Category 16: Notifications

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-16.1 | **Email notification on success** | 1. Configure email notification for success<br>2. Run job successfully | Email sent | ☐ |
| TC-16.2 | **Email notification on failure** | 1. Configure email notification for failure<br>2. Run job that fails | Email sent | ☐ |
| TC-16.3 | **Webhook notification** | 1. Configure webhook notification<br>2. Run job | Webhook called with execution data | ☐ |
| TC-16.4 | **Multiple notification recipients** | 1. Configure notification to multiple emails<br>2. Run job | All recipients notified | ☐ |
| TC-16.5 | **Notification with custom template** | 1. Use custom notification template<br>2. Run job | Custom template rendered correctly | ☐ |
| TC-16.6 | **PagerDuty notification** | 1. Configure PagerDuty notification<br>2. Run job that fails | PagerDuty incident created | ☐ |

### Category 17: Execution Control

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-17.1 | **Kill running execution** | 1. Start long-running job<br>2. Kill execution via UI/API | Execution stops, marked as killed | ☐ |
| TC-17.2 | **Execution timeout** | 1. Job with 30s timeout<br>2. Step that takes 60s | Job times out and fails | ☐ |
| TC-17.3 | **Step timeout** | 1. Individual step with timeout<br>2. Step exceeds timeout | Step times out, error handler runs if configured | ☐ |
| TC-17.4 | **Retry on failure** | 1. Configure step with retry count=3<br>2. Step fails initially | Step retried up to 3 times | ☐ |
| TC-17.5 | **Retry delay** | 1. Step with retry delay=5s<br>2. Step fails | 5s delay between retries | ☐ |
| TC-17.6 | **Execution limit (concurrent)** | 1. Job with max concurrent=1<br>2. Try to run twice simultaneously | Second execution queued or rejected | ☐ |
| TC-17.7 | **Execution limit per node** | 1. Node step with limit per node<br>2. Run on same node twice | Limit enforced per node | ☐ |

### Category 18: Log Output & Filtering

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-18.1 | **Log output captured** | 1. Step that produces stdout/stderr<br>2. View execution logs | All output visible | ☐ |
| TC-18.2 | **Log level filtering** | 1. Run job with DEBUG log level<br>2. View logs | Debug-level output included | ☐ |
| TC-18.3 | **Log filter: mask passwords** | 1. Configure mask passwords filter<br>2. Step outputs sensitive data | Passwords masked in output | ☐ |
| TC-18.4 | **Log filter: highlight output** | 1. Configure highlight filter<br>2. Step outputs matching text | Text highlighted in logs | ☐ |
| TC-18.5 | **Log filter: key-value data** | 1. Configure key-value data filter<br>2. Step outputs key=value pairs | Data captured for downstream steps | ☐ |
| TC-18.6 | **Log storage (S3/Azure)** | 1. Configure external log storage<br>2. Run job<br>3. Verify log upload | Logs stored externally | ☐ |
| TC-18.7 | **Live log streaming** | 1. Start long-running job<br>2. Watch execution in UI | Logs stream in real-time | ☐ |
| TC-18.8 | **Download execution log** | 1. Complete an execution<br>2. Download log file | Log file downloads correctly | ☐ |

### Category 19: Data Passing Between Steps

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-19.1 | **Global variables** | 1. Step 1 exports global variable<br>2. Step 2 uses `${globals.varname}` | Variable passed correctly | ☐ |
| TC-19.2 | **Data context from log filter** | 1. Step 1 uses key-value filter<br>2. Step 2 uses `${data.key}` | Data passed via context | ☐ |
| TC-19.3 | **Node-specific data** | 1. Node step exports data per node<br>2. Subsequent step accesses node data | Per-node data available | ☐ |
| TC-19.4 | **Export variables to parent job** | 1. Child job exports variable<br>2. Parent job accesses it | Variable exported to parent | ☐ |

### Category 20: Execution Lifecycle Plugins (Existing)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TC-20.1 | **beforeJobStarts plugin** | 1. Configure existing lifecycle plugin<br>2. Run job | Plugin's beforeJobStarts called | ☐ |
| TC-20.2 | **afterJobEnds plugin** | 1. Configure existing lifecycle plugin<br>2. Run job | Plugin's afterJobEnds called | ☐ |
| TC-20.3 | **Lifecycle plugin modifies context** | 1. Plugin that adds data to context<br>2. Run job | Modified context available to steps | ☐ |
| TC-20.4 | **Lifecycle plugin fails job** | 1. Plugin returns unsuccessful status<br>2. Run job | Job fails before steps execute | ☐ |
| TC-20.5 | **Multiple lifecycle plugins** | 1. Configure multiple lifecycle plugins<br>2. Run job | All plugins executed in order | ☐ |

---

## Test Environment Matrix

| Environment | Priority | Notes |
|-------------|----------|-------|
| Single Rundeck instance (no cluster) | High | Basic functionality |
| With Runners (automatic mode) | High | New feature testing |
| With Runners (manual mode) | High | Regression testing |
| Without Runners | Medium | Ensure feature flags don't break non-Runner setups |
| Docker deployment | Medium | Container-specific issues |
| WAR deployment | Medium | Traditional deployment |

### Provided Docker Test Environments

| Environment | Directory | Runners | Nodes | Purpose |
|-------------|-----------|---------|-------|---------|
| Ansible Runner Test | `docker-envs/ansible-runner-test/` | 2 | 11 | Categories 1-8 (Ansible/Runner tests) |
| Docker Runner | `docker-envs/docker-runner/` | 1 | 10 | Categories 9-20 (Common job tests) |

### Starting/Stopping Test Environments

```bash
# Start environments
cd runner-workflow-step-automatic-mode-bug-bush/docker-envs/ansible-runner-test && docker compose up -d
cd ../docker-runner && docker compose up -d

# Check status
docker compose ps

# View runner logs
docker compose logs -f runner-a runner-b  # Ansible environment
docker compose logs -f runner              # Docker Runner environment

# Stop environments
cd runner-workflow-step-automatic-mode-bug-bush/docker-envs/ansible-runner-test && docker compose down
cd ../docker-runner && docker compose down
```

### Verifying Environment Health

1. **Check Runners are connected:**
   - Rundeck UI > System Menu > Runners
   - All runners should show "Connected" status

2. **Check Nodes are discovered:**
   - Go to each project > Nodes
   - Verify expected node count (11 for Ansible, 10 for Common)

3. **Test SSH connectivity:**
   - Run TC-9.1 (Simple Command) to verify basic execution
   - Run TC-10.2 (Multiple Nodes) to verify node dispatch

---

## Documentation References

- [Rundeck Jobs Documentation](https://docs.rundeck.com/docs/learning/getting-started/jobs/)
- [What is a Job?](https://docs.rundeck.com/docs/learning/getting-started/jobs/what-is-a-job.html)
- [Workflow Strategies](https://docs.rundeck.com/docs/learning/getting-started/jobs/workflow-strategies.html)
- [Enterprise Runner Documentation](https://docs.rundeck.com/docs/administration/runner/)
- [Rundeck Terraform Provider](https://registry.terraform.io/providers/rundeck/rundeck/latest/docs)
- [Test Environment Setup](./TEST_ENVIRONMENT_SETUP.md) - Detailed instructions for Terraform and Docker setup
