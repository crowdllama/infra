variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "linode_region" {
  description = "Linode region for the DHT server"
  type        = string
  default     = "us-east"
}

variable "linode_instance_type" {
  description = "Linode instance type for the DHT server"
  type        = string
  default     = "g6-standard-1"
}

variable "root_password" {
  description = "Root password for the Linode instance"
  type        = string
  sensitive   = true
}

variable "create_dns_record" {
  description = "Whether to create a DNS record for the DHT server"
  type        = bool
  default     = false
}

variable "domain_id" {
  description = "Linode domain ID for DNS record creation"
  type        = number
  default     = null
}

variable "dns_subdomain" {
  description = "DNS subdomain for the DHT server"
  type        = string
  default     = "dht"
} 