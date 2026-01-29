#!/bin/bash
set -e

echo "🔨 Vegas Casino - Rebuild and Deploy Script"
echo "============================================"

# Source Dynatrace secrets if available
if [ -f /tmp/dynatrace-secrets.sh ]; then
  echo "📋 Loading Dynatrace secrets from /tmp/dynatrace-secrets.sh..."
  source /tmp/dynatrace-secrets.sh
  echo "✅ Dynatrace secrets loaded"
else
  echo "⚠️  Warning: /tmp/dynatrace-secrets.sh not found. Dynatrace integration may not work."
fi

# Verify Docker is running
if ! docker ps > /dev/null 2>&1; then
  echo "❌ Error: Docker is not running or not accessible"
  exit 1
fi

echo ""
echo "📦 Building Node.js services with metrics..."
echo "--------------------------------------------"

# Build services that have metrics integration
SERVICES=(
  "slots"
  "blackjack"
  "dashboard"
  "gateway"
  "frontend"
)

for service in "${SERVICES[@]}"; do
  echo ""
  echo "🔧 Building $service service..."
  
  # Run npm install from service directory
  echo "  📥 Installing dependencies..."
  cd "/workspaces/Perform-Hackathon-2026/services/$service"
  npm install --silent
  
  # Build Docker image from workspace root (Dockerfile paths are relative to root)
  echo "  🐳 Building Docker image vegasapp-$service:latest..."
  cd /workspaces/Perform-Hackathon-2026
  docker build -f "services/$service/Dockerfile" -t "vegasapp-$service:latest" .
  
  # Load into KIND using ctr (more reliable than kind load)
  echo "  ⬆️  Loading image into KIND cluster..."
  docker save "vegasapp-$service:latest" | docker exec -i kind-control-plane ctr --namespace k8s.io images import - > /dev/null 2>&1
  
  echo "  ✅ $service complete"
done

# Return to root
cd /workspaces/Perform-Hackathon-2026

echo ""
echo "🎲 Rebuilding other services..."
echo "--------------------------------"

# Build Python service (roulette)
echo ""
echo "🐍 Building roulette service (Python)..."
cd /workspaces/Perform-Hackathon-2026
docker build -f services/roulette/Dockerfile -t vegasapp-roulette:latest .
docker save vegasapp-roulette:latest | docker exec -i kind-control-plane ctr --namespace k8s.io images import - > /dev/null 2>&1
echo "✅ Roulette complete"

# Build Go service (dice)
echo ""
echo "🎯 Building dice service (Go)..."
cd /workspaces/Perform-Hackathon-2026
docker build -f services/dice/Dockerfile -t vegasapp-dice:latest .
docker save vegasapp-dice:latest | docker exec -i kind-control-plane ctr --namespace k8s.io images import - > /dev/null 2>&1
echo "✅ Dice complete"

# Build Java service (scoring)
echo ""
echo "☕ Building scoring service (Java)..."
cd /workspaces/Perform-Hackathon-2026
docker build -f services/scoring/Dockerfile -t vegasapp-scoring:latest .
docker save vegasapp-scoring:latest | docker exec -i kind-control-plane ctr --namespace k8s.io images import - > /dev/null 2>&1
echo "✅ Scoring complete"

# Return to root
cd /workspaces/Perform-Hackathon-2026

echo ""
echo "🚀 Deploying to Kubernetes..."
echo "------------------------------"

# Create Helm values override with Dynatrace secrets
cat > /tmp/helm-dynatrace-override.yaml <<EOF
# Dynatrace configuration for deployment
global:
  dynatrace:
    enabled: true

# Inject Dynatrace environment variables into all services
slots:
  env:
    DYNATRACE_TENANT: "${DYNATRACE_TENANT:-}"
    DYNATRACE_API_TOKEN: "${DYNATRACE_API_TOKEN:-}"
    DYNATRACE_PAAS_TOKEN: "${DYNATRACE_PAAS_TOKEN:-}"
    DYNATRACE_INGEST_TOKEN: "${DYNATRACE_INGEST_TOKEN:-}"
    DYNATRACE_METRICS_INGEST_TOKEN: "${DYNATRACE_METRICS_INGEST_TOKEN:-}"
    DYNATRACE_LOGS_INGEST_TOKEN: "${DYNATRACE_LOGS_INGEST_TOKEN:-}"
    DYNATRACE_COLLECTOR_ENDPOINT: "${DYNATRACE_COLLECTOR_ENDPOINT:-}"
    DYNATRACE_ENVIRONMENT_ID: "${DYNATRACE_ENVIRONMENT_ID:-}"

blackjack:
  env:
    DYNATRACE_TENANT: "${DYNATRACE_TENANT:-}"
    DYNATRACE_API_TOKEN: "${DYNATRACE_API_TOKEN:-}"
    DYNATRACE_PAAS_TOKEN: "${DYNATRACE_PAAS_TOKEN:-}"
    DYNATRACE_INGEST_TOKEN: "${DYNATRACE_INGEST_TOKEN:-}"
    DYNATRACE_METRICS_INGEST_TOKEN: "${DYNATRACE_METRICS_INGEST_TOKEN:-}"
    DYNATRACE_LOGS_INGEST_TOKEN: "${DYNATRACE_LOGS_INGEST_TOKEN:-}"
    DYNATRACE_COLLECTOR_ENDPOINT: "${DYNATRACE_COLLECTOR_ENDPOINT:-}"
    DYNATRACE_ENVIRONMENT_ID: "${DYNATRACE_ENVIRONMENT_ID:-}"

roulette:
  env:
    DYNATRACE_TENANT: "${DYNATRACE_TENANT:-}"
    DYNATRACE_API_TOKEN: "${DYNATRACE_API_TOKEN:-}"
    DYNATRACE_PAAS_TOKEN: "${DYNATRACE_PAAS_TOKEN:-}"
    DYNATRACE_INGEST_TOKEN: "${DYNATRACE_INGEST_TOKEN:-}"
    DYNATRACE_METRICS_INGEST_TOKEN: "${DYNATRACE_METRICS_INGEST_TOKEN:-}"
    DYNATRACE_LOGS_INGEST_TOKEN: "${DYNATRACE_LOGS_INGEST_TOKEN:-}"
    DYNATRACE_COLLECTOR_ENDPOINT: "${DYNATRACE_COLLECTOR_ENDPOINT:-}"
    DYNATRACE_ENVIRONMENT_ID: "${DYNATRACE_ENVIRONMENT_ID:-}"

dice:
  env:
    DYNATRACE_TENANT: "${DYNATRACE_TENANT:-}"
    DYNATRACE_API_TOKEN: "${DYNATRACE_API_TOKEN:-}"
    DYNATRACE_PAAS_TOKEN: "${DYNATRACE_PAAS_TOKEN:-}"
    DYNATRACE_INGEST_TOKEN: "${DYNATRACE_INGEST_TOKEN:-}"
    DYNATRACE_METRICS_INGEST_TOKEN: "${DYNATRACE_METRICS_INGEST_TOKEN:-}"
    DYNATRACE_LOGS_INGEST_TOKEN: "${DYNATRACE_LOGS_INGEST_TOKEN:-}"
    DYNATRACE_COLLECTOR_ENDPOINT: "${DYNATRACE_COLLECTOR_ENDPOINT:-}"
    DYNATRACE_ENVIRONMENT_ID: "${DYNATRACE_ENVIRONMENT_ID:-}"

scoring:
  env:
    DYNATRACE_TENANT: "${DYNATRACE_TENANT:-}"
    DYNATRACE_API_TOKEN: "${DYNATRACE_API_TOKEN:-}"
    DYNATRACE_PAAS_TOKEN: "${DYNATRACE_PAAS_TOKEN:-}"
    DYNATRACE_INGEST_TOKEN: "${DYNATRACE_INGEST_TOKEN:-}"
    DYNATRACE_METRICS_INGEST_TOKEN: "${DYNATRACE_METRICS_INGEST_TOKEN:-}"
    DYNATRACE_LOGS_INGEST_TOKEN: "${DYNATRACE_LOGS_INGEST_TOKEN:-}"
    DYNATRACE_COLLECTOR_ENDPOINT: "${DYNATRACE_COLLECTOR_ENDPOINT:-}"
    DYNATRACE_ENVIRONMENT_ID: "${DYNATRACE_ENVIRONMENT_ID:-}"

dashboard:
  env:
    DYNATRACE_TENANT: "${DYNATRACE_TENANT:-}"
    DYNATRACE_API_TOKEN: "${DYNATRACE_API_TOKEN:-}"
    DYNATRACE_PAAS_TOKEN: "${DYNATRACE_PAAS_TOKEN:-}"
    DYNATRACE_INGEST_TOKEN: "${DYNATRACE_INGEST_TOKEN:-}"
    DYNATRACE_METRICS_INGEST_TOKEN: "${DYNATRACE_METRICS_INGEST_TOKEN:-}"
    DYNATRACE_LOGS_INGEST_TOKEN: "${DYNATRACE_LOGS_INGEST_TOKEN:-}"
    DYNATRACE_COLLECTOR_ENDPOINT: "${DYNATRACE_COLLECTOR_ENDPOINT:-}"
    DYNATRACE_ENVIRONMENT_ID: "${DYNATRACE_ENVIRONMENT_ID:-}"

gateway:
  env:
    DYNATRACE_TENANT: "${DYNATRACE_TENANT:-}"
    DYNATRACE_API_TOKEN: "${DYNATRACE_API_TOKEN:-}"
    DYNATRACE_PAAS_TOKEN: "${DYNATRACE_PAAS_TOKEN:-}"
    DYNATRACE_INGEST_TOKEN: "${DYNATRACE_INGEST_TOKEN:-}"
    DYNATRACE_METRICS_INGEST_TOKEN: "${DYNATRACE_METRICS_INGEST_TOKEN:-}"
    DYNATRACE_LOGS_INGEST_TOKEN: "${DYNATRACE_LOGS_INGEST_TOKEN:-}"
    DYNATRACE_COLLECTOR_ENDPOINT: "${DYNATRACE_COLLECTOR_ENDPOINT:-}"
    DYNATRACE_ENVIRONMENT_ID: "${DYNATRACE_ENVIRONMENT_ID:-}"

frontend:
  env:
    DYNATRACE_TENANT: "${DYNATRACE_TENANT:-}"
    DYNATRACE_API_TOKEN: "${DYNATRACE_API_TOKEN:-}"
    DYNATRACE_PAAS_TOKEN: "${DYNATRACE_PAAS_TOKEN:-}"
    DYNATRACE_INGEST_TOKEN: "${DYNATRACE_INGEST_TOKEN:-}"
    DYNATRACE_METRICS_INGEST_TOKEN: "${DYNATRACE_METRICS_INGEST_TOKEN:-}"
    DYNATRACE_LOGS_INGEST_TOKEN: "${DYNATRACE_LOGS_INGEST_TOKEN:-}"
    DYNATRACE_COLLECTOR_ENDPOINT: "${DYNATRACE_COLLECTOR_ENDPOINT:-}"
    DYNATRACE_ENVIRONMENT_ID: "${DYNATRACE_ENVIRONMENT_ID:-}"
EOF

echo "✅ Created Dynatrace override file: /tmp/helm-dynatrace-override.yaml"

# Upgrade Helm deployment
echo ""
echo "⚙️  Upgrading Helm release 'vegas-casino'..."
helm upgrade vegas-casino ./helm/vegas-casino \
  -f ./helm/vegas-casino/values.kind.yaml \
  -f /tmp/helm-dynatrace-override.yaml \
  --namespace vegas-casino \
  --create-namespace \
  --wait \
  --timeout 5m

echo ""
echo "♻️  Restarting pods to pick up new images..."
kubectl rollout restart deployment -n vegas-casino

echo ""
echo "⏳ Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=vegas-casino -n vegas-casino --timeout=300s

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo "======================="
echo ""
echo "📊 Cluster Status:"
kubectl get pods -n vegas-casino
echo ""
echo "🔍 Verify metrics integration:"
echo "   kubectl logs -n vegas-casino -l app=slots --tail=50 | grep -i metric"
echo ""
echo "🌐 Access applications:"
echo "   Gateway:  http://localhost:38080  (if port-forward is running)"
echo "   Frontend: http://localhost:3000   (if port-forward is running)"
echo ""
echo "🎯 Next steps:"
echo "   1. Run traffic generation: ./run-traffic-tests.sh"
echo "   2. Check Dynatrace for telemetry: https://${DYNATRACE_TENANT}"
echo ""
