# Relay

> A small, reliable message broker built from scratch in Rust.

Relay is an educational systems project focused on the internals of message
brokers: protocols, delivery guarantees, persistence, backpressure, and
concurrency. The goal is not to replace production brokers, but to build a
compact implementation whose behavior can be understood end to end.

> [!IMPORTANT]
> Relay is currently in the design phase. The repository contains the project
> specification and architecture decisions; no usable broker has been released
> yet.

## Why Relay?

Most messaging tutorials stop at an in-memory queue. Relay goes further by
making the difficult parts visible and testable:

- queues and publish/subscribe topics;
- explicit acknowledgements and redelivery;
- bounded retries and dead-letter queues;
- durable messages backed by an append-only log;
- consumer groups and competing consumers;
- flow control for slow clients;
- a documented, versioned wire protocol;
- metrics and operational visibility.

## Planned experience

```text
publisher                 Relay                     consumers
    |                       |                           |
    |--- PUBLISH orders --->|                           |
    |<------- OK -----------|--- MESSAGE orders ------>|
    |                       |<--------- ACK ------------|
```

The initial interface will be a TCP server and a small CLI:

```console
$ relay-server --data ./relay-data
$ relay-cli queue create orders --durable
$ relay-cli publish orders '{"order_id": 42}'
$ relay-cli consume orders --group billing
```

Command names and syntax are provisional until the protocol ADR is accepted.

## Scope

The first stable release is intended to provide:

| Area | v1 target |
| --- | --- |
| Messaging | Queues, topics, consumer groups |
| Delivery | At-most-once and at-least-once |
| Reliability | ACK/NACK, retry, dead-letter queues |
| Persistence | Append-only log and recovery |
| Networking | Versioned protocol over TCP |
| Operations | Health checks, metrics, graceful shutdown |
| Tooling | CLI administration and Rust client |

Exactly-once delivery, clustering, a web dashboard, and multi-region
replication are deliberately outside the v1 scope.

## Architecture

```text
                         +------------------+
 publishers / consumers |   TCP transport  |
 ----------------------> +---------+--------+
                                   |
                         +---------v--------+
                         | protocol + auth  |
                         +---------+--------+
                                   |
                    +--------------v---------------+
                    | routing, queues and delivery |
                    +------+----------------+-------+
                           |                |
                    +------v------+  +------v------+
                    | scheduler   |  | persistence |
                    | ACK / retry |  | append log  |
                    +-------------+  +-------------+
```

See [the architecture document](docs/architecture.md) for component
boundaries, invariants, and the proposed repository layout.

## Roadmap

- **v0.1 — Foundation:** workspace, configuration, error model, CI.
- **v0.2 — In-memory broker:** queues, publish, consume, ACK/NACK.
- **v0.3 — Wire protocol:** TCP framing, client sessions, CLI.
- **v0.4 — Reliability:** retry policy, visibility timeout, dead letters.
- **v0.5 — Durability:** append-only log, recovery, compaction.
- **v0.6 — Pub/sub:** topics, subscriptions, consumer groups.
- **v0.7 — Operations:** metrics, health checks, graceful shutdown.
- **v1.0 — Stable:** compatibility policy, benchmarks, complete docs.

Milestone definitions and exit criteria live in [the full roadmap](docs/roadmap.md).

## Design principles

1. **Correctness before throughput.** Delivery state must remain explainable.
2. **Bounded resource use.** Queues and clients must apply backpressure.
3. **Crash recovery is a feature.** Durable state must survive abrupt exits.
4. **Small, explicit protocol.** Every frame is versioned and documented.
5. **Measure, then optimize.** Performance work requires reproducible benchmarks.

## Repository layout

```text
crates/       planned Rust workspace crates
docs/         architecture, protocol, roadmap, and ADRs
examples/     planned end-to-end examples
benchmarks/   planned reproducible performance scenarios
sdk/          planned client libraries
```

The directories currently contain contracts and ownership notes only. Source
code will be introduced incrementally as roadmap milestones begin.

## Status and contributing

The public API and wire protocol are not stable. Design feedback is welcome
through issues and discussions. Before contributing, read
[CONTRIBUTING.md](CONTRIBUTING.md) and the accepted
[architecture decisions](docs/adr/README.md).

## License

Relay is available under the [MIT License](LICENSE).
