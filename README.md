<h1 align="center">Open3DPP</h1>
<p align="center"><strong>Open Data Standard for FFF/FDM Polymer Printing</strong></p>
<p align="center"><em>Status: Draft v0.1.0 — a community specification maintained by Sunnyday
Technologies. The schema may change before v1.0. No standards-body affiliation, and no
conformance certification, is implied.</em></p>
<p align="center">
  <a href="Open3DPP_SCHEMA.md">Schema Reference</a> ·
  <a href="FIELDS.md">Field Table (152 columns)</a> ·
  <a href="schemas/core/v0.1.0/open3dpp-record.schema.json">JSON Schema</a> ·
  <a href="examples/">Examples</a> ·
  <a href="CHANGELOG.md">Changelog</a> ·
  <a href="ADDENDUM.md">Addendum</a> ·
  <a href="CROSSWALK.md">Crosswalk</a> ·
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

The polymer sibling of [Open3DCP](https://github.com/sunnyday-technologies/Open3DCP), developed
by [Sunnyday Technologies](https://sunn3d.com). One row = one **characterization observation**
of an FFF polymer material: a *settings card* (recommended conditions), a *measured specimen*
(geometry + mechanical properties), or a *moisture response* (a fitted property-vs-moisture
relation). Every column has a name, a type, a unit, and a purpose. No hidden unit conventions.

This repository provides the **schema definition only** — the field table, the generated JSON
Schema, three illustrative example records, and the format research behind the design. It hosts no
materials database, recommends no settings, and ranks no products.

> **Disclaimer.** Open3DPP is a data schema, not printing or engineering advice. Field semantics,
> example values and research findings are provided **AS IS**, without warranty of accuracy,
> completeness or fitness for a particular purpose. Records carry third-party data as published by
> their sources; Sunnyday Technologies does not test, verify, endorse or certify any value —
> including temperatures, drying limits, hardware requirements, certifications and safety-related
> trait tags. Verify against the manufacturer's own documentation before use, and never exceed
> manufacturer-stated limits. See [`NOTICE`](NOTICE).

## Why this exists

Filament vendors publish settings as slicer profiles in at least five incompatible
vocabularies (Cura `fdm_material` XML, PrusaSlicer INI, Orca/Bambu JSON, OFD JSON, datasheet
PDFs). None of them can carry a mechanical test result, and a mechanical-test paper can rarely
be joined back to a purchasable product. Open3DPP is the join: identity + composition +
process + **geometry** + structure + properties + **moisture** + provenance in one flat,
analysis-ready record.

## The ICME thesis: geometry is an axis, not metadata

Material identity + process conditions **do not fully determine printed properties.** The same
filament at the same settings yields different strength in different part geometries, because
geometry sets the thermal and load context: layer time → interlayer healing window; feature
size / thermal mass → cooling rate → crystallinity; orientation → anisotropy. A settings-only
format structurally cannot carry this, which is why Open3DPP exists alongside spool-tag
formats.

## Blocks (152 columns)

| Block | Cols | Purpose |
|---|--:|---|
| **A. Identity** | 19 | brand/material/variant ids, GTIN/SKU, colour, vendor-GUID alias, lifecycle |
| **B. Composition** | 23 | density, Tg/Tm/softening, crystallinity, filler, hardness, adhesion descriptors, solubility, controlled trait tags |
| **C. Process** | 37 | print conditions — every temperature as a **min/max range**, flow→temperature graph, material-side hardware requirements, shrinkage |
| **D. Geometry** | 18 | specimen standard/dims, orientation, raster, layer count, layer-time & thermal-mass proxies |
| **E. Structure** | 8 | as-printed density, void fraction, degree-of-healing, measured crystallinity, fiber alignment |
| **F. Properties** | 17 | tensile/flexural/impact/interlayer-Z/HDT — each with a paired stddev |
| **M. Moisture** | 11 | hygroscopic class, vendor drying limit, uptake kinetics, property-vs-moisture slopes |
| **G. Provenance** | 19 | DOI, licence, TDS/SDS, certifications-as-published, confidence, revision |

Full reference: [FIELDS.md](FIELDS.md) · principles and boundaries:
[Open3DPP_SCHEMA.md](Open3DPP_SCHEMA.md)

## Validating a record

Each version ships its own JSON Schema (Draft 2020-12). Schemas are
**version-exact** — `schema_version` is pinned and unknown properties are rejected — so validate a
record against the schema matching its own `schema_version`.

The `$id` (`https://open3dpp.org/schemas/core/v0.1.0/…`) resolves to the schema it names.
`open3dpp.org` serves `schemas/` verbatim from this repository, and the site build refuses to
publish if any `$id` disagrees with the path it would be served from. **This repository remains
authoritative** — if the two ever differ, the repository is correct.

There is deliberately **no `latest` alias**: schemas pin `schema_version` with `const`, so a
`latest` pointer would break every consumer the moment a new version shipped. Resolve the schema
from the record's own `schema_version` — see [`schemas/README.md`](schemas/README.md).

`format` keywords (`uri` on the data-sheet fields) are annotations in Draft 2020-12 and only
assert when your validator is given a format checker; the bounds, patterns and `uniqueItems`
assertions always apply. Range invariants that compare two fields (`min_* <= max_*`) cannot be
expressed in JSON Schema and are enforced by the publisher instead — the normative list is in
[`Open3DPP_SCHEMA.md`](Open3DPP_SCHEMA.md).

```bash
pip install check-jsonschema
# from a local clone
check-jsonschema --schemafile schemas/core/v0.1.0/open3dpp-record.schema.json examples/*.json
# or by identifier
check-jsonschema   --schemafile https://open3dpp.org/schemas/core/v0.1.0/open3dpp-record.schema.json   my-record.json
```

```python
import json, jsonschema
schema = json.load(open("schemas/core/v0.1.0/open3dpp-record.schema.json"))
record = json.load(open("examples/settings-card.example.json"))
jsonschema.validate(record, schema)   # raises on a non-conforming record
```

Absent means unknown: omit a field rather than filling it with a zero or a guess.

## Coming from a format you already have

You probably already hold this data in a slicer profile or a filament database.
[CROSSWALK.md](CROSSWALK.md) maps Cura `fdm_material`, the Open Filament Database, and the
OrcaSlicer / Bambu Studio / PrusaSlicer families onto Open3DPP columns, field by field, with
the count of records each mapping actually populates. It is generated from the code that
performs the mapping, so it cannot drift into describing something the tooling does not do.

## Contributing

**Anyone can propose a change through GitHub.** A field the schema cannot express is a gap
worth reporting, not a reason to bend an existing column — open a
[field proposal](https://github.com/sunnyday-technologies/Open3DPP/issues/new?template=field-proposal.md)
or a [correction](https://github.com/sunnyday-technologies/Open3DPP/issues/new?template=data-correction.md).
[CONTRIBUTING.md](CONTRIBUTING.md) explains what a proposal needs and how a change lands: what
counts as additive, why published artifacts are never rewritten, and how a new column reaches a
release. No affiliation or prior involvement is required.

## Governing principles

1. **Preserve, don't presume.** NULL for unknown; never invent a value.
2. **Temperature is a range.** Published optima are goal-dependent — studies report interlayer
   strength increasing toward the upper part of a vendor range, while vendors also cap the range
   for surface quality and dimensional control. Preserving both endpoints keeps that trade-off
   available to the analyst instead of collapsing it to a midpoint. This is a data-modelling
   rationale, not a printing instruction.
3. **SI units in the column name; per-property stddev.**
4. **One fact, one place.** Promoted traits are excluded from the tag vocabulary; derived
   quantities are stored as the source stated them, never back-filled.

## What Open3DPP deliberately does not carry

- **Equipment/environment records** — exact system identity, components, calibration and
  environment time series are out of scope for a core record. They are carried by the
  [Applied-System Addendum](ADDENDUM.md): linked JSON sidecars that reference a core record via
  `core_record_ref`. The core carries no back-link and does not depend on the addendum, so a
  record is complete without one.
- **Compatibility matrices** (material × printer × hotend) — a different cardinality; the
  material-side constraints (`min_nozzle_diameter_mm`, `required_nozzle_hrc`, `is_abrasive`)
  are carried here.
- **Slicer implementation knobs** (purge/park/wipe kinematics, G-code) — machine mechanics,
  not material characterization.

## Research

[`research/cura-fdm-material-census/`](research/cura-fdm-material-census/) contains the full
field census of Ultimaker's `fdm_material` XML format (281 files, 55 structural XPaths and
61 setting keys, parser-code ground truth, repository-history analysis) that motivated this schema's field set — including the finding
that a `(printer, nozzle_diameter)` pairing key is provably lossy. It also records what the repository history showed at the
revision analysed (commit `886e7ad`, 2026-06-03; pull-request data retrieved 2026-08-10): the
database is CC0-1.0, no new material files were added during 2026 up to that commit, and of the 21 open pull
requests the median age was about four years (the newest was 65 days old). Those are observations about one
commit, not a characterisation of the project or a prediction about it.

## License

**Apache-2.0** for the schema, documentation and tooling in this repository.
Copyright 2026 Sunnyday Technologies. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

Third-party material keeps its own licence, and [`NOTICE`](NOTICE) records each one:

- `research/cura-fdm-material-census/` reproduces three Ultimaker `fdm_materials` profiles
  **verbatim, with comments added**, under CC0-1.0. Trademarks are not waived by CC0 and are used
  nominatively.
- `examples/` contains records derived from third-party sources. Attribution-conditional sources
  (CC BY 4.0) carry `doi`, `source_citation` and `source_license` **inside the record**, and the
  creator is named in [`NOTICE`](NOTICE) and [`examples/README.md`](examples/README.md). Carrying
  those fields helps attribution travel with a record, but it does not by itself discharge a
  reuser's obligations: anyone redistributing a record remains responsible for satisfying the
  source licence. Examples are restricted to sources whose licence permits republication.
- Records that aggregate copyleft-licensed profile trees (OrcaSlicer, Bambu Studio, PrusaSlicer —
  AGPL-3.0 family) name every licence involved in their own `source_license` field and are not
  published here.

Contributions are accepted under Apache-2.0 with a Developer Certificate of Origin sign-off; see
[`CONTRIBUTING.md`](CONTRIBUTING.md).
