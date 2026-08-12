# Security and data-integrity reporting

Open3DPP is a schema and a set of static documents. It runs no service and
executes no user data, so the realistic risks are **integrity** rather than
compromise: a schema artifact that does not match what it claims, a published
identifier pointing somewhere unintended, or personal data appearing in a
research file.

## Reporting

Preferred: GitHub's private reporting — **Security → Report a vulnerability** on
<https://github.com/sunnyday-technologies/Open3DPP>. That keeps the report
confidential until a fix is out.

If you cannot use GitHub, email **security@sunn3d.com**. Please do not open a
public issue for anything in the first two categories below.

## In scope

- A published schema artifact whose bytes differ from what this repository or
  the changelog says it should be, or whose `$id` does not match the path it is
  served from.
- A released version's artifact being altered rather than superseded.
- Personal data (names, emails, phone numbers, postal addresses) in any file,
  including the research corpus and its extracted example values. Report these
  privately; they are removed rather than debated.
- Anything served from `open3dpp.org` that this repository does not contain.

## Out of scope

- Values being wrong in an upstream vendor's or paper's data. Open3DPP records
  third-party claims as published and verifies none of them; a wrong vendor
  figure is a data-quality issue, not a security one. Open a normal issue.
- Findings against other Sunnyday Technologies properties — report those through
  the relevant project, not here.

## Response

We aim to acknowledge within five working days. Integrity fixes ship as a new
version with the reason stated in the changelog; a published artifact is never
silently rewritten.
