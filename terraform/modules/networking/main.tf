# Réseau VPC principal
resource "google_compute_network" "main" {
  name                    = "${lower(var.project_name)}-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# Sous-réseau pour les services
resource "google_compute_subnetwork" "services" {
  name                     = "${lower(var.project_name)}-services-subnet"
  ip_cidr_range           = var.services_subnet_cidr
  region                  = var.region
  network                 = google_compute_network.main.id
  private_ip_google_access = true
  
  secondary_ip_range {
    range_name    = "services-secondary-range"
    ip_cidr_range = var.services_secondary_cidr
  }
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# Sous-réseau pour Cloud SQL
resource "google_compute_subnetwork" "database" {
  name                     = "${lower(var.project_name)}-database-subnet"
  ip_cidr_range           = var.database_subnet_cidr
  region                  = var.region
  network                 = google_compute_network.main.id
  private_ip_google_access = true
}

# Adresse IP externe pour Cloud NAT
resource "google_compute_address" "nat" {
  name   = "${lower(var.project_name)}-nat-ip"
  region = var.region
  
  labels = local.normalized_labels
}

# Cloud Router pour NAT
resource "google_compute_router" "router" {
  name    = "${lower(var.project_name)}-router"
  region  = var.region
  network = google_compute_network.main.id
  
  bgp {
    asn = 64514
  }
}

# Cloud NAT pour les sorties
resource "google_compute_router_nat" "nat" {
  name                               = "${lower(var.project_name)}-nat"
  router                            = google_compute_router.router.name
  region                            = var.region
  nat_ip_allocate_option            = "MANUAL_ONLY"
  nat_ips                           = [google_compute_address.nat.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall - Autoriser les connexions internes
resource "google_compute_firewall" "allow_internal" {
  name    = "${lower(var.project_name)}-allow-internal"
  network = google_compute_network.main.name
  
  allow {
    protocol = "icmp"
  }
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  source_ranges = [
    var.services_subnet_cidr,
    var.database_subnet_cidr,
    var.services_secondary_cidr
  ]
  
  target_tags = ["internal"]
}

# Firewall - Autoriser HTTPS depuis l'extérieur
resource "google_compute_firewall" "allow_https" {
  name    = "${lower(var.project_name)}-allow-https"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Firewall - Autoriser les health checks de Cloud Load Balancer
resource "google_compute_firewall" "allow_health_check" {
  name    = "${lower(var.project_name)}-allow-health-check"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  
  target_tags = ["web-server"]
}

# Firewall - Bloquer tout le reste
resource "google_compute_firewall" "deny_all" {
  name     = "${lower(var.project_name)}-deny-all"
  network  = google_compute_network.main.name
  priority = 65534
  
  deny {
    protocol = "all"
  }
  
  source_ranges = ["0.0.0.0/0"]
}

# Private Service Connect pour Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${lower(var.project_name)}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
} 