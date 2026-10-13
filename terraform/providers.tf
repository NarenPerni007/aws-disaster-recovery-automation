terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State note: this example deliberately leaves the backend unset so it can
  # be tried without touching shared state. For real use, configure a remote
  # backend per region and keep primary and DR state in separate state files.
  # A single state file that holds both regions becomes a single point of
  # failure for the setup that is supposed to survive a region outage.
}

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "disaster-recovery"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "disaster-recovery"
    }
  }
}
