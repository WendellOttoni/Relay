# Roadmap

The roadmap is organized around demonstrable behavior. Dates are intentionally
absent; a milestone is complete only when its exit criteria are met.

## v0.1 — Foundation

- Rust workspace and crate boundaries.
- Configuration precedence and validation.
- Structured error model and tracing conventions.
- CI for formatting, linting, tests, and dependency audit.

**Exit:** a documented server process starts, validates configuration, reports
health, and shuts down cleanly.

## v0.2 — In-memory broker

- Queue declaration and deletion.
- Publish and consume.
- ACK/NACK and visibility timeout.
- Bounded queues and producer backpressure.

**Exit:** deterministic state-machine and integration tests demonstrate
at-most-once and at-least-once delivery.

## v0.3 — TCP protocol and CLI

- Versioned frame codec and handshake.
- Client sessions and request correlation.
- CLI for queue administration, publish, and consume.
- Fuzz/property tests for frame parsing.

**Exit:** separate processes exchange messages over TCP, and malformed frames
cannot crash or exhaust the server.

## v0.4 — Reliability controls

- Retry policies and delayed redelivery.
- Dead-letter queues.
- Message TTL and queue limits.
- Consumer cancellation and connection recovery behavior.

**Exit:** fault-oriented tests cover disconnects, poison messages, and slow
consumers without unbounded resource growth.

## v0.5 — Durability

- Append-only record format with checksums.
- Durable publisher confirmation.
- Startup recovery and torn-write handling.
- Snapshots and log compaction.

**Exit:** crash-injection tests prove acknowledged durable messages recover and
partial records are safely ignored.

## v0.6 — Topics and consumer groups

- Topic declaration and queue bindings.
- Fan-out delivery.
- Competing consumers within a group.
- Subscription lifecycle and cleanup.

**Exit:** routing behavior has a precise contract and end-to-end test matrix.

## v0.7 — Operations

- Metrics for throughput, depth, latency, retries, and failures.
- Health and readiness endpoints.
- Configuration reload policy.
- Backup and recovery documentation.

**Exit:** an operator can diagnose queue pressure and execute a documented
recovery drill.

## v1.0 — Stable release

- Stable protocol and persistence compatibility policy.
- Rust SDK and complete examples.
- Security and performance review.
- Reproducible benchmark suite and published baseline.
- Deployment and upgrade guides.

**Exit:** all guarantees, limits, and unsupported scenarios are documented and
tested.

## Explicitly later

Clustering, replication, transactions across queues, exactly-once delivery,
WebSocket transport, additional SDKs, and a management dashboard may be
explored only after the single-node core is reliable.
