.PHONY: help init plan apply destroy output ssh logs status clean

# Default target
help:
	@echo "CrowdLlama Infrastructure Management"
	@echo ""
	@echo "Available commands:"
	@echo "  init     - Initialize Terraform"
	@echo "  plan     - Show Terraform execution plan"
	@echo "  apply    - Apply Terraform configuration"
	@echo "  destroy  - Destroy infrastructure"
	@echo "  output   - Show Terraform outputs"
	@echo "  ssh      - SSH into the DHT server"
	@echo "  logs     - View DHT server logs"
	@echo "  status   - Check DHT server status"
	@echo "  clean    - Clean up Terraform files"

# Initialize Terraform
init:
	@echo "🔧 Initializing Terraform..."
	terraform init

# Show execution plan
plan:
	@echo "📋 Showing Terraform execution plan..."
	terraform plan

# Apply configuration
apply:
	@echo "🚀 Applying Terraform configuration..."
	terraform apply

# Destroy infrastructure
destroy:
	@echo "🗑️  Destroying infrastructure..."
	terraform destroy

# Show outputs
output:
	@echo "📤 Terraform outputs:"
	terraform output

# SSH into the server
ssh:
	@echo "🔌 Connecting to DHT server..."
	@ssh root@$$(terraform output -raw dht_server_ip)

# View logs
logs:
	@echo "📋 Viewing DHT server logs..."
	@ssh root@$$(terraform output -raw dht_server_ip) "docker-compose -f /opt/crowdllama/docker-compose.yml logs -f"

# Check status
status:
	@echo "📊 Checking DHT server status..."
	@ssh root@$$(terraform output -raw dht_server_ip) "systemctl status crowdllama-dht"

# Clean up
clean:
	@echo "🧹 Cleaning up Terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f *.tfstate*
	rm -f crash.log

# Setup local development
setup-local:
	@echo "🔧 Setting up local development environment..."
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "⚠️  Please edit terraform.tfvars with your configuration"; \
	else \
		echo "✅ terraform.tfvars already exists"; \
	fi

# Validate configuration
validate:
	@echo "✅ Validating Terraform configuration..."
	terraform validate

# Format Terraform files
fmt:
	@echo "🎨 Formatting Terraform files..."
	terraform fmt -recursive

# Show current state
state:
	@echo "📊 Current Terraform state:"
	terraform show 