terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  # Uses application default credentials from gcloud auth application-default login
  # Uncomment the line below if you need to use a specific credentials file
  # credentials = var.credentials_file
}