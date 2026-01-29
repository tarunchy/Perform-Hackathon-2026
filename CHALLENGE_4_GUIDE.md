# Challenge 4: Improve Dynatrace Setup

## Overview

Implement Dynatrace best practices including Synthetic Monitoring, Custom Dashboards, SLOs, and Alerting Workflows.

## Prerequisites

⚠️ **IMPORTANT**: Challenge 4 requires a **Configuration API Token**

The token should be available as: `DYNATRACE_CONFIG_API_TOKEN`

Check if it's set:
```bash
printenv | grep DYNATRACE_CONFIG_API_TOKEN
```

## Part 1: Synthetic Monitoring

### Create a Browser Monitor

**Ask Copilot:**
```
Using the Dynatrace Synthetics API, create a browser monitor that:
1. Navigates to https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/
2. Clicks on the Roulette game
3. Places a bet
4. Validates the game responds successfully
5. Runs every 15 minutes from 3 global locations
```

### Create HTTP Monitors

**Ask Copilot:**
```
Create HTTP synthetic monitors for these Vegas Casino endpoints:
- GET  https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/health
- POST https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/roulette/spin
- GET  https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/leaderboard

Set SLA threshold to 500ms response time.
```

### Example API Call (Reference)

```bash
curl -X POST "https://vjg01043.apps.dynatrace.com/api/v1/synthetic/monitors" \
  -H "Authorization: Api-Token ${DYNATRACE_CONFIG_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "HTTP",
    "name": "Vegas Casino Health Check",
    "enabled": true,
    "locations": ["GEOLOCATION-1", "GEOLOCATION-2"],
    "frequencyMin": 15,
    "script": {
      "requests": [{
        "url": "https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/health",
        "method": "GET",
        "validation": {
          "rules": [{
            "type": "httpStatusesList",
            "passIfFound": false,
            "value": ">=400"
          }]
        }
      }]
    }
  }'
```

## Part 2: Custom Dashboard

### Create a Vegas Casino Dashboard

**Ask Copilot:**
```
Create a Dynatrace dashboard for Vegas Casino with these tiles:
1. Total requests per service (last 2 hours)
2. Average response time by service
3. Error rate percentage
4. Top 10 slowest operations  
5. Active games by type (slots, roulette, blackjack, dice)
6. Win rate percentage by game
7. Total payouts
8. Current players (active sessions)

Use DQL queries filtered by cluster UID: 1ae05c83-78f8-4686-9be9-684b17bc3f3b
```

### Example Dashboard Definition

```json
{
  "dashboardMetadata": {
    "name": "Vegas Casino - Production",
    "shared": true,
    "owner": "your-email@example.com"
  },
  "tiles": [
    {
      "name": "Requests by Service",
      "tileType": "DATA_EXPLORER",
      "configured": true,
      "query": "fetch spans, from:now()-2h | filter k8s.cluster.uid == '1ae05c83-78f8-4686-9be9-684b17bc3f3b' | summarize count(), by:{service.name}",
      "visualizationConfig": {
        "type": "PIE_CHART"
      }
    }
  ]
}
```

## Part 3: SLOs (Service Level Objectives)

### Define SLOs for Vegas Casino

**Ask Copilot:**
```
Create Dynatrace SLOs for:
1. Availability: 99.9% of requests return 2xx/3xx status codes
2. Performance: 95% of requests complete in < 500ms
3. Error Budget: Allow 0.1% errors per week

Target entities: All services in k8s.cluster.uid = 1ae05c83-78f8-4686-9be9-684b17bc3f3b
```

### Example SLO Definition

```json
{
  "name": "Vegas Casino - Availability SLO",
  "evaluationType": "AGGREGATE",
  "filter": "k8s.cluster.uid == '1ae05c83-78f8-4686-9be9-684b17bc3f3b'",
  "targetSuccess": 99.9,
  "targetWarning": 99.5,
  "errorBudgetBurnRate": {
    "enabled": true,
    "fastBurnThreshold": 10
  }
}
```

## Part 4: Alerting & Workflows

### Create Problem Detection Workflow

**Ask Copilot:**
```
Create a Dynatrace Workflow that triggers when:
- Any service in cluster 1ae05c83-78f8-4686-9be9-684b17bc3f3b has error rate > 5%
- OR response time degrades by > 50%

The workflow should:
1. Send a Slack notification to #vegas-casino-alerts
2. Create a GitHub issue in this repository
3. Send an email to ops-team@vegascasino.com

Include problem details: service name, error rate, affected users
```

### Example Workflow Definition

```yaml
workflowId: "vegas-casino-alerting"
title: "Vegas Casino - Production Alerts"
trigger:
  eventType: "DAVIS_PROBLEM"
  filterQuery: "k8s.cluster.uid == '1ae05c83-78f8-4686-9be9-684b17bc3f3b' AND (errorRate > 5 OR responseTimeDegradation > 0.5)"
tasks:
  - name: "Send Slack Notification"
    action: "dynatrace.slack:post-message"
    input:
      channel: "#vegas-casino-alerts"
      message: "🚨 Problem detected: {{event.title}}"
  
  - name: "Create GitHub Issue"
    action: "dynatrace.github:create-issue"
    input:
      repository: "dynatrace-oss/Perform-Hackathon-2026"
      title: "Production Alert: {{event.title}}"
      body: "Problem ID: {{event.id}}"
  
  - name: "Send Email"
    action: "dynatrace.email:send"
    input:
      to: "ops-team@vegascasino.com"
      subject: "Vegas Casino Alert"
      body: "{{event.details}}"
```

## Part 5: Create Best Practices Agent

**Ask Copilot:**
```
Create a custom Copilot agent named "Dynatrace Best Practices Agent" that can:
1. Audit my current Dynatrace configuration
2. Suggest missing synthetic monitors
3. Recommend dashboard improvements
4. Identify services without SLOs
5. Check for missing alerting workflows

The agent should be aware of my cluster: 1ae05c83-78f8-4686-9be9-684b17bc3f3b
```

Save this as: `.github/dynatrace-agent-instructions.md`

## Verification & Testing

### 1. Verify Synthetic Monitors

```bash
# List all synthetic monitors
curl -X GET "https://vjg01043.apps.dynatrace.com/api/v1/synthetic/monitors" \
  -H "Authorization: Api-Token ${DYNATRACE_CONFIG_API_TOKEN}"
```

### 2. Test Workflow

```bash
# Trigger an error to test alerting
kubectl delete pod -n vegas-casino -l app.kubernetes.io/component=roulette
```

### 3. Check Dashboard

Visit: https://vjg01043.apps.dynatrace.com/ui/dashboards

### 4. Verify SLOs

Visit: https://vjg01043.apps.dynatrace.com/ui/slo

## Success Criteria

✅ Created at least 1 synthetic monitor  
✅ Built a custom dashboard with 5+ tiles  
✅ Defined at least 1 SLO  
✅ Created a problem notification workflow  
✅ Documented best practices in a custom agent  

## Common Dynatrace APIs

### Synthetics API
- `POST /api/v1/synthetic/monitors` - Create monitor
- `GET /api/v1/synthetic/monitors` - List monitors
- `GET /api/v1/synthetic/monitors/{id}/results` - Get results

### Dashboards API (v2)
- `POST /api/config/v1/dashboards` - Create dashboard
- `GET /api/config/v1/dashboards` - List dashboards

### SLO API
- `POST /api/v2/slo` - Create SLO
- `GET /api/v2/slo` - List SLOs

### Workflows API
- `POST /platform/automation/v1/workflows` - Create workflow
- `GET /platform/automation/v1/workflows` - List workflows

## Additional Resources

- [Dynatrace Synthetics Docs](https://www.dynatrace.com/support/help/platform-modules/digital-experience/synthetic-monitoring)
- [Dashboard API Docs](https://www.dynatrace.com/support/help/dynatrace-api/configuration-api/dashboards-api)
- [SLO Docs](https://www.dynatrace.com/support/help/how-to-use-dynatrace/service-level-objectives)
- [Workflows Docs](https://www.dynatrace.com/support/help/platform-modules/cloud-automation/workflows)

---

**Congratulations!** You've completed all 4 challenges! 🎉
