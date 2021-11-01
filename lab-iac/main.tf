terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  # The file with the GCE credentials
  credentials = file("~/balmy-virtue-313511-2096bdc0342e.json")
  # The _ID_ of the project
  project = "balmy-virtue-313511"
  region  = "europe-west3"
  zone    = "europe-west3-a"
}


resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "default" {
  name    = "flask-app-firewall"
  network = "terraform-network"

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports = [
      "22"
    ]
  }
  allow {
    protocol = "tcp"
    ports = [
      "5000"
    ]
  }
}

resource "google_compute_instance" "smoketest" {
  name= "smoketest-vm"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
       image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "terraform-network"

    access_config {
       // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/my-ssh-key.pub")}"
  }

}


