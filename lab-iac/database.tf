resource "random_password" "mysql_password" {
  length           = 16
  special          = false
}

output db_password {
  value       = random_password.mysql_password.result
  sensitive = true
}

resource "google_sql_database_instance" "mastereu" {
  name = "testdbeu"
  database_version = "MYSQL_5_7"
  
  settings {
    tier = "db-f1-micro"
    activation_policy = "ALWAYS"
    
    ip_configuration {
      ipv4_enabled = "true"
       
      authorized_networks {
        value = "0.0.0.0/0"
        name = "all"
      }
    }

    location_preference {
      zone = var.gcp_zone_eu
    }
  }
}

resource "google_sql_user" "defaulteu" {
  name = "ubuntu"
  instance = google_sql_database_instance.mastereu.name
  host = "%"
  password = random_password.mysql_password.result
}

resource "google_sql_database" "defaulteu" {
  name = "testdbeu"
  instance = google_sql_database_instance.mastereu.name
}

# output EU
output db_address_eu {
  value = google_sql_database_instance.mastereu.public_ip_address
}

resource "google_sql_database_instance" "masterus" {
  name = "testdbus"
  database_version = "MYSQL_5_7"

  settings {
    tier = "db-f1-micro"
    activation_policy = "ALWAYS"

    ip_configuration {
      ipv4_enabled = "true"

      authorized_networks {
        value = "0.0.0.0/0"
        name = "all"
      }
    }

    location_preference {
      zone = var.gcp_zone_us
    }
  }
}

resource "google_sql_user" "defaultus" {
  name = "ubuntu"
  instance = google_sql_database_instance.masterus.name
  host = "%"
  password = random_password.mysql_password.result
}

resource "google_sql_database" "defaultus" {
  name = "testdbus"
  instance = google_sql_database_instance.masterus.name
}

# output US
output db_address_us {
  value = google_sql_database_instance.masterus.public_ip_address
}


