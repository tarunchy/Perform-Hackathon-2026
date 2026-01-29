# Vegas Casino - 2-Minute Demo Script

## Pre-Demo Setup (Done in advance)
```bash
# Source Dynatrace secrets
source /tmp/dynatrace-secrets.sh

# Verify cluster is running
kubectl get pods -n vegas-casino

# Start port forwards (if not already running)
kubectl port-forward -n vegas-casino svc/vegas-casino-gateway 38080:8080 &
kubectl port-forward -n vegas-casino svc/vegas-casino-frontend 3000:3000 &
```

## Demo Flow (2 minutes)

### 1. Show the Application (15 seconds)
**Narration:** "This is the Vegas Casino app - a polyglot microservices application with 10 services in Node.js, Python, Go, and Java."

**Actions:**
- Open browser to `http://localhost:3000`
- Show the casino games interface (Slots, Blackjack, Roulette, Dice)
- Highlight the real-time leaderboard

**Visual:** Clean, modern casino UI with multiple game options

---

### 2. Demonstrate Gameplay & Telemetry Generation (30 seconds)
**Narration:** "Let's play a few games to generate telemetry - slots and blackjack. Each game action creates traces, logs with correlation, and custom metrics."

**Actions:**
```bash
# Play 5 games of each type automatically
for i in {1..5}; do
  # Slots
  curl -X POST http://localhost:38080/api/slots/spin \
    -H "Content-Type: application/json" \
    -d '{"username":"demo-user","betAmount":10}'
  
  # Blackjack
  curl -X POST http://localhost:38080/api/blackjack/deal \
    -H "Content-Type: application/json" \
    -d '{"username":"demo-user","betAmount":20}'
done
```

**Visual:** Terminal showing successful API responses with game results

---

### 3. Show Observability Implementation (45 seconds)
**Narration:** "Now let's see what makes this observable. We've implemented three key enhancements:"

#### A. **Trace Propagation** (15 sec)
**Actions:**
```bash
# Show W3C Trace Context headers flowing through services
kubectl logs -n vegas-casino -l app=gateway --tail=5 | grep -i "traceparent"
```

**Visual:** Logs showing `traceparent` and `tracestate` headers being propagated

#### B. **Log-Trace Correlation** (15 sec)
**Actions:**
```bash
# Show structured logs with trace.id and span.id
kubectl logs -n vegas-casino -l app=slots --tail=10 | grep "trace.id"
```

**Visual:** JSON logs with embedded `trace.id` and `span.id` fields for correlation

#### C. **Custom Metrics** (15 sec)
**Actions:**
```bash
# Show metrics code implementation
cat services/common/metrics.js | grep -A 3 "game_plays_total\|game_wins_total\|bet_amount"
```

**Visual:** OpenTelemetry metrics code showing:
- `game_plays_total` (Counter)
- `game_wins_total` (Counter)
- `bet_amount` (Histogram)
- `game_latency_ms` (Histogram)
- `scoring_latency_ms` (Histogram)

---

### 4. Navigate to Dynatrace (30 seconds)
**Narration:** "All this telemetry flows to Dynatrace through OpenTelemetry collectors. Let's see it in action."

**Actions:**
1. Open Dynatrace: `https://vjg01043.live.dynatrace.com`
2. Navigate to **Services** → Filter by `vegas-`
3. Click on `vegas-slots-service` or `vegas-gateway`
4. Show:
   - **Service Flow**: Visualize calls between Gateway → Slots → Scoring
   - **Distributed Traces**: Click recent trace to show full span hierarchy
   - **Logs**: Click "View Logs" and show correlated logs with `trace.id`
   - **Metrics** (if custom metrics visible): Show game_plays_total chart

**Visual:** 
- Service dependency map showing all 10 Vegas Casino services
- End-to-end distributed trace with timing breakdown
- Logs panel showing structured JSON with trace correlation
- (Optional) Custom metrics dashboard if OTel metrics are ingested

---

## Key Talking Points

### Architecture
- **10 microservices**: Gateway, Frontend, Dashboard, Slots, Blackjack, Roulette, Dice, Scoring, Redis, PostgreSQL
- **4 languages**: Node.js (5 services), Python (1), Go (1), Java (1)
- **Kubernetes deployment**: KIND cluster with Helm charts
- **OpenTelemetry**: Auto-instrumentation + manual custom metrics

### Observability Enhancements
1. **W3C Trace Context Propagation**
   - Uses `traceparent` and `tracestate` headers
   - Flows through HTTP and gRPC calls
   - Enables end-to-end distributed tracing

2. **Log-Trace Correlation**
   - Every log entry includes `trace.id` and `span.id`
   - Enables jumping from trace to logs and vice versa
   - Implemented in both Node.js (Winston) and Python (logging)

3. **Custom OpenTelemetry Metrics**
   - 5 business-critical metrics
   - Uses OTel Metrics SDK with OTLP/gRPC exporter
   - Metrics: game plays, wins, bets, latencies
   - Configured to export to Dynatrace OTel collector

### Deployment
- **Helm-based**: Single `helm upgrade` deploys everything
- **Dynatrace integration**: Secrets injected via environment variables
- **OTel Collectors**: Daemonset + StatefulSet architecture
- **Port forwarding**: Gateway on 38080, Frontend on 3000

---

## Quick Demo Script (Word-for-Word)

> **"Hi! I'm going to show you the Vegas Casino app - a complete polyglot microservices demo with full Dynatrace observability.**
>
> **[Open browser to localhost:3000]**
> **This is our casino with 10 services across Node.js, Python, Go, and Java. Let's play some games to generate telemetry.**
>
> **[Run curl commands in terminal]**
> **I'm playing slots and blackjack automatically. Each game creates distributed traces, correlated logs, and custom metrics.**
>
> **[Show logs with trace.id]**
> **Here's the magic: every log entry has a trace.id and span.id for perfect correlation.**
>
> **[Show metrics code]**
> **We've instrumented custom OpenTelemetry metrics: game plays, wins, bet amounts, and latencies.**
>
> **[Open Dynatrace]**
> **All this flows to Dynatrace. Here's our service map... distributed traces... and correlated logs. Everything's connected.**
>
> **That's observability in action! Questions?"**

---

## Backup Commands (If Demo Breaks)

### Check Pod Status
```bash
kubectl get pods -n vegas-casino
kubectl describe pod -n vegas-casino <pod-name>
```

### Restart a Service
```bash
kubectl rollout restart deployment/<service> -n vegas-casino
```

### Check OTel Collector
```bash
kubectl get pods -n default | grep otel
kubectl logs -n default <otel-collector-pod> --tail=50
```

### View Dynatrace Secrets
```bash
source /tmp/dynatrace-secrets.sh
echo $DYNATRACE_TENANT
```

---

## Post-Demo Q&A Prep

**Q: How do you handle span status?**
> A: We use SpanStatusCode.OK/ERROR from OpenTelemetry API, properly set in redis.js and dashboard service.

**Q: What about metrics cardinality?**
> A: We use game type as the primary dimension (slots, blackjack, roulette, dice) - low cardinality, high value.

**Q: How do logs get correlated?**
> A: We extract trace context using OpenTelemetry's `trace.getActiveSpan()` and inject trace.id/span.id into every log entry.

**Q: Can you show the OTel configuration?**
> A: Yes! Check `helm/vegas-casino/templates/*-deployment.yaml` for OTEL_EXPORTER_OTLP_ENDPOINT and OTEL_SERVICE_NAME env vars.

**Q: What if the collector is down?**
> A: OTel SDK has built-in retries and batching. Telemetry queues locally and exports when collector recovers.

---

## Demo Success Metrics
- ✅ All 10 pods running
- ✅ Games playable via UI and API
- ✅ Traces visible in Dynatrace
- ✅ Logs show trace.id correlation
- ✅ Service map displays all dependencies
- ✅ < 2 minutes total demo time

---

**Prepared by:** Copilot Agent
**Date:** 2026-01-28
**Tenant:** vjg01043.live.dynatrace.com
**Cluster:** KIND (Kubernetes in Docker)
