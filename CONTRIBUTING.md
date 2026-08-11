# Contributing to Open3DPP

Open3DPP is a community specification maintained by Sunnyday Technologies.
Corrections, field proposals and interoperability reports are all welcome.

## Licensing of contributions (inbound = outbound)

By submitting a pull request or patch you agree that your contribution is
licensed under the **Apache License, Version 2.0**, the same licence as the
project, and that you have the right to submit it.

Please sign off every commit to certify the
[Developer Certificate of Origin](https://developercertificate.org/) 1.1:

```bash
git commit -s -m "your message"
```

`-s` appends a `Signed-off-by:` line. If you are contributing on behalf of an
employer, make sure you are authorised to do so.

## What belongs in this repository

**In scope:** the field table, its types/units/documentation, the JSON Schema,
worked examples, crosswalks to other formats, and research that justifies a
schema decision.

**Out of scope:** a materials database. Open3DPP defines how a record is shaped;
it does not host filament data, recommend settings, or rank products.

## Proposing a field

Open an issue first, with:

1. **The observation it records** — what is measured or published, and by whom.
2. **Unit and type**, and how the unit is expressed in at least one real source.
3. **Why an existing column will not carry it.** Duplication is the main thing
   we reject: a fact must be representable in exactly one place. Check whether
   the concept is already covered by a promoted trait, a filler column, or the
   planned Applied-System Addendum (equipment, environment, QMS context).
4. **At least one real source** that publishes the value. Fields with no data
   behind them are deferred, not added speculatively.

Two rules govern every field:

- **Preserve, don't presume.** Unknown is NULL. Never derive a value and store
  it as if it were observed.
- **Vendor claims are pass-throughs.** Certification and safety-adjacent fields
  record exactly what a source published. Proposals that require the project to
  assess, test or certify anything will be declined.

## Versioning and stability

- Column names are stable. A minor version may **add** columns; it does not
  rename or remove them.
- Each published version has its own JSON Schema, which is version-exact: it
  pins `schema_version` and is closed to unknown properties. Validate a record
  against the schema matching its own `schema_version`.
- Breaking changes wait for a major version and are listed in
  [`CHANGELOG.md`](CHANGELOG.md).

## Decision process

Sunnyday Technologies maintains the specification and decides what merges.
There is no standards-body affiliation and no formal ratification process; the
"Draft" status reflects that the schema is still changing, not that an external
body is reviewing it.
