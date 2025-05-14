# Output variables
output "vm_instance_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.app_instance.name
}

output "vm_external_ip" {
  description = "External IP address of the VM instance"
  value       = google_compute_instance.app_instance.network_interface[0].access_config[0].nat_ip
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM instance"
  value       = google_compute_instance.app_instance.network_interface[0].network_ip
}

output "service_account_email" {
  description = "Email of the service account"
  value       = var.service_account_email
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${var.postgres_user}:PASSWORD@${google_compute_instance.app_instance.network_interface[0].network_ip}:5432/${var.postgres_db}"
  sensitive   = true
}

output "app_url" {
  description = "URL for the deployed application"
  value       = "http://${google_compute_instance.app_instance.network_interface[0].access_config[0].nat_ip}:80"
}
