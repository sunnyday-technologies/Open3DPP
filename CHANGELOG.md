# Changelog

Each version has its own JSON Schema under `schemas/core/`, and each schema is
version-exact (`schema_version` is pinned by `const` and unknown properties are
rejected). Validate a record against the schema matching its own
`schema_version`.

A published schema artifact is permanent: it is superseded by a new version,
never rewritten in place and never removed. Column changes are additive within a
major series — a column is never renamed or repurposed — because a consumer that
pinned a version must keep resolving the same bytes. The release gate enforces
both properties on every publish.

## v0.1.0 — 2026-08-11

First public release. 152 typed columns in 8 blocks, each with a name, a type,
a unit and a one-line description generated from a single canonical definition,
so the field reference, the JSON Schema and the emitted records cannot drift
apart.

### The schema

- **A. Identity** (19) — brand/material/variant identifiers, GTIN and SKU,
  colour, a non-authoritative vendor-GUID alias, lifecycle status.
- **B. Composition** (23) — density, Tg / Tm / softening point, crystallinity,
  filler, hardness, surface-energy and adhesion descriptors, break
  temperatures, solubility, a controlled trait vocabulary.
- **C. Process** (37) — print conditions, with **every temperature stored as a
  min/max range** rather than a midpoint; a flow-to-temperature curve when a
  source publishes one; material-side hardware requirements; shrinkage.
- **D. Geometry** (18) — the ICME axis a settings-only format cannot carry:
  specimen standard and dimensions, orientation, raster angle, layer count,
  layer-time and thermal-mass proxies.
- **E. Structure** (8) — as-printed part density, void fraction,
  degree-of-healing, measured crystallinity, fibre alignment, roughness.
- **F. Properties** (17) — tensile, flexural, impact, interlayer-Z and HDT, each
  with a paired standard deviation.
- **M. Moisture** (11) — hygroscopic class, vendor drying limit, conditioning
  state, uptake kinetics, property-vs-moisture slopes.
- **G. Provenance** (19) — DOI, licence, technical and safety data sheets,
  certifications as published, measurement confidence, record revision.

### Principles it commits to

- **Preserve, don't presume.** A field is absent when unknown, never zero-filled
  or guessed, and never inferred from a related field. Vendor claims —
  certifications, safety trait tags, drying limits, hardware requirements — are
  recorded exactly as published and are never verified, tested or endorsed here.
- **Temperature is a range.** The useful value is goal-dependent, so both
  endpoints are preserved and the trade-off stays visible to the analyst. This
  is a data-modelling rationale, not printing advice.
- **SI units in the column name, and a standard deviation for every property.**
- **One fact, one place.** A trait promoted to a typed column is excluded from
  the tag vocabulary; derived quantities are stored as the source stated them
  and never back-filled from one another.
- **Cross-field range invariants** (`min_* <= max_*`) are published as normative
  and enforced by the publisher, because JSON Schema cannot compare two
  properties.

### What it deliberately does not carry

Equipment and environment records (a planned Applied-System Addendum of linked
sidecars, not yet published); compatibility matrices of material × printer ×
hotend, which are a different cardinality from "one row = one observation"; and
slicer implementation knobs, which are machine mechanics rather than material
characterization.

### Applied-System Addendum

Equipment, environment, measurement method and external artifacts are carried by
linked sidecars rather than by the core record, because a core row is one
observation and that context describes the run that produced it. Three schemas
ship alongside the core: applied-system context, measurement/outcome bundle, and
artifact/time-series manifest. Each references a core record through
`core_record_ref` and versions independently, so a core bump never invalidates a
sidecar, and the core carries no back-link — a record is complete without one.
See [ADDENDUM.md](ADDENDUM.md).

### Research behind it

`research/cura-fdm-material-census/` documents the field census of Ultimaker's
`fdm_material` XML format that informed the field set — 281 profiles, 55
structural XPaths and 61 setting keys, with the parser source treated as the
normative specification, since no written specification exists.
