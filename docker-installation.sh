#!/bin/bash

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root or with sudo.${NC}"
    exit 1
fi

echo -e "${GREEN}Starting Docker and Docker Compose installation/upgrade on Ubuntu...${NC}"

# Step 1: Update package index
echo "Updating package index..."
apt update && apt upgrade -y

# Step 2: Install prerequisites
echo "Installing required packages..."
apt install -y apt-transport-https ca-certificates curl software-properties-common

# Step 3: Add Docker GPG key
echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to add Docker GPG key.${NC}"
    exit 1
fi

# Step 4: Add Docker repository
echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 5: Install or upgrade Docker Engine
echo "Installing or upgrading Docker Engine..."
apt update
apt install -y docker-ce docker-ce-cli containerd.io
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to install/upgrade Docker.${NC}"
    exit 1
fi

# Step 6: Start and enable Docker
echo "Starting and enabling Docker service..."
systemctl start docker
systemctl enable docker

# Step 7: Verify Docker with version check
echo "Verifying Docker installation..."
DOCKER_VERSION=$(docker --version)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker installed/upgraded successfully: $DOCKER_VERSION${NC}"
else
    echo -e "${RED}Error: Docker installation/upgrade failed.${NC}"
    exit 1
fi

# Step 8: Add current user to docker group
CURRENT_USER=$(whoami)
echo "Adding user '$CURRENT_USER' to docker group..."
usermod -aG docker "$CURRENT_USER"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}User '$CURRENT_USER' added to docker group. Log out and back in to apply, or run 'newgrp docker'.${NC}"
else
    echo -e "${RED}Error: Failed to add user to docker group. You might need to do this manually.${NC}"
fi

# Step 9: Install or upgrade Docker Compose plugin
echo "Installing or upgrading Docker Compose plugin..."
apt update
apt install -y docker-compose-plugin
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to install/upgrade Docker Compose plugin.${NC}"
    exit 1
fi

sudo usermod -aG docker $USER
newgrp docker

# Step 10: Verify Docker Compose with version check
echo "Verifying Docker Compose installation..."
DOCKER_COMPOSE_VERSION=$(docker compose version)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker Compose installed/upgraded successfully: $DOCKER_COMPOSE_VERSION${NC}"
else
    echo -e "${RED}Error: Docker Compose installation/upgrade failed.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker and Docker Compose installation/upgrade completed successfully!${NC}"
echo "To use Docker without sudo, log out and back in, or run 'newgrp docker'."
echo "You can now navigate to your project directory and run 'docker compose up --build'."
