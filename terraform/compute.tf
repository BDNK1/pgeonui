# Compute Engine instance configuration
resource "google_compute_instance" "app_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = 30  # Increased size for Docker images and volumes
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
    }
  }

  # Use service account
  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  # Allow HTTP traffic
  tags = ["http-server"]

  # Startup script to install Docker, set up Docker Compose for PostgreSQL, PostgREST, and the application
  metadata_startup_script = templatefile("${path.module}/startup_script.sh", {
    postgres_user     = var.postgres_user
    postgres_password = var.postgres_password
    postgres_db       = var.postgres_db
    app_docker_image  = var.app_docker_image
    docker_compose_content = templatefile("${path.module}/docker-compose.yml.tpl", {
      postgres_user     = var.postgres_user
      postgres_password = var.postgres_password
      postgres_db       = var.postgres_db
      app_docker_image  = var.app_docker_image
      instance_name     = var.instance_name # Pass instance_name to docker-compose template
    })
    init_sql_content = file("${path.module}/init.sql.tpl")
    fluentd_conf_content = file("${path.module}/fluentd/fluent.conf") # Pass fluentd.conf content
    fluentd_dockerfile_content = file("${path.module}/fluentd/Dockerfile") # Pass fluentd.conf content
  })

  # No provisioners - all setup is done via startup script

  # No dependency on service account creation since we're using an existing one
}

# Firewall rule to allow external access to the application
resource "google_compute_firewall" "app_firewall" {
  name    = "allow-app"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "5601"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}
