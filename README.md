# CrowdLlama Infrastructure

This repository contains Terraform configurations to deploy the [CrowdLlama](https://github.com/matiasinsaurralde/crowdllama) DHT server on Linode cloud infrastructure.

## Overview

CrowdLlama is a distributed system that leverages the open-source Ollama project to run LLM inference tasks across multiple nodes using peer-to-peer (P2P) networking. This infrastructure focuses on deploying the DHT (Distributed Hash Table) server component.

## Architecture

The deployment includes:

- **Linode Instance**: Ubuntu 22.04 server running the DHT component
- **Docker & Docker Compose**: Containerized deployment with automatic updates
- **Watchtower**: Automatically updates containers when new images are pushed to GHCR
- **Firewall**: Configured to allow SSH (port 22) and DHT traffic (port 9000)
- **Systemd Service**: Ensures the DHT server starts automatically on boot

## Prerequisites

1. **Linode Account**: You need a Linode account with API access
2. **Linode API Token**: Generate a token at https://cloud.linode.com/profile/tokens
3. **Terraform**: Install Terraform (version >= 1.0)
4. **GitHub Repository**: Ensure your CrowdLlama repository has GitHub Actions enabled

## Quick Start

### 1. Clone and Configure

```bash
git clone <your-infra-repo>
cd infra

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration with your values
nano terraform.tfvars
```

### 2. Configure Variables

Edit `terraform.tfvars` with your specific values:

```hcl
# Required
linode_token = "your-linode-api-token"
root_password = "your-secure-root-password"

# Optional (defaults shown)
environment = "prod"
linode_region = "us-east"
linode_instance_type = "g6-standard-1"
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Verify Deployment

After deployment, you can:

```bash
# Get the server IP
terraform output dht_server_ip

# SSH into the server
terraform output dht_server_ssh_command

# Check service status
ssh root@<server-ip> "systemctl status crowdllama-dht"
```

## Docker Images

The deployment expects Docker images to be available at:
- `ghcr.io/matiasinsaurralde/crowdllama/dht:latest`

### Building and Pushing Images

To build and push new Docker images:

1. **Tag your release**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically**:
   - Build the Docker image from `Dockerfile.dht`
   - Push to GitHub Container Registry (GHCR)
   - Tag with version and `latest`

3. **Watchtower will automatically**:
   - Detect new images every 5 minutes
   - Pull and restart containers with new images
   - Clean up old images

## Configuration

### Instance Types

Available Linode instance types:
- `g6-standard-1`: 1 CPU, 2GB RAM (default)
- `g6-standard-2`: 2 CPU, 4GB RAM
- `g6-standard-4`: 4 CPU, 8GB RAM

### Regions

Available Linode regions:
- `us-east`: Newark, NJ
- `us-west`: Fremont, CA
- `us-central`: Dallas, TX
- `us-southeast`: Atlanta, GA
- `us-southwest`: Dallas, TX
- `ap-west`: Singapore
- `ap-southeast`: Sydney, Australia
- `ap-south`: Mumbai, India
- `ap-northeast`: Tokyo, Japan
- `eu-central`: Frankfurt, Germany
- `eu-west`: London, UK

### DNS Configuration

To enable DNS records:

```hcl
create_dns_record = true
domain_id = 12345  # Your Linode domain ID
dns_subdomain = "dht"
```

## Monitoring and Logs

### Service Management

```bash
# Check service status
systemctl status crowdllama-dht

# View logs
journalctl -u crowdllama-dht -f

# Restart service
systemctl restart crowdllama-dht
```

### Docker Logs

```bash
# View container logs
docker-compose -f /opt/crowdllama/docker-compose.yml logs -f

# View specific service logs
docker-compose -f /opt/crowdllama/docker-compose.yml logs -f dht
```

### Watchtower Logs

```bash
# View Watchtower logs
docker-compose -f /opt/crowdllama/docker-compose.yml logs -f watchtower
```

## Security

### Firewall Rules

The deployment includes a firewall with the following rules:

- **Inbound**:
  - SSH (TCP 22): Allowed from anywhere
  - DHT (TCP/UDP 9000): Allowed from anywhere

- **Outbound**:
  - All traffic allowed

### Recommendations

1. **SSH Key Authentication**: Consider setting up SSH keys instead of password authentication
2. **Restrict SSH Access**: Limit SSH access to specific IP ranges in production
3. **Regular Updates**: Keep the system updated with security patches
4. **Monitoring**: Set up monitoring and alerting for the DHT service

## Troubleshooting

### Common Issues

1. **Container won't start**:
   ```bash
   docker-compose -f /opt/crowdllama/docker-compose.yml logs dht
   ```

2. **Port 9000 not accessible**:
   ```bash
   # Check if port is listening
   netstat -tlnp | grep 9000
   
   # Check firewall status
   ufw status
   ```

3. **Watchtower not updating**:
   ```bash
   # Check Watchtower logs
   docker-compose -f /opt/crowdllama/docker-compose.yml logs watchtower
   
   # Manually pull latest image
   docker pull ghcr.io/matiasinsaurralde/crowdllama/dht:latest
   ```

### Manual Container Management

```bash
# Stop all containers
docker-compose -f /opt/crowdllama/docker-compose.yml down

# Start all containers
docker-compose -f /opt/crowdllama/docker-compose.yml up -d

# Rebuild and restart
docker-compose -f /opt/crowdllama/docker-compose.yml up -d --build
```

## Development

### Local Testing

To test the Docker Compose setup locally:

```bash
# Clone the CrowdLlama repository
git clone https://github.com/matiasinsaurralde/crowdllama.git
cd crowdllama

# Build the DHT image
docker build -f Dockerfile.dht -t crowdllama/dht:latest .

# Run locally
docker-compose up -d
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support

For issues related to:
- **Infrastructure**: Create an issue in this repository
- **CrowdLlama**: Create an issue in the [main repository](https://github.com/matiasinsaurralde/crowdllama)
