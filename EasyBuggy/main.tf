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

  metadata_startup_script = <<EOF
#!/bin/bash
sudo apt-get update
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get install -y ca-certificates curl git 
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo git clone https://github.com/k-tamura/easybuggy.git
cd easybuggy
sudo docker build . -t easybuggy:local 
sudo docker run -p 8080:8080 easybuggy:local 
EOF
}

resource "google_compute_firewall" "allow-home-ip" {
  name    = "allow-home-ip"
  network = "default" 

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [var.my_ip]
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = "default"  

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

output "instance_ip" {
  value = google_compute_instance.easybuggy.network_interface[0].access_config[0].nat_ip
}