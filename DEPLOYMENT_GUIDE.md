# CrowdLlama Deployment Guide

This guide explains how to deploy the CrowdLlama DHT server using the infrastructure in this repository.

## Prerequisites

1. **CrowdLlama Repository**: Ensure your CrowdLlama repository has the necessary Dockerfile for the DHT component
2. **GitHub Actions**: Enable GitHub Actions in your repository
3. **GitHub Container Registry**: Ensure your repository has access to GHCR

## Required Files in CrowdLlama Repository

Your CrowdLlama repository should have a `Dockerfile.dht` file that builds the DHT component. Here's an example structure:

```
crowdllama/
├── cmd/
│   └── dht/
│       └── main.go
├── Dockerfile.dht
├── .github/
│   └── workflows/
│       └── docker-build.yml
└── ...
```

### Example Dockerfile.dht

```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o dht ./cmd/dht

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/dht .
EXPOSE 9000

CMD ["./dht"]
```

## Deployment Process

### 1. Set Up Infrastructure

```bash
# Clone this infrastructure repository
git clone <your-infra-repo>
cd infra

# Configure your deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Linode credentials

# Deploy infrastructure
make init
make plan
make apply
```

### 2. Build and Push Docker Images

When you want to deploy a new version:

```bash
# In your CrowdLlama repository
git tag v1.0.0
git push origin v1.0.0
```

This will trigger the GitHub Actions workflow that:
1. Builds the Docker image
2. Pushes it to `ghcr.io/matiasinsaurralde/crowdllama/dht:latest`
3. Also tags it with the version number

### 3. Automatic Deployment

The deployed infrastructure includes Watchtower, which will:
1. Check for new images every 5 minutes
2. Automatically pull and restart containers with new images
3. Clean up old images

## Monitoring Deployment

### Check Deployment Status

```bash
# From the infrastructure directory
make status
make logs
```

### Health Check

```bash
# Run health check
./health-check.sh
```

### Manual Container Management

If you need to manually manage containers:

```bash
# SSH into the server
make ssh

# View container status
docker-compose -f /opt/crowdllama/docker-compose.yml ps

# View logs
docker-compose -f /opt/crowdllama/docker-compose.yml logs -f dht

# Restart containers
docker-compose -f /opt/crowdllama/docker-compose.yml restart
```

## Troubleshooting

### Image Not Updating

1. **Check GitHub Actions**: Ensure the workflow completed successfully
2. **Check Watchtower Logs**: `docker-compose -f /opt/crowdllama/docker-compose.yml logs watchtower`
3. **Manual Pull**: `docker pull ghcr.io/matiasinsaurralde/crowdllama/dht:latest`

### Container Won't Start

1. **Check Logs**: `docker-compose -f /opt/crowdllama/docker-compose.yml logs dht`
2. **Check Image**: `docker images | grep crowdllama`
3. **Rebuild**: `docker-compose -f /opt/crowdllama/docker-compose.yml up -d --build`

### Port Issues

1. **Check Firewall**: Ensure port 9000 is open in Linode firewall
2. **Check Container**: `docker-compose -f /opt/crowdllama/docker-compose.yml ps`
3. **Check Port**: `netstat -tlnp | grep 9000`

## Security Considerations

1. **API Tokens**: Keep your Linode API token secure
2. **SSH Access**: Consider using SSH keys instead of passwords
3. **Firewall**: Review and restrict firewall rules as needed
4. **Updates**: Keep the system updated with security patches

## Scaling

To scale the deployment:

1. **Increase Instance Size**: Modify `linode_instance_type` in terraform.tfvars
2. **Multiple Instances**: Clone the infrastructure for multiple DHT nodes
3. **Load Balancing**: Add a load balancer for multiple DHT instances

## Cost Optimization

1. **Instance Size**: Start with `g6-standard-1` and scale as needed
2. **Region**: Choose the closest region to your users
3. **Monitoring**: Monitor usage and adjust resources accordingly

## Support

For issues with:
- **Infrastructure**: Create an issue in this repository
- **CrowdLlama**: Create an issue in the main CrowdLlama repository
- **Deployment**: Check the troubleshooting section above 