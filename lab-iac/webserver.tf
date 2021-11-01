resource "google_compute_instance" "webservereu" {
  name = "${var.webserver_prefix}-eu"
  machine_type = "f1-micro"
  zone = var.gcp_zone_eu

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
  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host = google_compute_instance.webservereu.network_interface[0].access_config[0].nat_ip
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/my-ssh-key")}"
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${google_compute_instance.webservereu.network_interface[0].access_config[0].nat_ip},' playbooks/Webserver.yaml"
    environment = {
      MYSQL_HOST = google_sql_database_instance.mastereu.ip_address.0.ip_address
      MYSQL_USER = "ubuntu"
      MYSQL_PASSWORD = nonsensitive(random_password.mysql_password.result)
    }
  }

}

output webserver_address_eu {
  value = google_compute_instance.webservereu.network_interface[0].access_config[0].nat_ip
}



resource "google_compute_instance" "webserverus" {
  name = "${var.webserver_prefix}-us"
  machine_type = "f1-micro"
  zone = var.gcp_zone_us

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
  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host = google_compute_instance.webserverus.network_interface[0].access_config[0].nat_ip
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/my-ssh-key")}"
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${google_compute_instance.webserverus.network_interface[0].access_config[0].nat_ip},' playbooks/Webserver.yaml"
    environment = {
      MYSQL_HOST = google_sql_database_instance.masterus.ip_address.0.ip_address
      MYSQL_USER = "ubuntu"
      MYSQL_PASSWORD = nonsensitive(random_password.mysql_password.result)
    }
  }

}

output webserver_address_us {
  value = google_compute_instance.webserverus.network_interface[0].access_config[0].nat_ip
}





