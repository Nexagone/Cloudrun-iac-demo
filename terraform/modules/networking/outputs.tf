output "network_name" {
  description = "Nom du réseau VPC"
  value       = google_compute_network.main.name
}

output "network_id" {
  description = "ID du réseau VPC"
  value       = google_compute_network.main.id
}

output "services_subnet_name" {
  description = "Nom du sous-réseau des services"
  value       = google_compute_subnetwork.services.name
}

output "services_subnet_id" {
  description = "ID du sous-réseau des services"
  value       = google_compute_subnetwork.services.id
}

output "database_subnet_name" {
  description = "Nom du sous-réseau de la base de données"
  value       = google_compute_subnetwork.database.name
}

output "nat_ip" {
  description = "Adresse IP externe du NAT"
  value       = google_compute_address.nat.address
}

output "private_vpc_connection" {
  description = "Connexion VPC privée pour Cloud SQL"
  value       = google_service_networking_connection.private_vpc_connection.network
} 