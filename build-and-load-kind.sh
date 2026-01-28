#!/bin/bash
set -e

# Build and load images for KIND cluster
# This script builds all Vegas Casino service images locally and loads them into KIND

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGISTRY="vegasapp"
TAG="latest"

echo -e "${GREEN}=== Building Vegas Casino Images for KIND ===${NC}\n"

# Array of services to build
SERVICES=(
  "gateway"
  "frontend"
  "slots"
  "roulette"
  "dice"
  "blackjack"
  "dashboard"
  "scoring"
  "k6"
  "playwright"
)

# Build each service
for service in "${SERVICES[@]}"; do
  echo -e "${YELLOW}Building ${service}...${NC}"
  docker build -f services/${service}/Dockerfile -t ${REGISTRY}-${service}:${TAG} . 
done

echo -e "\n${GREEN}=== Loading Images into KIND Cluster ===${NC}\n"

# Load images into KIND
for service in "${SERVICES[@]}"; do
  echo -e "${YELLOW}Loading ${service} into KIND...${NC}"
  kind load docker-image ${REGISTRY}-${service}:${TAG}
done

echo -e "\n${GREEN}✓ All images built and loaded into KIND!${NC}"
