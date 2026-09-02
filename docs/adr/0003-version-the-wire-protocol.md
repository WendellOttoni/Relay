# 0003 — Version the wire protocol from its first frame

- Status: Accepted
- Date: 2026-09-02

## Context

Clients and servers will evolve independently. Without explicit negotiation, a
format change can be misread as valid data and cause silent incompatibility.

## Decision

Every connection begins with a handshake that identifies the protocol version.
Every frame carries enough fixed metadata to validate its version and length
before decoding the body. Unsupported versions fail with a stable error.

This ADR does not choose the body encoding; that requires measurements and a
separate decision.

## Consequences

Compatibility logic exists from the beginning, slightly increasing the first
implementation's complexity. In return, SDKs can fail clearly and future
versions have a defined migration path.

## Alternatives considered

- **Version only during handshake:** smaller frames, but makes captured frames
  and recovery after decoder state loss harder to diagnose.
- **No version until v1:** initially simpler, but encourages accidental
  contracts and ambiguous parsing failures.
