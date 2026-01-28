# Dynatrace Perform 2026 Hackathon – OTel Upgrade Plan

This file is a single-stop plan + snippets for improving OpenTelemetry tracing/metrics/log correlation (and optional Dynatrace configs) in the Vegas Casino app.

## Quickstart checklist
- [ ] Confirm OTEL exporter endpoint is set for all services: `OTEL_EXPORTER_OTLP_ENDPOINT` and `OTEL_EXPORTER_OTLP_INSECURE=true`.
- [ ] Ensure service names are consistent across languages (see "Service naming" below).
- [ ] Add trace/log correlation fields to `services/common/logger.js` and `services/common/logger.py`.
- [ ] Add OTel metrics (counters/histograms) in Node + Go + Python + Java (snippets below).
- [ ] Add context propagation to gateway proxy + frontend-to-scoring fetch.
- [ ] Run k6 + Playwright tests to generate traces/metrics/logs.
- [ ] Build two Dynatrace dashboards + SLOs + Guardian (templates below).

---

## 1) Architecture summary (request flow)

**Browser → Frontend → Game Services → Scoring → Storage**
- Browser loads static UI from **frontend service** and calls `/api/...` endpoints on frontend.
- **Frontend** uses **gRPC** to game services (slots, roulette, dice, blackjack) and dashboard service.
- Game services call **scoring service** (HTTP) to record results and scores.
- **Scoring service** writes to **Postgres**; game services use **Redis** for state.
- **Gateway** exists as an alternative HTTP entry point that proxies to game services (HTTP), and logs BizEvents.

Primary flow used by the UI in this repo:
- Browser → `frontend-service` HTTP → gRPC → game services → HTTP → `scoring-service` → Postgres

Secondary flow (gateway path):
- Browser or test client → `gateway-service` HTTP → HTTP → game services → scoring → Postgres

---

## 2) Where OpenTelemetry is configured today (and gaps)

| Service | OTel setup location | What’s working | Missing / gaps |
| --- | --- | --- | --- |
| gateway (Node) | `services/gateway/gateway-service.js`, `services/common/opentelemetry.js` | SDK init, auto-instrumentation, manual spans | No context propagation to downstream HTTP (`callChildJson`, `proxyJson`), duplicate HTTP spans, no metrics, logs not correlated |
| frontend (Node) | `services/frontend/frontend-service.js`, `services/common/opentelemetry.js` | SDK init, HTTP context extraction, gRPC metadata injection | No metrics, logs not correlated, fetch to scoring lacks propagation |
| slots (Node, gRPC+HTTP) | `services/slots/index.js`, `services/slots/slots-service-grpc.js`, `services/common/service-runner.js` | SDK init, gRPC metadata extraction, manual spans | No metrics, limited span status/error handling, no log correlation |
| blackjack (Node) | `services/blackjack/index.js`, `services/blackjack/blackjack-service.js` | SDK init, manual spans | No metrics, limited span status/error handling, no log correlation |
| roulette (Node) | `services/roulette/roulette-service.js`, `services/common/opentelemetry.js` | SDK init, feature flag attributes, scoring call | No metrics, limited error status, no log correlation |
| roulette (Python) | `services/roulette/python/opentelemetry_setup.py` | SDK init, manual spans | No metrics, no log correlation, limited span status |
| dice (Go) | `services/dice/go/opentelemetry.go`, `services/dice/go/dice-service.go`, `services/dice/go/dice-service-grpc.go` | SDK init, middleware spans, gRPC context extraction | No metrics, limited error status, logs not correlated |
| dashboard (Node) | `services/dashboard/dashboard-service.js`, `services/dashboard/dashboard-service-grpc.js` | SDK init, gRPC context extraction | No metrics, no log correlation |
| scoring (Java Spring) | `services/scoring/src/main/java/.../OpenTelemetryConfig.java`, `ScoringController.java`, `ScoringService.java` | SDK init, manual spans, context extraction | No metrics, logs not correlated (MDC), span attributes inconsistent |
| common libs | `services/common/opentelemetry.js`, `services/common/redis.js`, `services/common/scoring.js`, `services/common/openfeature.js` | Trace propagation + spans for Redis + scoring HTTP | No metrics, limited span status in some call sites |

---

## 3) Prioritized improvement plan

### First 60 minutes (highest ROI)
1) **End-to-end trace propagation**
   - Add `propagation.inject` in gateway HTTP proxy (`callChildJson`, `proxyJson`).
   - Add `propagation.inject` for frontend → scoring fetch.
2) **Log correlation**
   - Add trace_id/span_id fields in `services/common/logger.js` and `services/common/logger.py`.
3) **Span naming + boundary consistency**
   - Replace ad-hoc span names with `game.play`, `game.bet`, `game.outcome`, `scoring.update`, `redis.get`, `db.write`.
   - Avoid double HTTP spans in gateway by enriching active span instead of creating a new root span.
4) **Add core game attributes**
   - `game.type`, `game.action`, `bet.amount`, `outcome`, `player.id`, `session.id`, `feature_flag.variant`.

### Next 2 hours
5) **Metrics**: Add counters/histograms for gameplay, bets, latency, scoring latency, Redis/db calls.
6) **Java scoring metrics**: add `Meter` and record for DB and scoring operations.
7) **Go dice metrics**: add OTel metrics provider + counters/histograms.
8) **Python roulette metrics**: add OTel metrics provider + counters/histograms.
9) **Resource consistency**: normalize service names across all services via env vars/Helm.
10) **Dashboards + SLOs + Guardian**: build the “wow factor” views.

---

## 4) Top 10 highest-ROI instrumentation improvements (with files)

1) **Gateway HTTP propagation**
   - `services/gateway/gateway-service.js` (`proxyJson`, `callChildJson`)
   - Why: preserves trace across gateway → game services
2) **Frontend → Scoring propagation**
   - `services/frontend/frontend-service.js` (leaderboard/dashboard fetches)
   - Why: end-to-end scoring traces
3) **Central logger trace correlation**
   - `services/common/logger.js`, `services/common/logger.py`
   - Why: logs link to traces in Dynatrace
4) **Common metrics module (Node)**
   - `services/common/opentelemetry.js` + new `services/common/metrics.js`
   - Why: add counters/histograms once, reuse everywhere
5) **Game span boundaries**
   - `services/frontend/frontend-service.js` (game.start → game.outcome)
   - `services/slots/slots-service-grpc.js`, `services/roulette/roulette-service.js`, `services/blackjack/blackjack-service.js`, `services/dice/go/dice-service.go`
   - Why: consistent high-level game spans
6) **Error status + exceptions**
   - Same files as above
   - Why: error visibility + SLOs
7) **Feature flag attributes**
   - `services/common/openfeature.js` + call sites
   - Why: feature flag variant impact dashboards
8) **Redis and DB metrics**
   - `services/common/redis.js` (Node)
   - `services/dice/go/redis.go` (Go)
   - `services/scoring/.../ScoringService.java` (Java)
9) **Scoring latency metric**
   - `services/common/scoring.js` (Node)
   - Why: show scoring performance and failures
10) **Resource naming consistency**
   - Helm: `helm/vegas-casino/values.yaml` and templates
   - Why: clean topology and filters

---

## 5) File-by-file change list (what to edit and why)

- `services/gateway/gateway-service.js`
  - Inject trace context into downstream HTTP calls.
  - Use active span instead of creating a new root span for each request.
- `services/frontend/frontend-service.js`
  - Inject context into fetch calls to scoring service.
  - Add game boundary spans: `game.play`, `game.outcome`.
- `services/common/logger.js`
  - Add `trace_id` + `span_id` to every log entry.
- `services/common/logger.py`
  - Add `trace_id` + `span_id` to every log entry.
- `services/common/opentelemetry.js`
  - Add metrics exporter + MeterProvider (Node).
- `services/common/metrics.js` (new)
  - Central counters/histograms: game_plays_total, game_wins_total, bet_amount, game_latency, scoring_latency, redis_calls, db_calls.
- `services/common/scoring.js`
  - Add span around HTTP call + scoring_latency histogram + errors.
- `services/common/redis.js`
  - Add `redis_calls` counter + `redis_latency` histogram.
- `services/slots/slots-service-grpc.js`
  - Add consistent span attributes and metrics on Spin.
- `services/roulette/roulette-service.js`
  - Add `game.type`, `bet.amount`, `outcome`, feature flags, errors.
- `services/blackjack/blackjack-service.js`
  - Add `game.result`, `bet.amount`, status/error handling.
- `services/dice/go/dice-service.go` and `services/dice/go/opentelemetry.go`
  - Add OTel metrics provider and counters/histograms.
- `services/roulette/python/opentelemetry_setup.py` + `roulette_service.py`
  - Add meter provider, metrics, and log correlation.
- `services/scoring/src/main/java/.../OpenTelemetryConfig.java`
  - Add OTel metrics exporter (OTLP).
- `services/scoring/src/main/java/.../ScoringService.java`
  - Add metrics and status for DB calls.
- `helm/vegas-casino/values.yaml` + templates
  - Ensure `OTEL_SERVICE_NAME` and `OTEL_RESOURCE_ATTRIBUTES` set for each deployment.

---

## 6) Copy/paste code snippets (minimal, high impact)

### 6.1 Node: log correlation (common logger)

`services/common/logger.js`
```js
const { trace } = require('@opentelemetry/api');

  formatLog(level, category, event, data = {}) {
    const span = trace.getActiveSpan();
    const spanContext = span ? span.spanContext() : null;

    return JSON.stringify({
      timestamp: new Date().toISOString(),
      service: this.serviceName,
      level: level.toUpperCase(),
      category: category,
      event: event,
      trace_id: spanContext ? spanContext.traceId : undefined,
      span_id: spanContext ? spanContext.spanId : undefined,
      ...data
    });
  }
```

### 6.2 Python: log correlation

`services/common/logger.py`
```py
from opentelemetry import trace

    def format_log(self, level, category, event, data=None):
        if data is None:
            data = {}

        span = trace.get_current_span()
        span_ctx = span.get_span_context() if span else None

        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "level": level.upper(),
            "category": category,
            "event": event,
            "trace_id": format(span_ctx.trace_id, "032x") if span_ctx else None,
            "span_id": format(span_ctx.span_id, "016x") if span_ctx else None,
            **data
        }
        return json.dumps(log_entry)
```

### 6.3 Gateway: propagate context to downstream HTTP

`services/gateway/gateway-service.js`
```js
const { context, propagation, trace } = require('@opentelemetry/api');

function proxyJson(targetPort, req, res) {
  const headers = { 'Content-Type': 'application/json' };
  propagation.inject(context.active(), headers);

  const options = {
    hostname: hostname,
    port: targetPort,
    path: req.url.replace(/^\/api\/(slots|roulette|dice|blackjack)/, ''),
    method: req.method,
    headers
  };
  // ... rest unchanged
}

function callChildJson(targetPort, pathName, payload) {
  return new Promise((resolve, reject) => {
    const headers = { 'Content-Type': 'application/json' };
    propagation.inject(context.active(), headers);

    const options = { hostname, port: targetPort, path: pathName, method: 'POST', headers };
    // ... rest unchanged
  });
}
```

### 6.4 Frontend: propagate context to scoring fetch

`services/frontend/frontend-service.js`
```js
const { context, propagation } = require('@opentelemetry/api');

function injectHeaders() {
  const headers = {};
  propagation.inject(context.active(), headers);
  return headers;
}

const response = await fetch(`${scoringServiceUrl}/api/scoring/leaderboard/${game}?limit=${limit}`, {
  headers: { ...injectHeaders() }
});
```

### 6.5 Node metrics: central metrics module

`services/common/metrics.js` (new)
```js
const { metrics } = require('@opentelemetry/api');

const meter = metrics.getMeter('vegas-casino');

const gamePlaysTotal = meter.createCounter('game_plays_total');
const gameWinsTotal = meter.createCounter('game_wins_total');
const betAmount = meter.createHistogram('bet_amount', { unit: 'USD' });
const gameLatency = meter.createHistogram('game_latency', { unit: 'ms' });
const scoringLatency = meter.createHistogram('scoring_latency', { unit: 'ms' });
const redisCalls = meter.createCounter('redis_calls');
const dbCalls = meter.createCounter('db_calls');

module.exports = {
  meter,
  gamePlaysTotal,
  gameWinsTotal,
  betAmount,
  gameLatency,
  scoringLatency,
  redisCalls,
  dbCalls,
};
```

### 6.6 Node metrics export (OTLP)

`services/common/opentelemetry.js`
```js
const { MeterProvider, PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-grpc');

// inside initializeTelemetry()
const metricExporter = endpoint ? new OTLPMetricExporter({ url: endpoint }) : undefined;
const metricReader = metricExporter ? new PeriodicExportingMetricReader({ exporter: metricExporter }) : undefined;

const sdk = new NodeSDK({
  resource,
  traceExporter: ...,
  metricReader,
  instrumentations: [...]
});
```

### 6.7 Add span status + metrics in a game handler (example: slots)

`services/slots/slots-service-grpc.js`
```js
const { gamePlaysTotal, gameWinsTotal, betAmount, gameLatency } = require('./common/metrics');

const start = Date.now();
const span = tracer.startSpan('game.play', { attributes: { 'game.type': 'slots', 'game.action': 'spin' } });

try {
  // ... game logic
  span.setAttributes({ 'bet.amount': betAmountValue, 'outcome': win ? 'win' : 'lose' });
  gamePlaysTotal.add(1, { 'game.type': 'slots' });
  if (win) gameWinsTotal.add(1, { 'game.type': 'slots' });
  betAmount.record(betAmountValue, { 'game.type': 'slots' });
  gameLatency.record(Date.now() - start, { 'game.type': 'slots' });
  span.setStatus({ code: 1 });
} catch (err) {
  span.recordException(err);
  span.setStatus({ code: 2, message: err.message });
  throw err;
} finally {
  span.end();
}
```

### 6.8 Scoring HTTP call spans + metrics

`services/common/scoring.js`
```js
const { trace } = require('@opentelemetry/api');
const { scoringLatency } = require('./metrics');

async function recordGameResult(gameResult) {
  const tracer = trace.getTracer('scoring-client');
  const start = Date.now();
  const span = tracer.startSpan('scoring.record_game_result', {
    attributes: { 'game.type': gameResult.game, 'bet.amount': gameResult.betAmount }
  });

  try {
    const response = await makeHttpRequest(url, { method: 'POST' }, payloadStr);
    span.setStatus({ code: 1 });
    return true;
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: 2, message: error.message });
    return false;
  } finally {
    scoringLatency.record(Date.now() - start, { 'game.type': gameResult.game });
    span.end();
  }
}
```

### 6.9 Go metrics (dice)

`services/dice/go/opentelemetry.go`
```go
import (
  "go.opentelemetry.io/otel/sdk/metric"
  "go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
)

// inside initTelemetry
metricExporter, _ := otlpmetricgrpc.New(context.Background(), otlpmetricgrpc.WithInsecure())
mp := metric.NewMeterProvider(metric.WithReader(metric.NewPeriodicReader(metricExporter)))
otel.SetMeterProvider(mp)
```

`services/dice/go/dice-service.go`
```go
meter := otel.Meter("vegas-dice-service")
plays, _ := meter.Int64Counter("game_plays_total")
wins, _ := meter.Int64Counter("game_wins_total")
latency, _ := meter.Float64Histogram("game_latency")

start := time.Now()
plays.Add(ctx, 1, attribute.String("game.type", "dice"))
if win { wins.Add(ctx, 1, attribute.String("game.type", "dice")) }
latency.Record(ctx, float64(time.Since(start).Milliseconds()), attribute.String("game.type", "dice"))
```

### 6.10 Java scoring metrics + log correlation (MDC)

`services/scoring/src/main/java/.../OpenTelemetryConfig.java`
```java
import io.opentelemetry.sdk.metrics.SdkMeterProvider;
import io.opentelemetry.sdk.metrics.export.PeriodicMetricReader;
import io.opentelemetry.exporter.otlp.metrics.OtlpGrpcMetricExporter;

SdkMeterProvider meterProvider = SdkMeterProvider.builder()
  .registerMetricReader(PeriodicMetricReader.builder(
    OtlpGrpcMetricExporter.builder().setEndpoint(endpoint).build()
  ).build())
  .setResource(resource)
  .build();

OpenTelemetrySdk sdk = OpenTelemetrySdk.builder()
  .setTracerProvider(sdkTracerProvider)
  .setMeterProvider(meterProvider)
  .setPropagators(ContextPropagators.create(W3CTraceContextPropagator.getInstance()))
  .build();
```

`services/scoring/src/main/java/.../ScoringService.java`
```java
var meter = openTelemetry.getMeter("vegas-scoring-service");
var dbCalls = meter.counterBuilder("db_calls").build();
var scoringLatency = meter.histogramBuilder("scoring_latency").ofLongs().build();

long start = System.currentTimeMillis();
try { ... } finally {
  dbCalls.add(1, Attributes.of(AttributeKey.stringKey("db.system"), "postgresql"));
  scoringLatency.record(System.currentTimeMillis() - start);
}
```

`logback.xml` or a simple filter (MDC example):
```java
import io.opentelemetry.api.trace.Span;
import org.slf4j.MDC;

Span span = Span.current();
var sc = span.getSpanContext();
if (sc.isValid()) {
  MDC.put("trace_id", sc.getTraceId());
  MDC.put("span_id", sc.getSpanId());
}
```

---

## 7) Metrics to add (canonical names)

- `game_plays_total` (counter)
- `game_wins_total` (counter)
- `bet_amount` (histogram, unit=USD)
- `game_latency` (histogram, unit=ms)
- `scoring_latency` (histogram, unit=ms)
- `redis_calls` (counter)
- `db_calls` (counter)

Recommended attributes (tags):
- `game.type`, `game.action`, `outcome`, `feature_flag.variant`, `service.name`, `error`

---

## 8) Service naming consistency

Normalize service names via env vars (Helm or K8s manifests):
- `vegas-frontend-service`
- `vegas-casino-gateway`
- `vegas-slots-service`
- `vegas-roulette-service`
- `vegas-dice-service`
- `vegas-blackjack-service`
- `vegas-dashboard-service`
- `vegas-scoring-service`

Set:
- `OTEL_SERVICE_NAME=<service>`
- `SERVICE_NAME=<service>` (for services that use SERVICE_NAME)
- `OTEL_RESOURCE_ATTRIBUTES=service.namespace=vegas-casino,deployment.environment=production`

---

## 9) Dynatrace “wow factor” ideas

### Dashboard A: Dev/SRE View
- **Service map** (Smartscape) filtered to `vegas-casino` namespace
- **RED metrics**: p95 latency, error rate, request rate per service
- **Top failing traces** (errors by service)
- **DB/Redis call rates + latency**
- **gRPC vs HTTP split** (frontend → game services)

### Dashboard B: Casino Manager View
- **Plays per game** (game_plays_total by game.type)
- **Win rate** (game_wins_total / game_plays_total)
- **Revenue proxy** (sum bet_amount - sum payouts)
- **Feature flag impact** (wins/latency by feature_flag.variant)
- **Top players / biggest wins** from scoring data

### Suggested SLOs
1) **Gameplay Availability**
   - SLO: 99.5% of game requests succeed
   - Signal: error rate from traces or `http.status_code >= 500`
2) **Scoring Latency**
   - SLO: 95% of scoring writes < 300ms
   - Signal: `scoring_latency` histogram p95

### Site Reliability Guardian concept
**“Casino Shift Guardian”**
- Checks: game error rate, scoring latency, Redis/DB saturation, and flagd errors
- Recommends: scale up specific game service, rollback a flag variant, or isolate a noisy game

---

## 10) Test plan

### k6 (load generation)
- Use doc: `docs/testing/k6.md`
- Example local run:
```bash
k6 run services/k6/load-test.js \
  --env CASINO_URL=http://localhost:3000 \
  --env VUS=10 \
  --env DURATION=5m
```

### Playwright (UX simulation)
- Use doc: `docs/testing/playwright.md`
- Example Docker run:
```bash
docker run --rm \
  -e CASINO_URL=http://localhost:3000 \
  -e USER_NAME=DemoUser \
  -e ITERATIONS=1 \
  hrexed/vegasapp-playwright:0.10
```

### Validate telemetry
- Trace view: ensure `frontend → game → scoring → db` is one trace.
- Metrics: check counters for plays/wins and histograms for latency.
- Logs: verify trace_id/span_id present and linkable.

---

## 11) 2-minute demo storyline

1) “Start a spin” in UI → show a single distributed trace (frontend → slots → scoring → db). (20s)
2) Show log with trace_id and jump to trace. (15s)
3) Dashboard A (Dev/SRE): highlight RED metrics + error rate. (25s)
4) Dashboard B (Casino Manager): win rate + revenue proxy + feature flag impact. (25s)
5) Trigger a feature flag variant, show change in win rate or latency. (20s)
6) Show SLO + Guardian recommendation (e.g., “roll back cheat flag variant”). (15s)

---

## Notes / gotchas
- Avoid PII in logs/attributes; prefer `player.id` or hashed username.
- Use `baggage` for propagation of `player.id` or `session.id` when needed.
- If using auto-instrumentation + manual spans, prefer enriching the active span instead of creating a new root span.

