# infra/main.tf
#
# Root module for miso.
# This module stays cloud-free on purpose so Atlantis can demonstrate the full
# PR workflow without external credentials or provider-side costs.

# null_resource: placeholder to give `tofu plan` something meaningful to diff.
# Changing `run_id` forces a replacement, which makes Atlantis comments easy to see.
resource "null_resource" "demo" {
  triggers = {
    run_id = var.run_id
  }
}
