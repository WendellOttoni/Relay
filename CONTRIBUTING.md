# Contributing to Relay

Relay is in its design phase. Contributions that clarify requirements,
challenge an invariant, or add a reproducible experiment are as valuable as
code.

## Before opening a change

1. Search existing issues and architecture decisions.
2. Open an issue before changing the wire protocol, storage format, delivery
   semantics, or public API.
3. Keep a pull request focused on one concern.
4. Add or update documentation when behavior changes.

## Architecture decisions

Decisions with a long-term compatibility or operational cost must be captured
as an ADR in `docs/adr`. Copy the template, describe alternatives honestly,
and submit it as `Proposed`. An ADR becomes `Accepted` only after review.

## Development expectations

Once implementation begins, every change is expected to pass formatting,
linting, unit tests, and relevant integration tests. Unsafe Rust must include a
written safety justification. Performance claims must include a reproducible
benchmark and environment details.

## Commit and pull request style

Use a short imperative subject and explain the reason for non-obvious changes
in the body. Pull requests should state:

- the problem being solved;
- the chosen approach and trade-offs;
- how the change was verified;
- any compatibility or migration impact.

## Reporting security issues

Do not disclose suspected vulnerabilities in a public issue. Follow the
private reporting process in [SECURITY.md](SECURITY.md).
