# infra/variables.tf
#
# Input variable declarations for the miso root module.
# Keep the first demo variable simple so reviewers can trigger a clear plan diff
# by changing a single string value in a pull request.

variable "run_id" {
  description = "String used to force a visible null_resource replacement in plans."
  type        = string
  default     = "initial-demo"
}
