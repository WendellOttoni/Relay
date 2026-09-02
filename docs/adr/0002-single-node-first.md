# 0002 — Build a correct single-node broker first

- Status: Accepted
- Date: 2026-09-02

## Context

Replication and consensus multiply failure modes before basic delivery,
backpressure, and recovery semantics are understood. The project needs a scope
that permits deep implementation and credible testing.

## Decision

Relay v1 will be a single-node broker. It will provide durable local storage
but make no high-availability claim after machine or disk loss.

## Consequences

The core can remain compact and observable, and crash recovery can be tested
thoroughly. Relay will not suit workloads that require automatic failover.
Storage and public APIs should avoid assumptions that make future replication
impossible, but no abstraction will be added solely for a hypothetical cluster.

## Alternatives considered

- **Leader/follower replication in v1:** rejected because it introduces
  consensus, membership, and split-brain concerns too early.
- **In-memory only:** rejected because persistence and recovery are central
  learning goals.
