
# This is a sample Terraform configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "google" {
  region  = "us-central1"
}

# Sample resource configuration
resource "google_storage_bucket" "example" {
  name     = "example-bucket"
  location = "us-central1"
}