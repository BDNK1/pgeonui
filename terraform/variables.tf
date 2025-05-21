variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-central2"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-central2-a"
}

variable "credentials_file" {
  description = "Path to the GCP service account key file (Optional when using gcloud application-default credentials)"
  type        = string
  default     = null
}

variable "instance_name" {
  description = "Name for the compute instance"
  type        = string
  default     = "pgeonui-instance"
}

variable "machine_type" {
  description = "Machine type for the compute instance"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "OS image for the compute instance"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "service_account_email" {
  description = "Email of the existing service account"
  type        = string
}

variable "postgres_password" {
  description = "Password for PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "postgres_user" {
  description = "Username for PostgreSQL database"
  type        = string
  default     = "postgres"
}

variable "postgres_db" {
  description = "Database name for PostgreSQL"
  type        = string
  default     = "appdb"
}

variable "app_docker_image" {
  description = "Docker image for the application"
  type        = string
}
