#!/bin/bash

# CrowdLlama DHT Server Setup Script
# This script installs Docker and Docker Compose on a fresh Ubuntu 22.04 system

set -e

echo "🚀 Setting up CrowdLlama DHT Server..."

# Configure package manager for non-interactive mode
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Pre-configure SSH server to prevent interactive prompts
echo "🔧 Pre-configuring SSH server..."
echo "openssh-server openssh-server/permit-root-login boolean true" | debconf-set-selections
echo "openssh-server openssh-server/password-authentication boolean true" | debconf-set-selections

# Update system packages
echo "📦 Updating system packages..."
apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Install required packages
echo "📦 Installing required packages..."
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Add Docker's official GPG key
echo "🔑 Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "📋 Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
apt-get update

# Install Docker
echo "🐳 Installing Docker..."
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker || true
systemctl enable docker || true

# Install Docker Compose (standalone version for better compatibility)
echo "📋 Installing Docker Compose..."
if [ ! -f /usr/local/bin/docker-compose ]; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Create symbolic link
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Navigate to CrowdLlama directory (already created by Terraform)
echo "📁 Using CrowdLlama directory..."
cd /opt/crowdllama

# Copy docker-compose.yml (this will be done via Terraform)
echo "📄 Docker Compose configuration should already be present"

# Create systemd service for Docker Compose
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/crowdllama-dht.service << EOF
[Unit]
Description=CrowdLlama DHT Server
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/crowdllama
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload || true
systemctl enable crowdllama-dht.service || true

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Copy docker-compose.yml to /opt/crowdllama/"
echo "2. Start the service: systemctl start crowdllama-dht"
echo "3. Check status: systemctl status crowdllama-dht"
echo "4. View logs: docker-compose -f /opt/crowdllama/docker-compose.yml logs -f"
echo ""
echo "🌐 DHT server will be available on port 9000" 