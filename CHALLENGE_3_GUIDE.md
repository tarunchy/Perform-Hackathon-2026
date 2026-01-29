# Challenge 3: Improve OpenTelemetry Instrumentation

## Overview

Now that you can query your observability data, it's time to improve your OpenTelemetry instrumentation to capture more valuable business context.

## Current Instrumentation

Your services already have basic OpenTelemetry instrumentation. You can see:
- HTTP requests/responses
- Database calls  
- Service-to-service calls
- Basic game metrics

## Areas to Improve

### 1. Identify Instrumentation Gaps

**Ask Copilot to analyze your code:**
```
@workspace analyze the OpenTelemetry instrumentation in the Vegas Casino services.  
What business metrics are missing that would help troubleshoot issues or  
understand game performance?
```

**Or query Dynatrace for long-running/error spans:**
```dql
fetch spans, from:now() - 2h
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter duration > 1000000000 or isNotNull(error)
| fields service.name, span.name, duration, http.route, http.status_code
| sort duration desc
```

### 2. Add Custom Spans

**Example: Add a custom span for game logic**

Ask Copilot:
```
Add a custom OpenTelemetry span to track the roulette wheel spin logic in  
services/roulette/server.js. Include attributes for:
- bet amount
- bet type  
- spin result
- win/loss
```

### 3. Add Custom Attributes

**Example: Enrich existing spans with business context**

Ask Copilot:
```
Add custom attributes to the blackjack service spans to track:
- player hand value
- dealer hand value
- player decision (hit/stand/double)
- game outcome
```

### 4. Add Baggage for Context Propagation

**Example: Propagate user context across services**

Ask Copilot:
```
Implement OpenTelemetry baggage to propagate user_id and session_id  
across all Vegas Casino services
```

## Example Implementation

### Before:
```javascript
app.post('/spin', async (req, res) => {
  const result = spinWheel();
  res.json(result);
});
```

### After:
```javascript
const { trace } = require('@opentelemetry/api');

app.post('/spin', async (req, res) => {
  const tracer = trace.getTracer('roulette-service');
  
  await tracer.startActiveSpan('roulette.spin', async (span) => {
    try {
      const betAmount = req.body.amount;
      const betType = req.body.type;
      
      // Add custom attributes
      span.setAttribute('game.bet.amount', betAmount);
      span.setAttribute('game.bet.type', betType);
      
      const result = spinWheel();
      
      span.setAttribute('game.result.number', result.number);
      span.setAttribute('game.result.color', result.color);
      span.setAttribute('game.result.win', result.isWin);
      span.setAttribute('game.result.payout', result.payout);
      
      span.setStatus({ code: SpanStatusCode.OK });
      res.json(result);
    } catch (error) {
      span.recordException(error);
      span.setStatus({ code: SpanStatusCode.ERROR });
      throw error;
    } finally {
      span.end();
    }
  });
});
```

## Testing Your Changes

### 1. Rebuild and Redeploy

```bash
# Use the provided script
./rebuild-and-deploy.sh
```

### 2. Generate Traffic

```bash
# Play some games
for i in {1..20}; do
  curl -X POST https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/roulette/spin \
    -H "Content-Type: application/json" \
    -d '{"amount": 100, "type": "red"}'
  sleep 1
done
```

### 3. Verify in Dynatrace

```dql
fetch spans, from:now() - 10m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter service.name == "vegas-roulette-service"
| filter isNotNull(`game.bet.amount`)
| fields timestamp, span.name, `game.bet.amount`, `game.bet.type`, `game.result.win`, `game.result.payout`
| sort timestamp desc
```

## Success Criteria

✅ Identified instrumentation gaps using Copilot or DQL queries  
✅ Added custom spans to track business logic  
✅ Added custom attributes for business metrics  
✅ Redeployed services with improved instrumentation  
✅ Verified new telemetry data in Dynatrace  

## Common Improvements

### Game Services
- Bet details (amount, type, odds)
- Game outcomes (win/loss, payout)
- Player actions (hit, stand, spin, roll)
- RTP (Return to Player) calculations

### Frontend Service  
- Page load times
- User interactions
- Client-side errors

### Gateway Service
- Route timing
- Authentication events
- Rate limiting events

### Scoring Service
- Leaderboard updates
- Score calculations
- Achievement unlocks

---

**Next**: Challenge 4 - Improve Dynatrace Setup
