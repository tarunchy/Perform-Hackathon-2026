# Vegas Casino Hackathon - Complete Guide

## Your Environment

| Property | Value |
|----------|-------|
| **Kubernetes Cluster UID** | `1ae05c83-78f8-4686-9be9-684b17bc3f3b` |
| **Kubernetes Cluster Name** | `hackathon-registration` |
| **Dynatrace Environment** | https://vjg01043.apps.dynatrace.com |
| **Application URL** | https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/ |
| **Namespace** | `vegas-casino` |

## Challenge Status

| Challenge | Status | Guide |
|-----------|--------|-------|
| **Challenge 1** | ✅ Complete | Validated metrics flowing to Dynatrace |
| **Challenge 2** | ✅ Complete | [CHALLENGE_2_SOLUTION.md](CHALLENGE_2_SOLUTION.md) |
| **Challenge 3** | 📝 In Progress | [CHALLENGE_3_GUIDE.md](CHALLENGE_3_GUIDE.md) |
| **Challenge 4** | 📝 Todo | [CHALLENGE_4_GUIDE.md](CHALLENGE_4_GUIDE.md) |

## Quick Start

### Generate Traffic

```bash
# Frontend
curl https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/

# Play Roulette
curl -X POST https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/roulette/spin \
  -H "Content-Type: application/json" \
  -d '{"amount": 100, "type": "red"}'
```

### Query Your Data

**Always filter by your cluster UID:**
```dql
k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
```

## Essential DQL Queries

### 1. Service Overview
```dql
fetch spans, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| summarize 
    requests = count(),
    avg_duration_ms = avg(duration)/1000000,
    error_count = countIf(http.status_code >= 400),
    by: {service.name}
| fieldsAdd error_rate = (error_count / requests) * 100
| sort requests desc
```

### 2. Recent Errors
```dql
fetch spans, from:now() - 1h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter http.status_code >= 400 or isNotNull(error)
| fields timestamp, service.name, http.route, http.status_code, span.name
| sort timestamp desc
| limit 20
```

### 3. Game Analytics
```dql
fetch spans, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter isNotNull(`game.type`)
| summarize 
    games_played = count(),
    total_wins = countIf(`game.win` == true),
    avg_payout = avg(`game.payout`),
    by: {service.name, `game.type`}
| fieldsAdd win_rate = (total_wins / games_played) * 100
| sort games_played desc
```

### 4. Performance Bottlenecks
```dql
fetch spans, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| summarize 
    p50 = percentile(duration, 50)/1000000,
    p95 = percentile(duration, 95)/1000000,
    p99 = percentile(duration, 99)/1000000,
    max = max(duration)/1000000,
    by: {service.name, span.name}
| filter p95 > 100  // Spans slower than 100ms at p95
| sort p95 desc
```

## Your Services

```
vegas-casino/
├── vegas-frontend-service      (Port 3000) - Web UI
├── vegas-gateway-service       (Port 8080) - API Gateway
├── vegas-blackjack-service     (Port 8084) - Blackjack game
├── vegas-roulette-service      (Port 8082) - Roulette game
├── vegas-dice-service          (Port 8083) - Dice game
├── vegas-slots-service         (Port 8081) - Slots game
├── vegas-scoring-service       (Port 8085) - Leaderboard
└── vegas-dashboard-service     (Port 3001) - Analytics
```

## Useful Commands

### Kubernetes

```bash
# Check pods
kubectl get pods -n vegas-casino

# Check logs
kubectl logs -n vegas-casino -l app.kubernetes.io/component=roulette --tail=50

# Restart a service
kubectl rollout restart deployment vegas-casino-roulette -n vegas-casino

# Check OTEL collectors
kubectl get pods -n default | grep otel
kubectl logs -n default otel-collector-statefulset-0 --tail=30
```

### Development

```bash
# Rebuild and redeploy all services
./rebuild-and-deploy.sh

# Validate metrics are flowing
./validate-metrics.sh

# Build and load into KIND
./build-and-load-kind.sh
```

### Environment Variables

```bash
# Check Dynatrace config
printenv | grep DYNATRACE
printenv | grep DT_

# Your cluster UID
kubectl get namespace kube-system -o jsonpath='{.metadata.uid}'
```

## GitHub Copilot Integration

### Custom Agent Files

1. **[.github/copilot-instructions.md](.github/copilot-instructions.md)**
   - Automatic cluster filtering
   - Vegas Casino service context
   - DQL query templates

2. **Future**: `.github/dynatrace-agent-instructions.md` (Challenge 4)
   - Dynatrace best practices
   - Configuration auditing
   - Automated recommendations

### Using Copilot

Copilot now automatically knows about your cluster! Just ask:

```
"Show me errors in my services"
"What's the slowest operation in my cluster?"
"Give me game statistics from the last hour"
"Show me all roulette service spans"
```

## Troubleshooting

### No Data in Dynatrace?

1. Check OTEL collector is running:
   ```bash
   kubectl get pods -n default | grep otel
   ```

2. Check collector logs for errors:
   ```bash
   kubectl logs -n default otel-collector-statefulset-0 --tail=50
   ```

3. Verify secret configuration:
   ```bash
   kubectl get secret dynatrace -n default -o jsonpath='{.data.dynatrace_oltp_url}' | base64 -d
   ```

4. Generate traffic and wait 30-60 seconds

### Services Not Starting?

1. Check pod status:
   ```bash
   kubectl get pods -n vegas-casino
   ```

2. Describe problem pods:
   ```bash
   kubectl describe pod <pod-name> -n vegas-casino
   ```

3. Check logs:
   ```bash
   kubectl logs <pod-name> -n vegas-casino
   ```

### Build Failures?

1. Check Docker is running:
   ```bash
   docker ps
   ```

2. Rebuild individual service:
   ```bash
   cd services/roulette
   docker build -t vegas-roulette:latest .
   kind load docker-image vegas-roulette:latest
   ```

## Next Steps

1. ✅ **Challenge 2 Complete** - You can now query your observability data!

2. 📝 **Challenge 3 Next** - Improve OpenTelemetry instrumentation
   - Add custom spans for game logic
   - Enrich spans with business metrics
   - Implement baggage for context propagation
   - See: [CHALLENGE_3_GUIDE.md](CHALLENGE_3_GUIDE.md)

3. 📝 **Challenge 4 Later** - Improve Dynatrace setup
   - Create synthetic monitors
   - Build custom dashboards
   - Define SLOs
   - Set up alerting workflows
   - See: [CHALLENGE_4_GUIDE.md](CHALLENGE_4_GUIDE.md)

## Resources

- **Dynatrace**: https://vjg01043.apps.dynatrace.com
- **Application**: https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/
- **OpenTelemetry Docs**: https://opentelemetry.io/docs/
- **Dynatrace API**: https://www.dynatrace.com/support/help/dynatrace-api

## Challenge Files

- [Challenges/1.md](Challenges/1.md) - Ingest data into Dynatrace
- [Challenges/2.md](Challenges/2.md) - Prompt your observability data  
- [Challenges/3.md](Challenges/3.md) - Improve OpenTelemetry instrumentation
- [Challenges/4.md](Challenges/4.md) - Improve Dynatrace setup

---

**Happy Hacking!** 🎰🎲🎯
