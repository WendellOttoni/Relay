# Architecture

## Context

Relay is a single-node message broker designed to expose the essential
mechanics of reliable messaging without hiding them behind a large distributed
system. The initial system favors explicit state transitions and observability
over feature count.

## Component boundaries

```text
+------------+     +-----------+     +----------------+
| TCP server | --> | protocol  | --> | broker runtime |
+------------+     +-----------+     +---+--------+---+
                                          |        |
                                   +------v--+  +--v---------+
                                   | queues  |  | scheduler  |
                                   +------+--+  | retry/TTL  |
                                          |     +------------+
                                   +------v------------------+
                                   | persistence / recovery |
                                   +-------------------------+
```

### Transport

Owns sockets, connection limits, timeouts, and graceful shutdown. It converts
bytes into protocol frames but does not make messaging decisions.

### Protocol

Validates frames, negotiates a protocol version, authenticates a session, and
maps commands to broker operations. Protocol errors do not leak storage or
runtime details.

### Broker runtime

Owns exchanges/topics, queues, subscriptions, and message state. It enforces
delivery semantics independent of the transport used by a client.

### Delivery scheduler

Tracks visibility deadlines, delayed delivery, retry limits, and dead-letter
routing. Time is injected so behavior remains deterministic in tests.

### Persistence

Records durable mutations in an append-only log before acknowledging them to a
publisher. On startup it rebuilds broker state from a snapshot and subsequent
log records. Compaction is an offline concern for the first durable milestone.

### Observability

Exposes structured events and metrics without coupling the broker runtime to a
specific exporter. Logs must never contain message payloads by default.

## Core message state

```text
published -> available -> in-flight -> acknowledged
                  ^           |
                  |           +-> retry scheduled
                  |                    |
                  +--------------------+
                                       |
                                       +-> dead-lettered
```

A message identifier is immutable. Delivery attempts and deadlines are broker
metadata, not mutations of the payload.

## Initial invariants

- A durable publish is acknowledged only after its log record is durable.
- A message has at most one active delivery per consumer group.
- ACK and NACK operations are idempotent within a session window.
- An expired visibility timeout makes a message eligible for redelivery.
- Retry limits are bounded; poison messages cannot loop forever.
- Slow consumers cannot cause unbounded process memory growth.
- Recovery never exposes a partially written record as a valid message.

## Concurrency model

The proposed model is asynchronous I/O at the edges and ownership-based state
inside the broker. Each queue is managed by a single logical owner receiving
commands through bounded channels. This avoids a global mutex while keeping
state transitions serial and auditable. The model must be validated by a
prototype before it becomes an accepted decision.

## Proposed workspace

| Crate | Responsibility |
| --- | --- |
| `relay-core` | Domain types, commands, delivery state |
| `relay-protocol` | Frames, codecs, version negotiation |
| `relay-storage` | Log, snapshots, recovery, compaction |
| `relay-server` | Configuration, TCP runtime, lifecycle |
| `relay-cli` | Publishing, consuming, and administration |
| `relay-testkit` | Deterministic clocks and integration fixtures |

Crate boundaries are proposals until implementation pressure validates them.
Avoid creating a crate that has no independent responsibility.

## Failure model

The first stable version targets a single process on a single machine. It must
handle malformed clients, slow consumers, dropped connections, full queues,
partial log writes, and process restarts. It does not claim availability after
host or disk loss, because replication is outside the v1 scope.

## Testing strategy

- State-machine tests for message transitions.
- Property tests for frame parsing and log recovery.
- Fault injection around partial writes and abrupt shutdown.
- Integration tests using real TCP connections.
- Soak tests for bounded memory and redelivery behavior.
- Benchmarks that publish environment and workload definitions.
