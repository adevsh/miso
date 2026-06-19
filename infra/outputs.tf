# infra/outputs.tf
#
# Output values for the miso root module.
# Surface the configured trigger value so local validation and Atlantis applies
# have a simple, human-readable result to show in output.

output "demo_run_id" {
  description = "Current trigger value for the null_resource demo."
  value       = null_resource.demo.triggers.run_id
}
