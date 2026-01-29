/**
 * OpenTelemetry Metrics for Vegas Casino
 * Provides consistent metrics across all game services
 */

const { metrics } = require('@opentelemetry/api');
const { MeterProvider, PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-grpc');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

let meterProvider;
let meter;
let metricsInitialized = false;

// Metric instruments
let gamePlayCounter;
let gameWinCounter;
let gameLossCounter;
let betAmountHistogram;
let gameLatencyHistogram;
let scoringLatencyHistogram;

/**
 * Initialize metrics provider
 */
function initializeMetrics(serviceName) {
  if (metricsInitialized) {
    return meter;
  }

  const resource = new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
    [SemanticResourceAttributes.SERVICE_NAMESPACE]: process.env.SERVICE_NAMESPACE || 'vegas-casino',
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.DEPLOYMENT_ENVIRONMENT || 'hackathon',
  });

  // Format endpoint for gRPC
  let endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT;
  if (endpoint && !endpoint.startsWith('http://') && !endpoint.startsWith('https://')) {
    endpoint = `http://${endpoint}`;
  }

  const metricExporter = new OTLPMetricExporter({
    url: endpoint || 'http://otel-collector.default.svc.cluster.local:4317',
  });

  const metricReader = new PeriodicExportingMetricReader({
    exporter: metricExporter,
    exportIntervalMillis: 10000, // Export every 10 seconds
  });

  meterProvider = new MeterProvider({
    resource,
    readers: [metricReader],
  });

  metrics.setGlobalMeterProvider(meterProvider);
  meter = metrics.getMeter(serviceName);

  // Create metric instruments
  gamePlayCounter = meter.createCounter('game.plays.total', {
    description: 'Total number of game plays',
    unit: '1',
  });

  gameWinCounter = meter.createCounter('game.wins.total', {
    description: 'Total number of game wins',
    unit: '1',
  });

  gameLossCounter = meter.createCounter('game.losses.total', {
    description: 'Total number of game losses',
    unit: '1',
  });

  betAmountHistogram = meter.createHistogram('bet.amount', {
    description: 'Distribution of bet amounts',
    unit: 'currency',
  });

  gameLatencyHistogram = meter.createHistogram('game.latency.ms', {
    description: 'Game processing latency in milliseconds',
    unit: 'ms',
  });

  scoringLatencyHistogram = meter.createHistogram('scoring.latency.ms', {
    description: 'Scoring service call latency in milliseconds',
    unit: 'ms',
  });

  metricsInitialized = true;
  console.log(`[Metrics] Initialized for service: ${serviceName}`);
  return meter;
}

/**
 * Record a game play
 */
function recordGamePlay(gameType, username, attributes = {}) {
  if (!metricsInitialized) return;
  
  gamePlayCounter.add(1, {
    'game.type': gameType,
    'user.name': username,
    ...attributes,
  });
}

/**
 * Record a game win
 */
function recordGameWin(gameType, username, payout, attributes = {}) {
  if (!metricsInitialized) return;
  
  gameWinCounter.add(1, {
    'game.type': gameType,
    'user.name': username,
    'game.outcome': 'win',
    ...attributes,
  });
}

/**
 * Record a game loss
 */
function recordGameLoss(gameType, username, attributes = {}) {
  if (!metricsInitialized) return;
  
  gameLossCounter.add(1, {
    'game.type': gameType,
    'user.name': username,
    'game.outcome': 'loss',
    ...attributes,
  });
}

/**
 * Record bet amount
 */
function recordBetAmount(gameType, amount, attributes = {}) {
  if (!metricsInitialized) return;
  
  betAmountHistogram.record(amount, {
    'game.type': gameType,
    ...attributes,
  });
}

/**
 * Record game latency
 */
function recordGameLatency(gameType, latencyMs, attributes = {}) {
  if (!metricsInitialized) return;
  
  gameLatencyHistogram.record(latencyMs, {
    'game.type': gameType,
    ...attributes,
  });
}

/**
 * Record scoring service latency
 */
function recordScoringLatency(gameType, latencyMs, attributes = {}) {
  if (!metricsInitialized) return;
  
  scoringLatencyHistogram.record(latencyMs, {
    'game.type': gameType,
    ...attributes,
  });
}

/**
 * Shutdown metrics provider
 */
async function shutdownMetrics() {
  if (meterProvider) {
    await meterProvider.shutdown();
    console.log('[Metrics] Provider shutdown complete');
  }
}

module.exports = {
  initializeMetrics,
  recordGamePlay,
  recordGameWin,
  recordGameLoss,
  recordBetAmount,
  recordGameLatency,
  recordScoringLatency,
  shutdownMetrics,
};
