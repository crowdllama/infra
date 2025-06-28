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

# Create a Linode instance for the DHT server
resource "linode_instance" "dht_server" {
  label     = "crowdllama-dht-${var.environment}"
  region    = var.linode_region
  type      = var.linode_instance_type
  image     = "linode/ubuntu22.04"
  root_pass = var.root_password

  tags = [
    "crowdllama",
    "dht",
    var.environment
  ]

  # Wait for the instance to be ready
  provisioner "remote-exec" {
    inline = ["echo 'Instance is ready'"]

    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = tolist(self.ipv4)[0]
    }
  }

  # Copy setup script to the instance
  provisioner "file" {
    source      = "setup-server.sh"
    destination = "/tmp/setup-server.sh"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = tolist(self.ipv4)[0]
    }
  }

  # Create directory and copy Docker Compose file
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/crowdllama"
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = tolist(self.ipv4)[0]
    }
  }

  # Copy Docker Compose file to the instance
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/opt/crowdllama/docker-compose.yml"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = tolist(self.ipv4)[0]
    }
  }

  # Run setup script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup-server.sh",
      "/tmp/setup-server.sh"
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = tolist(self.ipv4)[0]
    }
  }

  # Start the CrowdLlama DHT service
  provisioner "remote-exec" {
    inline = [
      "systemctl start crowdllama-dht.service"
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = tolist(self.ipv4)[0]
    }
  }
}

# Create firewall for the DHT server
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

# Create DNS record for the DHT server (optional)
resource "linode_domain_record" "dht_dns" {
  count   = var.create_dns_record ? 1 : 0
  domain_id = var.domain_id
  name      = var.dns_subdomain
  record_type = "A"
  target      = tolist(linode_instance.dht_server.ipv4)[0]
  ttl_sec     = 300
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