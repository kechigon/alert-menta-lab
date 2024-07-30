terraform {
  required_providers {
    google = {
        source = "hashicorp/google"
        version = "5.39.0"
    }
  }
}

provider "google" {
  credentials = var.credential_file
  project     = var.project
  region      = var.region
}

resource "google_compute_instance" "easybuggy" {
  name         = "easybuggy-instance"
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}

output "instance_ip" {
  value = google_compute_instance.easybuggy.network_interface[0].access_config[0].nat_ip
}

resource "google_compute_firewall" "default" {
  name    = "allow-home-ip"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080"]
  }

  source_ranges = [var.my_ip]
}