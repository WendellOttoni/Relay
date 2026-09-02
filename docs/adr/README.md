# Architecture decision records

ADRs record decisions that are expensive to reverse or affect compatibility.
They explain context and trade-offs so future changes do not depend on memory.

## Status

| ADR | Decision | Status |
| --- | --- | --- |
| [0001](0001-use-rust.md) | Use Rust for the broker implementation | Accepted |
| [0002](0002-single-node-first.md) | Build a correct single-node broker first | Accepted |
| [0003](0003-version-the-wire-protocol.md) | Version the wire protocol from its first frame | Accepted |

## Adding an ADR

Copy [the template](template.md), assign the next number, and use a short
kebab-case title. ADRs are immutable after acceptance except for corrections.
A later decision supersedes an earlier one instead of rewriting history.
