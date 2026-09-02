# 0001 — Use Rust for the broker implementation

- Status: Accepted
- Date: 2026-09-02

## Context

Relay needs predictable resource use, safe concurrency, explicit error
handling, and control over its storage and network formats. It should also be
deployable as a small standalone binary.

## Decision

Implement the broker, server, CLI, and first client library in stable Rust.
Unsafe code is prohibited by default and requires a localized justification.

## Consequences

Rust provides memory safety without a garbage collector and a strong type
system for modeling delivery state. The project accepts a steeper learning
curve, longer compile times, and a smaller contributor pool than languages
with managed runtimes.

## Alternatives considered

- **Go:** excellent networking and deployment story, but less direct control
  over allocation and fewer compile-time tools for encoding state transitions.
- **C#:** productive async ecosystem, but a managed runtime is less aligned
  with the project's systems-learning goal.
- **C++:** sufficient control, but materially increases the memory-safety burden.
