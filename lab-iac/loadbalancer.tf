# Load balancer with unmanaged instance group | lb-unmanaged.tf
# used to forward traffic to the correct load balancer for HTTP load balancing
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name = "global-forwarding-rule"
  target = google_compute_target_http_proxy.target_http_proxy.self_link
  port_range = "80"
}

# used by one or more global forwarding rule to route incoming HTTP requests to a URL map
resource "google_compute_target_http_proxy" "target_http_proxy" {
  name = "proxy"
  url_map = google_compute_url_map.url_map.self_link
}

# defines a group of virtual machines that will serve traffic for load balancing
resource "google_compute_backend_service" "backend_service" {
  name = "backend-service"
  port_name = "http"
  protocol = "HTTP"
  health_checks = ["${google_compute_health_check.healthcheck.self_link}"]
  backend {
    group = google_compute_instance_group.web_private_group_eu.self_link
    balancing_mode = "RATE"
    max_rate_per_instance = 100
  }

  backend {
    group = google_compute_instance_group.web_private_group_us.self_link
    balancing_mode = "RATE"
    max_rate_per_instance = 100
  }
}

# creates a group of dissimilar virtual machine instances
resource "google_compute_instance_group" "web_private_group_eu" {
  name = "vm-group-eu"
  description = "Web servers instance group"
  zone = var.gcp_zone_eu
  instances = [
    google_compute_instance.webservereu.self_link,
  ]
  named_port {
    name = "http"
    port = "5000"
  }
}
# creates a group of dissimilar virtual machine instances
resource "google_compute_instance_group" "web_private_group_us" {
  name = "vm-group-us"
  description = "Web servers instance group"
  zone = var.gcp_zone_us
  instances = [
    google_compute_instance.webserverus.self_link
  ]
  named_port {
    name = "http"
    port = "5000"
  }
}
# determine whether instances are responsive and able to do work
resource "google_compute_health_check" "healthcheck" {
  name = "healthcheck"
  timeout_sec = 1
  check_interval_sec = 1
  http_health_check {
    port = 5000
  }
}
# used to route requests to a backend service based on rules that you define for the host and path of an incoming URL
resource "google_compute_url_map" "url_map" {
  name = "load-balancer"
  default_service = google_compute_backend_service.backend_service.self_link
}
# show external ip address of load balancer
output "load-balancer-ip-address" {
  value = google_compute_global_forwarding_rule.global_forwarding_rule.ip_address
}

