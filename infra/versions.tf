# infra/versions.tf
#
# Root module version constraints for miso.
# The null provider gives Atlantis something safe to plan and apply without
# requiring any cloud credentials or billable infrastructure.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
