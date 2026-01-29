# Copilot Instructions for Vegas Casino Observability

## Context
This is a Vegas Casino microservices application running on Kubernetes cluster with UID: `1ae05c83-78f8-4686-9be9-684b17bc3f3b`

Dynatrace Environment: https://vjg01043.apps.dynatrace.com

## IMPORTANT: Always Filter by My Cluster

When querying observability data (logs, spans, metrics, events) from Dynatrace, **ALWAYS** include this filter:

```
k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
```

## My Services

The Vegas Casino application consists of these services:
- `vegas-frontend-service` - Frontend web application  
- `vegas-gateway-service` - API Gateway
- `vegas-blackjack-service` - Blackjack game service
- `vegas-roulette-service` - Roulette game service
- `vegas-dice-service` - Dice game service
- `vegas-slots-service` - Slots game service
- `vegas-scoring-service` - Scoring and leaderboard service
- `vegas-dashboard-service` - Dashboard service

All services run in the `vegas-casino` namespace.

## Example DQL Queries for My Cluster

### Spans
```dql
fetch spans, from:now() - 2h 
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b" 
| summarize count = count(), by: {service.name, span.kind}
| sort count desc
```

### Logs
```dql
fetch logs, from:now() - 2h 
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| summarize count = count(), by: {k8s.namespace.name, k8s.deployment.name, loglevel}
| sort count desc
```

### Metrics (Example: HTTP request duration)
```dql
timeseries avg(http.server.request.duration), by:{service.name, http.route}
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
```

### Events  
```dql
fetch events, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| fields timestamp, event.type, event.name, dt.event.description
```

### Service Entities
```dql
fetch dt.entity.service
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| fields entity.name, service.namespace, deployment.environment
```

## When I Ask About Observability

1. **Always use my cluster filter** in all DQL queries
2. **Default to 2-4 hour timeframe** for recent data
3. **Prefer spans over logs** for distributed tracing insights
4. **Look for business metrics** like `game.*` attributes
5. **Check for errors** using status_code, error flags

## Agent Behavior Rules

- Never query data without the cluster UID filter
- If data is not found, suggest extending the timeframe (4h, 12h, 24h)
- When analyzing errors, focus on http.status_code, error attributes, and exception traces
- For performance issues, look at span duration and highlight slow operations
- Always show service.name context in results
