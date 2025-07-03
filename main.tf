terraform {
  required_version = ">= 1.0"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

# Create a VPC for the CrowdLlama infrastructure (only if region supports VPCs)
resource "linode_vpc" "crowdllama_vpc" {
  count       = var.enable_vpc ? 1 : 0
  label       = "crowdllama-vpc-${var.environment}"
  region      = var.linode_region
  description = "VPC for CrowdLlama DHT infrastructure"
}

# Create a subnet within the VPC (only if VPC is enabled)
resource "linode_vpc_subnet" "crowdllama_subnet" {
  count  = var.enable_vpc ? 1 : 0
  vpc_id = linode_vpc.crowdllama_vpc[0].id
  label  = "crowdllama-subnet-${var.environment}"
  ipv4   = "10.0.1.0/24"
}

# Create firewall for the DHT server (public access, before instance creation)
resource "linode_firewall" "dht_firewall" {
  label = "crowdllama-dht-firewall-${var.environment}"
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-dht"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "9000"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-dht-udp"
    action   = "ACCEPT"
    protocol = "UDP"
    ports    = "9000"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  outbound {
    label    = "allow-all-outbound"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "1-65535"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  outbound {
    label    = "allow-all-outbound-udp"
    action   = "ACCEPT"
    protocol = "UDP"
    ports    = "1-65535"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  linodes = [linode_instance.dht_server.id]
}

# Create firewall for the internal VPC (only if VPC is enabled)
resource "linode_firewall" "dht_vpc_firewall" {
  count = var.enable_vpc ? 1 : 0
  label = "crowdllama-dht-vpc-firewall-${var.environment}"
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  inbound {
    label    = "allow-vpc-tcp-9000"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "9000"
    ipv4     = ["10.0.1.0/24"]
    ipv6     = ["::/0"]
  }

  outbound {
    label    = "allow-all-outbound"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "1-65535"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }
}

# Create a Linode instance for the DHT server
resource "linode_instance" "dht_server" {
  label     = "crowdllama-dht-${var.environment}"
  region    = var.linode_region
  type      = var.linode_instance_type
  image     = "linode/ubuntu22.04"
  root_pass = var.root_password
  private_ip = true

  tags = [
    "crowdllama",
    "dht",
    var.environment
  ]

  # Wait for the instance to be ready
  provisioner "remote-exec" {
    inline = ["echo 'Instance is ready'"]

    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = tolist(self.ipv4)[0]
      timeout     = "10m"
      agent       = false
    }
  }

  # Copy setup script to the instance
  provisioner "file" {
    source      = "setup-server.sh"
    destination = "/tmp/setup-server.sh"

    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = tolist(self.ipv4)[0]
      timeout     = "10m"
      agent       = false
    }
  }

  # Create directory and copy Docker Compose file
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/crowdllama"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = tolist(self.ipv4)[0]
      timeout     = "10m"
      agent       = false
    }
  }

  # Copy Docker Compose file to the instance
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/opt/crowdllama/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = tolist(self.ipv4)[0]
      timeout     = "10m"
      agent       = false
    }
  }

  # Run setup script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup-server.sh",
      "/tmp/setup-server.sh"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = tolist(self.ipv4)[0]
      timeout     = "10m"
      agent       = false
    }
  }

  # Start the CrowdLlama DHT service
  provisioner "remote-exec" {
    inline = [
      "systemctl start crowdllama-dht.service"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = tolist(self.ipv4)[0]
      timeout     = "10m"
      agent       = false
    }
  }
}



# Create the crowdllama.ai domain
resource "linode_domain" "crowdllama_domain" {
  domain      = "crowdllama.ai"
  type        = "master"
  soa_email   = var.domain_soa_email
  tags        = ["crowdllama", var.environment]
}

# Create A record for the root domain pointing to the DHT server
resource "linode_domain_record" "crowdllama_root" {
  domain_id   = linode_domain.crowdllama_domain.id
  name        = ""
  record_type = "A"
  target      = tolist(linode_instance.dht_server.ipv4)[0]
  ttl_sec     = 30
}

# Create A record for www subdomain
resource "linode_domain_record" "crowdllama_www" {
  domain_id   = linode_domain.crowdllama_domain.id
  name        = "www"
  record_type = "A"
  target      = tolist(linode_instance.dht_server.ipv4)[0]
  ttl_sec     = 30
}

# Create A record for dht subdomain pointing to the DHT server
resource "linode_domain_record" "dht_subdomain" {
  domain_id   = linode_domain.crowdllama_domain.id
  name        = "dht"
  record_type = "A"
  target      = tolist(linode_instance.dht_server.ipv4)[0]
  ttl_sec     = 30
}

# Create A record for the DHT server (optional, for backward compatibility)
resource "linode_domain_record" "dht_dns" {
  count       = var.create_dns_record ? 1 : 0
  domain_id   = linode_domain.crowdllama_domain.id
  name        = var.dns_subdomain
  record_type = "A"
  target      = tolist(linode_instance.dht_server.ipv4)[0]
  ttl_sec     = 30
}

# Output the server information
output "dht_server_ip" {
  description = "IP address of the DHT server"
  value       = tolist(linode_instance.dht_server.ipv4)[0]
}

output "dht_server_ssh_command" {
  description = "SSH command to connect to the DHT server"
  value       = "ssh root@${tolist(linode_instance.dht_server.ipv4)[0]}"
}

output "dht_server_status" {
  description = "Status of the DHT server"
  value       = linode_instance.dht_server.status
}

output "dht_server_url" {
  description = "DHT server URL"
  value       = "http://${tolist(linode_instance.dht_server.ipv4)[0]}:9000"
}

output "domain_name" {
  description = "Domain name"
  value       = linode_domain.crowdllama_domain.domain
}

output "domain_id" {
  description = "Domain ID"
  value       = linode_domain.crowdllama_domain.id
}

output "domain_url" {
  description = "Domain URL"
  value       = "http://${linode_domain.crowdllama_domain.domain}:9000"
}

output "www_url" {
  description = "WWW subdomain URL"
  value       = "http://www.${linode_domain.crowdllama_domain.domain}:9000"
}

output "dht_subdomain_url" {
  description = "DHT subdomain URL"
  value       = "http://dht.${linode_domain.crowdllama_domain.domain}:9000"
}

output "vpc_id" {
  description = "VPC ID"
  value       = var.enable_vpc ? linode_vpc.crowdllama_vpc[0].id : null
}

output "vpc_subnet_id" {
  description = "VPC Subnet ID"
  value       = var.enable_vpc ? linode_vpc_subnet.crowdllama_subnet[0].id : null
} 