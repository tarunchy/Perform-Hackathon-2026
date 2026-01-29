# Challenge 2: Query Your Observability Data

## Your Cluster Details

- **Kubernetes Cluster UID**: `1ae05c83-78f8-4686-9be9-684b17bc3f3b`  
- **Kubernetes Cluster Name**: `hackathon-registration`
- **Dynatrace Environment**: https://vjg01043.apps.dynatrace.com
- **Namespace**: `vegas-casino`

## ✅ Success: Custom Copilot Agent Created!

I've created a custom Copilot instructions file that automatically filters all Dynatrace queries to YOUR cluster:

📁 **File**: [.github/copilot-instructions.md](.github/copilot-instructions.md)

This file instructs GitHub Copilot to:
1. **Always** filter queries by your cluster UID
2. Use appropriate time ranges (2-4 hours by default)
3. Focus on business metrics like `game.*` attributes
4. Provide helpful context about your Vegas Casino services

## How to Use the Custom Agent

### Method 1: Direct Prompts to Copilot

Now you can ask Copilot natural questions and it will automatically filter for your cluster:

**Examples:**
- "Show me all spans from my cluster in the last hour"
- "What errors occurred in my services?"
- "Show me the slowest operations"
- "Give me logs from the vegas-roulette-service"

### Method 2: Using DQL Queries Directly

**Always include this filter in your DQL queries:**
```dql
k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
```

## Example Queries for Your Cluster

### 1. Get All Spans
```dql
fetch spans, from:now() - 2h 
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b" 
| summarize count = count(), by: {service.name, span.kind}
| sort count desc
```

### 2. Get Logs by Service
```dql
fetch logs, from:now() - 2h 
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| summarize count = count(), by: {k8s.deployment.name, loglevel}
| sort count desc
```

### 3. Get HTTP Performance Metrics
```dql
fetch spans, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter span.kind == "server"
| summarize 
    avg_duration_ms = avg(duration)/1000000,
    p95_duration_ms = percentile(duration, 95)/1000000,
    request_count = count(),
    by: {service.name, http.route}
| sort avg_duration_ms desc
```

### 4. Get Error Spans
```dql
fetch spans, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter http.status_code >= 400 or isNotNull(error)
| fields timestamp, service.name, span.name, http.status_code, http.route
| sort timestamp desc
```

### 5. Get Business Metrics (Game Data)
```dql
fetch spans, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter isNotNull(`game.type`)
| summarize 
    total_games = count(),
    wins = countIf(`game.win` == true),
    by: {service.name, `game.type`}
| fieldsAdd win_rate = (wins / total_games) * 100
| sort total_games desc
```

### 6. Get Service Entities
```dql
fetch dt.entity.service
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| fields entity.name, service.namespace, deployment.environment
```

### 7. Get Kubernetes Events
```dql
fetch events, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| fields timestamp, event.type, event.name, dt.event.description
| sort timestamp desc
```

## Verification Steps

1. **Generate Traffic** to your app:
   ```bash
   curl https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/
   ```

2. **Wait 30-60 seconds** for telemetry to be ingested

3. **Query Dynatrace** using the examples above

4. **Verify** you only see data from YOUR cluster (check k8s.cluster.uid matches)

## Your Services

When querying, you should see these services:
- `vegas-frontend-service`
- `vegas-gateway-service`
- `vegas-blackjack-service`
- `vegas-roulette-service`
- `vegas-dice-service`
- `vegas-slots-service`
- `vegas-scoring-service`
- `vegas-dashboard-service`

## Challenge 2 Checklist

✅ Created custom Copilot instructions file  
✅ Identified your cluster UID: `1ae05c83-78f8-4686-9be9-684b17bc3f3b`  
✅ Demonstrated queries filtered to your cluster  
✅ Created reusable query templates  
✅ Documented how to use the custom agent  

## Next Steps

**Challenge 3**: Improve OpenTelemetry Instrumentation  
**Challenge 4**: Improve Dynatrace Setup

---

💡 **Pro Tip**: The `.github/copilot-instructions.md` file is automatically loaded by GitHub Copilot for this workspace. Any prompts you give to Copilot will now automatically understand your cluster context!
