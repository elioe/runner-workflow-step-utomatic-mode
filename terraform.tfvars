# =============================================================================
# Terraform Variables for RUN-4022 Bug Bash Test Cases
# =============================================================================
# Update these values for your environment
# =============================================================================

# Rundeck server URL
rundeck_url = "http://localhost:4440"

# API version (requires 56+ for project runners)
rundeck_api_version = "56"

# API authentication token (get from Rundeck: Profile > User API Tokens)
# IMPORTANT: Update this with your actual API token before running!
rundeck_auth_token = "FSiAhMN6UEAggcNVEqSzK1c3cPHIUv9F"

runner_image = "rundeckpro/runner-ci:runner-workflow-step-automatic-mode"