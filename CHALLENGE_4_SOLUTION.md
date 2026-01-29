# Challenge 4: Improve Dynatrace Setup - COMPLETE GUIDE

## 🎯 Overview

This challenge focuses on implementing Dynatrace best practices for the Vegas Casino application. Due to API token scope limitations, we'll provide both automated scripts (for future use) and manual UI-based approaches.

## ✅ What We Accomplished

### 1. Environment Setup
- ✅ Configured DYNATRACE_CONFIG_API_TOKEN
- ✅ Identified correct API endpoints (*.live.dynatrace.com for config APIs)
- ✅ Created automation scripts for future use

### 2. Scripts Created
- `scripts/create-synthetic-monitors.sh` - Automated synthetic monitor setup
- `scripts/create-dashboard.sh` - Automated dashboard creation

## 📊 Part 1: Synthetic Monitoring (Manual Setup)

### Why Synthetic Monitoring?
- Proactive detection of availability issues
- Performance monitoring from user perspective  
- SLA compliance validation
- Alert before users notice problems

### Manual Setup Steps:

#### Step 1: Access Synthetic Monitoring
1. Go to: https://vjg01043.apps.dynatrace.com/ui/http-monitor
2. Click "Create HTTP monitor"

#### Step 2: Create Frontend Health Monitor
```
Name: Vegas Casino - Frontend Health
URL: https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/
Method: GET
Frequency: Every 5 minutes
Validation: HTTP status code < 400
Performance threshold: 1000ms
Tags: environment:production, application:vegas-casino
```

#### Step 3: Create Roulette API Monitor
```
Name: Vegas Casino - Roulette API
URL: https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/roulette/spin
Method: POST
Body: {"BetAmount": 10, "BetType": "red", "Username": "synthetic_test"}
Frequency: Every 10 minutes
Validation: HTTP status code < 400
Performance threshold: 500ms
Tags: environment:production, application:vegas-casino, service:roulette
```

#### Step 4: Create Slots API Monitor
```
Name: Vegas Casino - Slots API
URL: https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/slots/spin
Method: POST
Body: {"BetAmount": 25, "Username": "synthetic_test"}
Frequency: Every 10 minutes
Validation: HTTP status code < 400
Performance threshold: 500ms
Tags: environment:production, application:vegas-casino, service:slots
```

## 📈 Part 2: Custom Dashboard

### Why Custom Dashboards?
- Unified view of system health
- Business metrics visualization
- Stakeholder communication
- Incident triage acceleration

### Manual Dashboard Creation:

#### Step 1: Create New Dashboard
1. Go to: https://vjg01043.apps.dynatrace.com/ui/dashboards
2. Click "Create dashboard"
3. Name: "🎰 Vegas Casino - Production Overview"

#### Step 2: Add Tiles

**Tile 1: Service Request Count (DQL)**
```dql
fetch spans, from:now()-2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| summarize request_count = count(), by: {service.name}
| sort request_count desc
```
Visualization: Pie Chart

**Tile 2: Average Response Time (DQL)**
```dql
fetch spans, from:now()-2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter span.kind == "server"
| summarize avg_duration_ms = avg(duration)/1000000, by: {service.name}
| sort avg_duration_ms desc
```
Visualization: Bar Chart

**Tile 3: Error Rate (DQL)**
```dql
fetch spans, from:now()-2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| summarize 
    total = count(),
    errors = countIf(http.status_code >= 400),
    by: {service.name}
| fieldsAdd error_rate = (errors / total) * 100
| sort error_rate desc
```
Visualization: Table

**Tile 4: Active Games (DQL)**
```dql
fetch spans, from:now()-15m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter isNotNull(`game.action`)
| summarize games = count(), by: {service.name, `game.action`}
| sort games desc
```
Visualization: Honeycomb

**Tile 5: Win Rate by Game (DQL)**
```dql
fetch spans, from:now()-2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter isNotNull(`game.win`)
| summarize 
    total_games = count(),
    wins = countIf(`game.win` == true),
    total_payout = sum(`game.payout`),
    total_wagered = sum(`game.bet_amount` ?? `game.total_bet_amount`),
    by: {service.name}
| fieldsAdd 
    win_rate = (wins / total_games) * 100,
    house_profit = total_wagered - total_payout
| sort house_profit desc
```
Visualization: Table

**Tile 6: Top Players (DQL)**
```dql
fetch spans, from:now()-2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter isNotNull(user.name)
| summarize 
    games_played = count(),
    total_wagered = sum(`game.bet_amount` ?? `game.total_bet_amount`),
    total_won = sum(`game.payout`),
    by: {user.name}
| fieldsAdd net_result = total_won - total_wagered
| sort games_played desc
| limit 10
```
Visualization: Table

**Tile 7: Pod Health (Metrics)**
- Use Data Explorer
- Metric: `builtin:cloud.kubernetes.workload.pods`
- Filter: `k8s.cluster.uid = 1ae05c83-78f8-4686-9be9-684b17bc3f3b`
- Split by: `k8s.workload.name`
- Visualization: Line Chart

**Tile 8: Info Panel (Markdown)**
```markdown
## 🎰 Vegas Casino Production Dashboard

**Cluster:** 1ae05c83-78f8-4686-9be9-684b17bc3f3b

**Services Monitored:**
- ✅ Vegas Frontend Service
- ✅ Vegas Gateway Service  
- ✅ Vegas Roulette Service
- ✅ Vegas Blackjack Service
- ✅ Vegas Slots Service
- ✅ Vegas Dice Service
- ✅ Vegas Scoring Service

**Key Metrics:** Request Count | Response Time | Error Rate | Win Rate | House Profit
```

## 🎯 Part 3: Service Level Objectives (SLOs)

### Why SLOs?
- Define reliability targets
- Track error budgets
- Data-driven decision making
- Balance innovation vs. stability

### Manual SLO Setup:

#### Step 1: Access SLO Management
1. Go to: https://vjg01043.apps.dynatrace.com/ui/slo

#### Step 2: Create Availability SLO
```
Name: Vegas Casino - Service Availability
Target: 99.9%
Warning: 99.5%
Timeframe: Last 7 days

Query (DQL):
fetch spans, from:now()-7d
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter span.kind == "server"
| summarize 
    total = count(),
    successful = countIf(http.status_code < 400)
| fieldsAdd success_rate = (successful / total) * 100
```

#### Step 3: Create Performance SLO
```
Name: Vegas Casino - Response Time
Target: 95% of requests < 500ms
Warning: 90% of requests < 500ms
Timeframe: Last 7 days

Query (DQL):
fetch spans, from:now()-7d
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter span.kind == "server"
| summarize 
    total = count(),
    fast = countIf(duration < 500000000)
| fieldsAdd performance_rate = (fast / total) * 100
```

## 🔔 Part 4: Alerting & Workflows

### Why Workflows?
- Automated incident response
- Multi-channel notifications  
- Reduce MTTR (Mean Time To Resolution)
- Team collaboration

### Manual Workflow Setup:

#### Step 1: Access Workflows
1. Go to: https://vjg01043.apps.dynatrace.com/ui/workflows

#### Step 2: Create Problem Alert Workflow
```
Name: Vegas Casino - Production Alert
Trigger: Davis Problem
Filter: k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"

Conditions:
- Error rate > 5%
- OR Response time degraded > 50%
- OR Service unavailable

Actions:
1. Send Email
   - To: ops-team@vegascasino.com
   - Subject: "🚨 Vegas Casino Alert: {{problem.title}}"
   - Body: Include problem details, affected services, impact

2. Create Jira Ticket (if integrated)
   - Project: VEGAS
   - Type: Incident
   - Priority: High
   - Description: Auto-populated from problem

3. Post to Slack (if integrated)
   - Channel: #vegas-casino-alerts
   - Message: "@here Production alert: {{problem.title}}"
```

## 🤖 Part 5: Davis AI Analysis

### Configure Davis AI Settings:

#### Step 1: Service Anomaly Detection
1. Go to: Settings > Anomaly Detection > Services
2. Configure sensitivity for:
   - Failure rate increase
   - Response time degradation
   - Traffic drops/spikes

#### Step 2: Custom Events for Business Metrics
Create custom events for:
- Abnormal win rates (> 60% or < 30%)
- High-value transactions (> $1000)
- Unusual betting patterns
- Suspected cheating activity

## ✅ Success Criteria

You've successfully completed Challenge 4 when you have:

### Synthetic Monitoring
- ✅ At least 3 HTTP monitors created
- ✅ Monitors running every 5-10 minutes
- ✅ Performance thresholds configured
- ✅ Proper tagging applied

### Custom Dashboard
- ✅ Dashboard with 6+ tiles created
- ✅ Mix of DQL queries and metrics
- ✅ Business metrics visualized
- ✅ Dashboard shared with team

### SLOs
- ✅ Availability SLO defined (99.9%)
- ✅ Performance SLO defined (95% < 500ms)
- ✅ Error budget tracking enabled

### Alerting
- ✅ At least 1 workflow created
- ✅ Multi-channel notification configured
- ✅ Problem detection rules set

## 📚 Additional Best Practices

### 1. Documentation
- Document all monitors, dashboards, and SLOs
- Create runbooks for common alerts
- Maintain contact lists

### 2. Regular Review
- Weekly dashboard review
- Monthly SLO retrospectives
- Quarterly monitor optimization

### 3. Continuous Improvement
- Adjust thresholds based on data
- Add new monitors for new features
- Retire obsolete monitors

### 4. Team Enablement
- Train team on Dynatrace features
- Share dashboards across organization
- Promote data-driven decisions

## 🎓 Key Learnings

### 1. Proactive vs. Reactive
- Synthetic monitoring catches issues before users
- SLOs provide objective reliability metrics
- Workflows automate response, reducing MTTR

### 2. Visibility Drives Action
- Dashboards make data accessible
- Business metrics align tech with outcomes
- Shared understanding improves collaboration

### 3. Automation Saves Time
- Scripts enable reproducibility
- Workflows eliminate manual steps
- Standard processes reduce errors

## 🚀 Next Steps

### Immediate
1. Generate traffic to populate dashboard
2. Test synthetic monitors
3. Verify SLO calculations

### Short-term (1 week)
1. Tune alert thresholds
2. Add more business metrics
3. Create team-specific dashboards

### Long-term (1 month)
1. Implement advanced workflows
2. Set up cross-team dashboards
3. Establish SLO review cadence

## 🎉 Congratulations!

You've completed all 4 Vegas Casino Hackathon Challenges:

- ✅ **Challenge 1**: Deployed Vegas Casino to Kubernetes
- ✅ **Challenge 2**: Created custom observability agent
- ✅ **Challenge 3**: Enhanced OpenTelemetry instrumentation
- ✅ **Challenge 4**: Implemented Dynatrace best practices

You now have:
- Production-grade observability
- Automated monitoring and alerting
- Business metrics tracking
- Proactive problem detection

**You're ready for production!** 🎰🎲🃏

---

## 📖 Resources

- [Dynatrace Synthetics Docs](https://www.dynatrace.com/support/help/platform-modules/digital-experience/synthetic-monitoring)
- [Dashboard Best Practices](https://www.dynatrace.com/support/help/observe-and-explore/dashboards)
- [SLO Guide](https://www.dynatrace.com/support/help/how-to-use-dynatrace/service-level-objectives)
- [Workflows Documentation](https://www.dynatrace.com/support/help/platform-modules/cloud-automation/workflows)
- [DQL Reference](https://www.dynatrace.com/support/help/observe-and-explore/query-data/dynatrace-query-language)
