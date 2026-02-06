# RUN-4022 Bug Bash - Terraform Test Cases

This directory contains Terraform configurations to create Rundeck projects and jobs for the RUN-4022 Bug Bash test plan.

## Overview

The configuration creates two Rundeck projects:

1. **Ansible-Test** - For Runner Automatic Workflow Step tests (Categories 1-8)
2. **Common-Job-Tests** - For common job execution tests (Categories 9-20)

## Prerequisites

1. **Terraform** installed (v1.0+)
   ```bash
   terraform -version
   ```
   
   Note: This configuration uses Rundeck provider version >= 1.0.0

2. **Docker** installed (for running the ephemeral runners)
   ```bash
   docker --version
   ```

3. **Rundeck Enterprise** instance running with:
   - Runner support enabled
   - Ansible plugin installed (v4.0.14+)
   - Feature flags enabled:
     ```properties
     rundeck.feature.distributedAutomation.enabled=true
     rundeck.feature.runnerAutomaticWorkflowStepAssociation.enabled=true
     ```

4. **API Token** from Rundeck:
   - Login to Rundeck as admin
   - Go to Profile > User API Tokens
   - Create a new token

## Quick Start - Complete Setup

Follow these steps to set up the complete test environment:

### Step 1: Configure Variables

Edit `terraform.tfvars` and update with your Rundeck API token:

```hcl
rundeck_url         = "http://localhost:4440"
rundeck_api_version = "56"
rundeck_auth_token  = "your-actual-api-token"  # Get from Profile > User API Tokens
ssh_key_path        = "keys/test/id_rsa"
```

### Step 2: Initialize and Apply Terraform

```bash
# Initialize Terraform (downloads the provider)
terraform init

# Review what will be created
terraform plan -var-file=terraform.tfvars

# Apply the configuration (creates projects, jobs, runners, and .env files)
terraform apply -var-file=terraform.tfvars
```

Type `yes` when prompted to confirm.

This creates:
- Two Rundeck projects with all test jobs
- Three project runners (tokens generated automatically)
- SSH keys and passwords in Key Storage
- `.env` files for Docker Compose environments (see below)

**Important:** Terraform automatically generates the `.env` files in the Docker environment directories with the runner tokens and IDs:
- `docker-envs/ansible-runner-test/.env` - Contains `RUNNER_A_TOKEN`, `RUNNER_A_ID`, `RUNNER_B_TOKEN`, `RUNNER_B_ID`
- `docker-envs/docker-runner/.env` - Contains `RUNNER_RUNDECK_SERVER_TOKEN`, `RUNNER_RUNDECK_CLIENT_ID`

These files are required by Docker Compose to start the runners with the correct credentials.

### Step 3: Start Docker Environments

After Terraform apply completes, start the Docker containers:

**Option A: Using Docker Compose (Recommended)**

```bash
# Start Ansible Runner Test environment (2 runners + SSH nodes)
cd docker-envs/ansible-runner-test
docker compose up -d

# Start Docker Runner environment (1 runner + nodes)
cd ../docker-runner
docker compose up -d
```

**Option B: Using standalone Docker commands**

```bash
# Get runner tokens from Terraform outputs
RUNNER_A_TOKEN=$(terraform output -raw ansible_runner_a_token)
RUNNER_B_TOKEN=$(terraform output -raw ansible_runner_b_token)
COMMON_TOKEN=$(terraform output -raw common_runner_token)

# Start individual runners
docker run -d --name runner-ansible-a \
  -e RUNDECK_URL="http://host.docker.internal:4440" \
  -e RUNDECK_RUNNER_TOKEN="$RUNNER_A_TOKEN" \
  rundeckpro/runner

docker run -d --name runner-ansible-b \
  -e RUNDECK_URL="http://host.docker.internal:4440" \
  -e RUNDECK_RUNNER_TOKEN="$RUNNER_B_TOKEN" \
  rundeckpro/runner

docker run -d --name runner-common \
  -e RUNDECK_URL="http://host.docker.internal:4440" \
  -e RUNDECK_RUNNER_TOKEN="$COMMON_TOKEN" \
  rundeckpro/runner
```

### Step 4: Verify Setup

1. **Check runners are connected:**
   - Go to Rundeck UI > System Menu > Runners
   - All 3 runners should show as "Connected"

2. **Check projects were created:**
   - Navigate to Projects list
   - You should see "Ansible-Test-Bug-Bash" and "Common-Job-Tests-Bug-Bash"

3. **Verify nodes are discovered:**
   - Go to each project > Nodes
   - Docker nodes should be visible

### Step 5: Run Tests

Navigate to each project and execute the test jobs. Jobs are organized by category:
- Category 1-8: Ansible/Runner tests (Ansible-Test project)
- Category 9-20: Common job execution tests (Common-Job-Tests project)

## Stopping the Environment

```bash
# Stop Docker Compose environments
cd docker-envs/ansible-runner-test && docker compose down
cd ../docker-runner && docker compose down

# Or stop standalone runners
docker stop runner-ansible-a runner-ansible-b runner-common
docker rm runner-ansible-a runner-ansible-b runner-common
```

## Project Structure

```
terraform-test-cases/
├── main.tf                    # Provider configuration and locals
├── variables.tf               # Variable definitions
├── terraform.tfvars           # Variable values (update with your settings)
├── project-ansible-test.tf    # Ansible-Test project and jobs (Categories 1-8)
├── project-common-tests.tf    # Common-Job-Tests project and jobs (Categories 9-20)
├── runners.tf                 # Docker runner definitions
├── docker-envs.tf             # Generates .env files for Docker environments
├── outputs.tf                 # Output definitions
├── .gitignore                 # Git ignore rules
├── TEST_ENVIRONMENT_SETUP.md  # This file
└── docker-envs/               # Docker Compose environments
    ├── ansible-runner-test/   # Ansible test runners + SSH nodes
    │   ├── docker-compose.yml
    │   ├── .env               # Generated by Terraform (runner tokens)
    │   ├── ansible/           # Ansible configuration files
    │   ├── keys/              # SSH keys
    │   ├── node/              # SSH node Dockerfile
    │   └── runner/            # Runner Dockerfile + plugins
    └── docker-runner/         # Common test runner + nodes
        ├── docker-compose.yml
        ├── .env               # Generated by Terraform (runner tokens)
        ├── data/              # Ansible config and keys
        └── runner/            # Runner Dockerfile
```

**Note:** The `.env` files in docker-envs subdirectories are automatically generated by Terraform with the runner tokens. They are gitignored for security.

## Test Jobs Created

### Ansible-Test Project (Categories 1-8)

| Test Case | Job Name | Description |
|-----------|----------|-------------|
| TC-1.1 | Ansible Single Runner | Ansible Playbook dispatched to correct Runner |
| TC-1.2 | Ansible Multiple Runners | Multiple Runners with different node sets |
| TC-1.3 | Ansible Local Execution | Nodes without Runner association run locally |
| TC-1.4 | Ansible Mixed Environment | Mixed local and remote nodes |
| TC-2.1 | Parent Job Reference | Job reference with automatic Runner assignment |
| TC-2.2 | Nested Job References | 3-level job hierarchy |
| TC-2.3 | Job Reference Node Override | Parent overrides child's node filter |
| TC-3.1 | Sequential Workflow Strategy | Multiple Ansible steps in sequence |
| TC-3.3 | Parallel Execution | Parallel execution across Runners |
| TC-4.5 | Command Node Step | Command node step via runner node dispatch |
| TC-4.6 | Ansible Workflow Node Step | Ansible playbook per-node via runner |
| TC-5.1 | Mixed Workflow Steps | Non-Ansible steps unaffected |
| TC-5.2 | Scheduled Job | Scheduled job with Runner assignment |

### Common-Job-Tests Project (Categories 9-20)

| Test Case | Job Name | Description |
|-----------|----------|-------------|
| TC-9.1 | Simple Command | Basic echo command |
| TC-9.2 | Script Step | Inline script execution |
| TC-9.4 | Multiple Steps | 5 sequential steps |
| TC-10.1 | Single Node Step | Command on single node |
| TC-10.2 | Multiple Nodes | Command on all nodes |
| TC-10.3 | Keepgoing True | Continue on failure |
| TC-10.4 | Keepgoing False | Stop on first failure |
| TC-10.5 | Thread Count | Parallel with 3 threads |
| TC-10.6 | Rank Ascending | Ascending node order |
| TC-10.7 | Rank Descending | Descending node order |
| TC-11.1 | Sequential Strategy | Sequential workflow |
| TC-11.2 | Node-First Strategy | Node-first workflow |
| TC-12.1 | Text Option | Text input option |
| TC-12.2 | Required Option | Required option validation |
| TC-12.3 | Default Option | Option with default value |
| TC-12.4 | Secure Option | Password option (masked) |
| TC-12.6 | Allowed Values | Restricted value list |
| TC-12.7 | Regex Validation | Pattern validation |
| TC-12.8 | Multi-Valued | Multi-select option |
| TC-13.1 | Simple Job Reference | Basic job reference |
| TC-13.2 | Reference With Arguments | Job reference with args |
| TC-14.1 | Error Handler | Step error handler |
| TC-14.2 | Handler Continues | Handler allows continuation |
| TC-15.1 | Cron Schedule | Scheduled job (disabled) |
| TC-15.4 | Disabled Schedule | Schedule disabled test |
| TC-17.1 | Long Running Job | For kill testing |
| TC-17.2 | Execution Timeout | 30s timeout test |
| TC-17.4 | Retry on Failure | Retry count test |
| TC-17.6 | Execution Limit | Single concurrent limit |
| TC-18.1 | Log Output | stdout/stderr capture |
| TC-18.2 | Log Levels | Debug log level |
| TC-18.7 | Live Log Streaming | Real-time log test |
| TC-19.1 | Global Variables | Variable passing |
| TC-20.1 | Lifecycle Plugin Test | Lifecycle hooks |
| TC-20.5 | Multiple Lifecycle Plugins | Plugin order test |

## Runner Configuration

This Terraform configuration creates **3 ephemeral Docker runners**:

| Runner | Project | Description |
|--------|---------|-------------|
| Runner-Ansible-WS-A | Ansible-Test | Handles nodes tagged `RUNNER-A` |
| Runner-Ansible-WS-B | Ansible-Test | Handles nodes tagged `RUNNER-B` |
| Runner-Common-Tests | Common-Job-Tests | General job execution |

### Docker Environment Details

**Ansible Runner Test** (`docker-envs/ansible-runner-test/`):
- 2 runners (Runner A and Runner B)
- 5 SSH nodes for Runner A (tagged `ANSIBLE-RUNNER-A`)
- 5 SSH nodes for Runner B (tagged `ANSIBLE-RUNNER-B`)
- 1 local SSH node

**Docker Runner** (`docker-envs/docker-runner/`):
- 1 runner for Common-Job-Tests
- 10 demo nodes for testing

### Node Configuration

For the test cases to work, configure nodes:

| Node | Tags | Runner Association |
|------|------|-------------------|
| `node-runner1-1` | `RUNNER1` | Runner-Ansible-WS-A |
| `node-runner2-1` | `RUNNER2` | Runner-Ansible-WS-B |
| `ssh-node` | (none) | Local execution |

### Manual Configuration Required

**Resource Model Source - Runner Filter:**

The Terraform provider does not support configuring the Runner filter for Resource Model Sources. You must configure this manually in the Rundeck UI:

1. Go to **Project Settings > Edit Nodes**
2. For each Resource Model Source that needs to run on a specific Runner:
   - Click **Edit** on the source
   - Scroll to **Runner Settings**
   - Enable **Execute on Runner**
   - Set **Runner Filter Mode** to "Tags"
   - Enter the Runner tag (e.g., `RUNNER-A` or `RUNNER-B`)
   - Save the configuration

For the **Ansible-Test** project, configure:
- Docker Container Model Source for Runner A nodes → Runner Filter: `RUNNER-A`
- Docker Container Model Source for Runner B nodes → Runner Filter: `RUNNER-B`

### Project Runner Mode

Set Runner mode to "automatic" for the Ansible-Test project:
- Go to Project Settings > Edit Configuration
- Set Runner Dispatch Mode to "Automatic"

## Cleanup

To remove all created resources:

```bash
terraform destroy -var-file=terraform.tfvars
```

Type `yes` when prompted to confirm.

## Troubleshooting

### Authentication Error
- Verify your API token is valid
- Check the token has appropriate permissions
- Ensure the Rundeck URL is correct

### Provider Not Found
Run `terraform init` to download the provider.

### Jobs Not Creating
- Check Rundeck logs for errors
- Verify the projects were created first
- Ensure required plugins are installed (Ansible)

## Documentation References

- [Rundeck Terraform Provider](https://registry.terraform.io/providers/rundeck/rundeck/latest/docs)
- [Rundeck Jobs Documentation](https://docs.rundeck.com/docs/learning/getting-started/jobs/)
- [Terraform Getting Started](https://docs.rundeck.com/docs/learning/howto/use-terraform-provider.html)
