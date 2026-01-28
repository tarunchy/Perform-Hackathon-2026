# 🎰 Vegas Casino – Hackathon Ready Guide
## Dynatrace Perform 2026 Hackathon

This document provides a complete guide to deploying, testing, and demonstrating the Vegas Casino observability application.

---

## 🚀 Quick Start (GitHub Codespaces)

### Prerequisites
All required secrets are already configured in Codespaces:
- `DYNATRACE_ENVIRONMENT_ID`
- `DYNATRACE_API_TOKEN`
- `DYNATRACE_PLATFORM_TOKEN`
- `DYNATRACE_OAUTH_CLIENT_ID`
- `DYNATRACE_OAUTH_CLIENT_SECRET`
- `DYNATRACE_ACCOUNT_ID`
- `DYNATRACE_CONFIG_API_TOKEN`

### Deployment Steps

1. **Build and Load Docker Images**
   ```bash
   ./build-and-load-kind.sh
   ```
   This builds all service images locally and loads them into the KIND cluster (~15 minutes).

2. **Deploy OpenTelemetry & Infrastructure**
   ```bash
   bash codespace/deployment.sh
   ```
   Installs cert-manager, open-feature operator, and OTel collectors.

3. **Deploy Application with Helm**
   ```bash
   helm install vegas-casino ./helm/vegas-casino \
     -n vegas-casino --create-namespace \
     -f ./helm/vegas-casino/values.kind.yaml \
     --set global.dynatrace.environmentId="${DYNATRACE_ENVIRONMENT_ID}" \
     --set global.dynatrace.apiToken="${DYNATRACE_API_TOKEN}" \
     --set global.dynatrace.oauthClientId="${DYNATRACE_OAUTH_CLIENT_ID}" \
     --set global.dynatrace.oauthClientSecret="${DYNATRACE_OAUTH_CLIENT_SECRET}" \
     --set global.dynatrace.accountId="${DYNATRACE_ACCOUNT_ID}"
   ```

4. **Verify Deployment**
   ```bash
   kubectl get pods -n vegas-casino
   ```
   All pods should show `Running` status (10 pods total).

5. **Port Forward Services**
   ```bash
   # Gateway (Backend API)
   kubectl port-forward -n vegas-casino svc/vegas-casino-gateway 38080:8080 --address=0.0.0.0 &
   
   # Frontend (UI)
   kubectl port-forward -n vegas-casino svc/vegas-casino-frontend 3000:3000 --address=0.0.0.0 &
   ```

6. **Access the Application**
   - **Frontend UI**: Click the "Ports" tab in Codespaces → Open port 3000
   - **Gateway API**: http://localhost:38080/api/health
   - **Dashboard**: Access via frontend menu

---

## 🎮 How to Use the Casino

### Playing Games
1. Open the Frontend UI (port 3000)
2. Enter a username (e.g., `hackathon-judge`)
3. Set an initial deposit (e.g., $1000)
4. Choose a game:
   - **Slots** (Node.js) - High variance, 100x max payout
   - **Roulette** (Python) - Table game, 36x max payout
   - **Dice** (Go) - Simple dice rolling, 2x max payout
   - **Blackjack** (Node.js) - Card game, 2.5x max payout
5. Place bets and play!

### Generating Traffic for Observability
The app automatically generates telemetry with each game play. For load testing:

```bash
# Manual load test with curl
for i in {1..10}; do
  curl -X POST http://localhost:38080/api/slots/spin \
    -H "Content-Type: application/json" \
    -d '{"username":"loadtest","bet_amount":50}'
  sleep 1
done
```

---

## 📊 Observability Features

### What Was Improved for the Hackathon

#### 1. **End-to-End Trace Propagation** ✅
- Full distributed tracing across all services
- W3C Trace Context propagation through:
  - Frontend → Gateway → Game Services → Scoring → Database
  - HTTP and gRPC requests
- OpenTelemetry auto-instrumentation with manual spans where needed

#### 2. **Log-Trace Correlation** ✅
All logs now include trace context for perfect correlation in Dynatrace:

**Node.js Services** (`services/common/logger.js`):
- Extracts active span context from OpenTelemetry
- Adds `trace.id`, `span.id`, `trace.flags` to every log entry

**Python Services** (`services/common/logger.py`):
- Uses OpenTelemetry Python API
- Formats trace IDs consistently (32-char hex format)

Example log output:
```json
{
  "timestamp": "2026-01-28T22:00:00.000Z",
  "service": "vegas-slots-service",
  "level": "INFO",
  "category": "game",
  "event": "start",
  "trace.id": "a1b2c3d4e5f6789012345678901234",
  "span.id": "1234567890abcdef",
  "username": "player1",
  "bet_amount": 50
}
```

#### 3. **Enhanced Span Attributes** ✅
Added rich business context to traces visible in Dynatrace:
- `game.type` - Game name (slots, roulette, dice, blackjack)
- `game.action` - spin, roll, deal, bet
- `bet.amount` - Bet size
- `game.outcome` - win/loss result
- `game.payout` - Winnings amount
- `feature_flag.progressive_jackpot` - Feature flag state
- `feature_flag.house_advantage` - House advantage enabled
- `feature_flag.cheat_detection` - Cheat detection active
- `game.cheat_active` - Cheat attempt detected
- `db.redis.*` - Redis operation details
- `db.system` - Database type

#### 4. **Correct Span Status Usage** ✅
Fixed incorrect OpenTelemetry span status codes throughout the codebase:
- **Before**: Using numeric codes (1 for OK, 2 for ERROR)
- **After**: Using proper constants (`SpanStatusCode.OK`, `SpanStatusCode.ERROR`)
- Files fixed:
  - `services/common/redis.js` - All Redis operations
  - `services/dashboard/dashboard-service-grpc.js` - Dashboard analytics

#### 5. **Kubernetes-Aware Gateway** ✅
Fixed gateway service to properly detect Kubernetes environment:
- Checks for `KUBERNETES_SERVICE_HOST` or service URL environment variables
- Skips starting child processes when running in K8s (each service in its own pod)
- Routes to independent service pods via ClusterIP services
- Prevents "InvalidImageName" errors from monolithic deployment code

---

## 🏆 2-Minute Demo Script for Judges

### Setup (30 seconds)
```bash
# Show healthy deployment
kubectl get pods -n vegas-casino

# Output should show:
# NAME                                     READY   STATUS    RESTARTS
# vegas-casino-blackjack-xxx               2/2     Running   0
# vegas-casino-dashboard-xxx               1/1     Running   0
# vegas-casino-dice-xxx                    2/2     Running   0
# vegas-casino-frontend-xxx                2/2     Running   0
# vegas-casino-gateway-xxx                 1/1     Running   0
# vegas-casino-postgresql-xxx              1/1     Running   0
# vegas-casino-redis-xxx                   1/1     Running   0
# vegas-casino-roulette-xxx                2/2     Running   0
# vegas-casino-scoring-xxx                 1/1     Running   0
# vegas-casino-slots-xxx                   2/2     Running   0
```

### Demo Flow (90 seconds)

**"Welcome to Vegas Casino - a production-grade observability showcase"**

1. **Play a Game** (20 seconds)
   - Open Frontend UI in browser
   - Enter username: `judge-demo`
   - Deposit: $1000
   - Play Slots with $50 bet
   - Show win/loss result in UI

2. **Show Distributed Trace in Dynatrace** (35 seconds)
   - Open Dynatrace → Applications & Microservices → Distributed Traces
   - Filter by service: `vegas-slots-service`
   - Select recent trace, expand to show:
     - ✅ **Frontend** → **Gateway** → **Slots** → **Scoring** → **PostgreSQL**
     - ✅ Feature flag evaluations visible as span attributes
     - ✅ Redis caching operations traced
     - ✅ Database queries captured
     - ✅ Business metrics: bet amount, payout, game result

3. **Show Log-Trace Correlation** (20 seconds)
   - Click on the **Slots** span in the trace
   - Navigate to "View related logs"
   - Show structured JSON logs with matching `trace.id` and `span.id`
   - Highlight business context in logs:
     ```json
     {
       "event": "start",
       "username": "judge-demo",
       "bet_amount": 50,
       "trace.id": "abc123...",
       "feature_flag.progressive_jackpot": true
     }
     ```

4. **Show Multi-Language Support** (15 seconds)
   - Point out services in different languages:
     - **Node.js**: Slots, Blackjack, Gateway, Frontend
     - **Python**: Roulette
     - **Go**: Dice
     - **Java**: Scoring
   - All instrumented with OpenTelemetry!

**Closing:**  
*"All services are auto-instrumented with OpenTelemetry, using W3C trace propagation, enriched with business context, and integrated natively with Dynatrace. This is production-ready observability!"*

---

## 🔧 Troubleshooting

### Pods Not Starting
```bash
# Describe the pod to see events
kubectl describe pod -n vegas-casino <pod-name>

# Check logs
kubectl logs -n vegas-casino <pod-name>

# For multi-container pods (with flagd sidecar)
kubectl logs -n vegas-casino <pod-name> -c <container-name>
```

### Images Not Found
If you see `InvalidImageName` or `ImagePullBackOff`:
```bash
# Rebuild and reload all images
./build-and-load-kind.sh

# Restart deployments
kubectl rollout restart deployment -n vegas-casino
```

### Gateway Not Routing to Services
```bash
# Check service endpoints
kubectl get svc -n vegas-casino
kubectl get endpoints -n vegas-casino

# Check gateway logs
kubectl logs -n vegas-casino -l app.kubernetes.io/component=gateway

# You should see: "☸️ Running in Kubernetes mode - services are separate pods"
```

### OTel Collector Not Sending Data
```bash
# Check collector status
kubectl get pods -n default | grep otel-collector

# Check collector logs
kubectl logs -n default otel-collector-statefulset-0

# Verify configuration
kubectl get configmap -n default otel-collector-statefulset-config -o yaml
```

### Port Forward Stops Working
```bash
# Kill existing port forwards
pkill -f "port-forward.*vegas-casino"

# Restart them
kubectl port-forward -n vegas-casino svc/vegas-casino-gateway 38080:8080 --address=0.0.0.0 &
kubectl port-forward -n vegas-casino svc/vegas-casino-frontend 3000:3000 --address=0.0.0.0 &
```

---

## 📝 Architecture Summary

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTP
       ▼
┌─────────────────┐
│ Frontend (Node) │ ◄─── OpenFeature Flags
│   Port: 3000    │
└────────┬────────┘
         │ gRPC (W3C Trace Context)
         ▼
┌────────────────────────────────────────────┐
│          Game Services (gRPC)              │
│  ┌─────────┐ ┌──────────┐ ┌──────┐ ┌────┐│
│  │ Slots   │ │ Roulette │ │ Dice │ │ BJ ││
│  │ (Node)  │ │ (Python) │ │ (Go) │ │(JS)││
│  └────┬────┘ └─────┬────┘ └───┬──┘ └─┬──┘│
│       └────────────┼──────────┼──────┘   │
└────────────────────┼──────────┼──────────┘
                     │ HTTP     │
                     ▼          ▼
              ┌──────────────────────┐
              │ Scoring (Java/Spring)│ ◄─── Business Logic
              │    Port: 8085        │
              └──────────┬───────────┘
                         │
                 ┌───────┴────────┐
                 ▼                ▼
         ┌──────────────┐  ┌──────────┐
         │ PostgreSQL   │  │  Redis   │
         │  (Storage)   │  │ (Cache)  │
         └──────────────┘  └──────────┘

┌───────────────────────────────────────────┐
│       OpenTelemetry Collector             │
│  ┌──────────────┐  ┌──────────────────┐  │
│  │  DaemonSet   │  │  StatefulSet     │  │
│  │ (Node agent) │  │ (Aggregation)    │  │
│  └──────┬───────┘  └────────┬─────────┘  │
│         └──────────┬─────────┘            │
└────────────────────┼──────────────────────┘
                     │ OTLP/gRPC
                     ▼
            ┌─────────────────┐
            │   Dynatrace     │
            │    Tenant       │
            └─────────────────┘
```

### Component Details

| Component | Language | Port | Purpose |
|-----------|----------|------|---------|
| **Frontend** | Node.js | 3000 | React UI, user interface |
| **Gateway** | Node.js | 8080 | API gateway, routing, BizEvents |
| **Slots** | Node.js | 8081 (HTTP), 50051 (gRPC) | Slot machine game |
| **Roulette** | Python | 8082 (HTTP), 50052 (gRPC) | Roulette game |
| **Dice** | Go | 8083 (HTTP), 50053 (gRPC) | Dice rolling game |
| **Blackjack** | Node.js | 8084 (HTTP), 50054 (gRPC) | Card game |
| **Dashboard** | Node.js | 3001 (HTTP), 50055 (gRPC) | Analytics & stats |
| **Scoring** | Java Spring | 8085 | Game history & persistence |
| **PostgreSQL** | PostgreSQL | 5432 | Relational database |
| **Redis** | Redis | 6379 | Caching & session state |
| **OTel Collector** | OTEL | 4317 (gRPC), 4318 (HTTP) | Telemetry aggregation |

---

## 🎯 Key Hackathon Points

### ✅ What We Built
- [x] **Production-Ready Kubernetes Deployment** - Helm chart with KIND support
- [x] **Full OpenTelemetry Auto-Instrumentation** - All 4 languages (Node.js, Python, Go, Java)
- [x] **Log-Trace Correlation** - Implemented in common logger libraries
- [x] **Rich Span Attributes** - Business context in every trace
- [x] **Multi-Language Support** - Consistent OTel across tech stack
- [x] **Feature Flag Observability** - OpenFeature integration traced
- [x] **Database & Cache Tracing** - PostgreSQL + Redis operations visible
- [x] **Cheat Detection Monitoring** - Security events traced
- [x] **Real-Time Dashboard Analytics** - gRPC-based stats service
- [x] **W3C Trace Context Propagation** - Standard headers across HTTP/gRPC

### 🚀 What Makes This Special
1. **Real Microservices Architecture** - Not a toy demo, actual distributed system
2. **Multi-Protocol Tracing** - HTTP, gRPC, WebSocket all traced
3. **Business Context Throughout** - Every trace tells a business story
4. **Production Patterns** - Proper error handling, status codes, exception recording
5. **DevOps Ready** - CI/CD friendly, Helm charts, environment-based config

---

## 📚 Additional Resources

- **Detailed Setup Guide**: [codespace/HACKATHON_READY.md](codespace/HACKATHON_READY.md)
- **Architecture Docs**: [docs/architecture/](docs/architecture/)
- **Deployment Options**: [docs/deployment/](docs/deployment/)
- **Contributing**: [docs/contributing.md](docs/contributing.md)

---

## 🏁 Quick Verification Checklist

Before the demo, verify:
- [ ] All 10 pods in `vegas-casino` namespace are `Running`
- [ ] Port forwards active on 3000 (frontend) and 38080 (gateway)
- [ ] Frontend UI loads successfully
- [ ] Can play at least one game end-to-end
- [ ] Dynatrace shows traces for the game services
- [ ] Logs in Dynatrace include `trace.id` field
- [ ] Span attributes include business context (bet_amount, game outcome, etc.)

---

**Built for Dynatrace Perform 2026 Hackathon**  
*Demonstrating enterprise-grade observability in a multi-language microservices application*

**Team**: Vegas Casino Observability Squad  
**Challenge**: End-to-end observability with OpenTelemetry + Dynatrace  
**Status**: ✅ **READY TO DEMO**
