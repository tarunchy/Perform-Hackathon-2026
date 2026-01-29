# Challenge 3 - Verification Guide

## 🎯 How to Verify Your Improved Instrumentation

The rebuild and deployment is in progress. Once complete, follow these steps to verify the enhanced telemetry.

### Step 1: Wait for Pods to be Ready

```bash
# Check pod status
kubectl get pods -n vegas-casino

# Wait for all pods to show 2/2 READY (or 1/1 for services without sidecars)
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=vegas-casino -n vegas-casino --timeout=300s
```

### Step 2: Generate Test Traffic

**Option A: Use the Web UI**
```
Open: https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/
Play some games manually
```

**Option B: Use curl commands**

```bash
# Play Roulette (10 spins)
for i in {1..10}; do
  curl -X POST "https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/roulette/spin" \
    -H "Content-Type: application/json" \
    -d '{"BetAmount": 100, "BetType": "red", "Username": "test_player_'$i'"}'
  echo ""
  sleep 1
done

# Play Blackjack (complete games)
for i in {1..5}; do
  # Deal
  DEAL=$(curl -s -X POST "https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/blackjack/deal" \
    -H "Content-Type: application/json" \
    -d '{"BetAmount": 50, "Username": "blackjack_player_'$i'"}')
  echo "Deal: $DEAL"
  
  # Stand (simple strategy for testing)
  RESULT=$(curl -s -X POST "https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/blackjack/stand" \
    -H "Content-Type: application/json" \
    -d '{"Username": "blackjack_player_'$i'"}')
  echo "Result: $RESULT"
  sleep 2
done

# Play Slots (10 spins)
for i in {1..10}; do
  curl -X POST "https://fluffy-space-barnacle-vw7wgw4j43x5wv-3000.app.github.dev/api/slots/spin" \
    -H "Content-Type: application/json" \
    -d '{"BetAmount": 25, "Username": "slots_player_'$i'"}'
  echo ""
  sleep 1
done
```

### Step 3: Query Dynatrace for Enhanced Telemetry

Wait 30-60 seconds for data to be ingested, then run these queries:

#### Query 1: Verify User Tracking

```dql
fetch spans, from:now() - 15m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter isNotNull(user.name)
| summarize 
    games_played = count(),
    services = collectDistinct(service.name),
    by: {user.name}
| sort games_played desc
```

**Expected**: Should see user names like `test_player_1`, `blackjack_player_1`, `slots_player_1`

#### Query 2: Verify Business Metrics (House Edge & RTP)

```dql
fetch spans, from:now() - 15m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter service.name == "vegas-roulette-service"
| filter isNotNull(`game.house_edge_percent`)
| summarize 
    spins = count(),
    avg_house_edge = avg(`game.house_edge_percent`),
    avg_rtp = avg(`game.actual_rtp_percent`),
    total_bet = sum(`game.total_bet_amount`),
    total_payout = sum(`game.payout`)
```

**Expected**: Should show house edge and RTP calculations

#### Query 3: Verify Span Events

```dql
fetch spans, from:now() - 15m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter isNotNull(events)
| fields timestamp, service.name, span.name, user.name, events
| sort timestamp desc
```

**Expected**: Should see events like `player_won`, `player_bust`, `natural_blackjack`, `slot_win`

#### Query 4: Blackjack Game Details

```dql
fetch spans, from:now() - 15m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter service.name == "vegas-blackjack-service"
| filter span.name == "blackjack_stand"
| fields 
    timestamp,
    user.name,
    `game.player_score`,
    `game.dealer_score`,
    `game.result`,
    `game.payout`,
    `game.net_result`,
    `game.dealer_hit_count`
| sort timestamp desc
```

**Expected**: Detailed blackjack game outcomes with all new attributes

#### Query 5: Slots Symbol Distribution

```dql
fetch spans, from:now() - 15m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter service.name == "vegas-slots-service"
| summarize 
    spins = count(),
    wins = countIf(`game.win` == true),
    avg_multiplier = avg(`game.multiplier`),
    max_multiplier = max(`game.multiplier`),
    by: {`game.win_type`}
| fieldsAdd win_rate = (wins / spins) * 100
| sort avg_multiplier desc
```

**Expected**: Win distribution by type (triple, double, special)

#### Query 6: Player Profitability Analysis

```dql
fetch spans, from:now() - 15m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter isNotNull(user.name)
| filter isNotNull(`game.net_result`)
| summarize 
    games = count(),
    total_wagered = sum(`game.bet_amount` ?? `game.total_bet_amount`),
    total_won = sum(`game.payout`),
    net_profit = sum(`game.net_result`),
    by: {user.name, service.name}
| fieldsAdd roi_percent = (net_profit / total_wagered) * 100
| sort net_profit desc
```

**Expected**: Player profitability by service

### Step 4: Validate All New Attributes Are Present

Run this query to see ALL attributes captured:

```dql
fetch spans, from:now() - 10m
| filter k8s.cluster.uid == "1ae05c83-78f8-4686-9be9-684b17bc3f3b"
| filter service.name in ("vegas-roulette-service", "vegas-blackjack-service", "vegas-slots-service")
| limit 1
```

**Check for these new attributes in the result:**

**Roulette:**
- ✅ user.name
- ✅ game.type
- ✅ game.bet_type  
- ✅ game.total_bet_amount
- ✅ game.bet_count
- ✅ game.house_edge_percent
- ✅ game.actual_rtp_percent
- ✅ game.net_result

**Blackjack:**
- ✅ user.name
- ✅ game.is_blackjack
- ✅ game.is_bust
- ✅ game.player_card_count
- ✅ game.dealer_card_count
- ✅ game.dealer_hit_count
- ✅ game.net_result

**Slots:**
- ✅ user.name
- ✅ game.result_symbol_1/2/3
- ✅ game.net_result
- ✅ game.cheat_boosted

### Step 5: Explore in Dynatrace UI

1. **Go to Distributed Traces**
   - https://vjg01043.apps.dynatrace.com/ui/distributed-tracing
   - Filter by: `k8s.cluster.uid:"1ae05c83-78f8-4686-9be9-684b17bc3f3b"`
   - Click on any trace to see the new attributes

2. **Service Analysis**
   - https://vjg01043.apps.dynatrace.com/ui/services
   - Select one of your services
   - View the new attributes in the request details

3. **Create a Notebook**
   - Use the DQL queries above
   - Create visualizations
   - Share with your team

## ✅ Success Indicators

You've successfully completed Challenge 3 when you can:

1. ✅ **See user.name in spans** - Player tracking works
2. ✅ **See game-specific metrics** - Business KPIs are captured  
3. ✅ **See span events** - Key moments are tracked
4. ✅ **Query by business dimensions** - Can answer business questions
5. ✅ **Calculate ROI and profitability** - Financial insights available

## 🎉 You're Done!

Your OpenTelemetry instrumentation is now world-class! You can:
- Track individual players across games
- Calculate house edge and RTP in real-time
- Identify winning/losing patterns
- Detect anomalies and cheating
- Answer complex business questions

**Next**: Move on to [Challenge 4](CHALLENGE_4_GUIDE.md) to set up Dynatrace best practices!
