# Wire protocol sketch

Status: **Exploratory**

This document defines questions and constraints for Relay's TCP protocol. It
is not yet a compatibility promise. The final format will be specified by an
accepted ADR before implementation.

## Goals

- Simple to implement in multiple languages.
- Unambiguous framing over a byte stream.
- Explicit protocol version negotiation.
- Request correlation for concurrent operations.
- Bounded frame and field sizes.
- Forward-compatible optional fields.

## Candidate frame

```text
+---------+---------+---------+------------+------------------+
| magic   | version | flags   | body len   | encoded body     |
| 2 bytes | 1 byte  | 1 byte  | 4 bytes    | N bytes          |
+---------+---------+---------+------------+------------------+
```

The body encoding is intentionally undecided. JSON is easy to inspect but
costly and weakly typed; a compact binary encoding is efficient but increases
client complexity. Benchmarks and SDK ergonomics should inform the ADR.

## Planned operations

| Category | Operations |
| --- | --- |
| Session | `HELLO`, `AUTH`, `PING`, `CLOSE` |
| Topology | `DECLARE_QUEUE`, `DECLARE_TOPIC`, `BIND` |
| Producer | `PUBLISH` |
| Consumer | `SUBSCRIBE`, `UNSUBSCRIBE`, `ACK`, `NACK` |
| Admin | `STATS`, `PURGE`, `DELETE` |

## Required protections

- Reject unsupported versions during handshake.
- Reject frames larger than the configured maximum before allocation.
- Apply per-connection idle and request timeouts.
- Never trust client-provided lengths or identifiers.
- Use stable error codes; diagnostic text is not part of the contract.
- Apply backpressure rather than buffering unbounded responses.

## Open questions

1. Binary format or length-prefixed JSON for v0.x?
2. Can requests be multiplexed on one connection?
3. Are publisher confirmations individual or batched?
4. How are resumable consumer sessions identified?
5. Which authentication mechanism is appropriate before TLS support?
