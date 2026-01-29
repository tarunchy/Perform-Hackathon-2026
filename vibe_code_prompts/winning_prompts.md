You are my hackathon automation engineer inside this Codespace.

Goal: fully automate the Dynatrace Perform 2026 Vegas Casino hackathon so I can win with minimal manual steps.

Do this end-to-end, in this order:

A) Environment verification + recovery
1) Confirm kubectl/kind/helm are installed and the KIND cluster is reachable.
2) Verify the vegas-casino namespace exists and all app pods are Running.
3) If deployment is broken, fix it (use repo scripts like codespace/deployment.sh and/or build-and-load-kind.sh). Prefer local image build+kind load if registry images are not accessible.
4) Print a clear “READY” summary: cluster name, namespaces, gateway/frontend URL/ports.

B) Secrets + Dynatrace connectivity checks
5) Verify required env vars exist in the Codespace environment:
   DYNATRACE_ENVIRONMENT_ID, DYNATRACE_ENVIRONMENT, DYNATRACE_API_TOKEN,
   DYNATRACE_PLATFORM_TOKEN, DYNATRACE_OAUTH_CLIENT_ID, DYNATRACE_OAUTH_CLIENT_SECRET,
   DYNATRACE_ACCOUNT_ID, and DYNATRACE_CONFIG_API_TOKEN.
   If any are missing, stop and tell me exactly which ones and where to add them (GitHub → Settings → Secrets and variables → Codespaces), then tell me to restart Codespace and re-run the script.

C) Instrumentation upgrades (high impact, minimal changes)
6) Implement end-to-end trace propagation across services (frontend → game services → scoring; gateway proxy too).
7) Add log-trace correlation everywhere feasible:
   - Node: services/common/logger.js add trace_id/span_id
   - Python: services/common/logger.py add trace_id/span_id
   - Java: scoring service add MDC trace_id/span_id (or equivalent)
8) Add 5 key OTel metrics with consistent names/tags:
   game_plays_total, game_wins_total, bet_amount, game_latency_ms, scoring_latency_ms
   Ensure they export to Dynatrace via OTLP.
9) Normalize service names and OTel env vars in Helm so all services have consistent:
   OTEL_SERVICE_NAME, OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_EXPORTER_OTLP_INSECURE,
   OTEL_RESOURCE_ATTRIBUTES (service.namespace=vegas-casino, deployment.environment=hackathon).

D) Build, deploy, validate
10) Rebuild images (if needed), load into KIND, redeploy Helm release, wait for pods.
11) Run automated traffic generation:
   - Run k6 load test for 2–3 minutes (or whatever repo supports).
   - Run Playwright simulation at least once (or whatever repo supports).
   - Also do a basic curl-based smoke test against frontend/gateway endpoints.
12) Verify telemetry locally:
   - Confirm requests succeed
   - Confirm logs include trace_id/span_id
   - Confirm OTel collector pods are healthy
   - Print commands I can use to confirm traces/metrics inside Dynatrace (filters / where to look).

E) Deliverables for judging + git push
13) Create DEMO.md: a 2-minute demo script + “what to click in Dynatrace” checklist + screenshots commands.
14) Update/extend HACKATHON_READY.md with the final exact steps.
15) Commit changes with meaningful messages and push to my fork.

Constraints:
- Keep changes minimal and focused on hackathon impact.
- Do not ask me questions unless you are blocked by missing secrets.
- If blocked, output a single concise checklist of what I must do, then stop.
- Always end with: (1) app URL, (2) tests run, (3) what changed, (4) next 3 steps for me.

Now execute.
