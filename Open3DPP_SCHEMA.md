# Open3DPP v0.1.0 — Open 3D Polymer Printing schema

> **Open3DPP is a data schema, not printing or engineering advice.** Field semantics and
> example values are provided **AS IS**, without warranty of accuracy, completeness or
> fitness for a particular purpose. Records carry third-party data as published by their
> sources; vendor claims — certifications, safety trait tags, drying limits, hardware
> requirements — are recorded as published and are never verified here. Verify against the
> manufacturer's documentation before use. See [`NOTICE`](NOTICE) and [`LICENSE`](LICENSE).

The polymer sibling of **Open3DCP**. A single, flat characterization schema for FFF/FDM
polymer materials, print conditions, part geometry, and mechanical performance — a row is a
**settings card** (recommended conditions, no test), a **measured specimen** (geometry +
properties), or a **moisture response** (a fitted property-vs-moisture relation).

- **Identity + process** columns use **OpenPrintTag** field names (MIT) → a spool tag is a
  strict *projection* of Open3DPP, not a separate vocabulary.
- **Architecture** (fidelity, provenance, per-property uncertainty, controlled vocab) mirrors
  **Open3DCP** (Apache-2.0).
- Every column is defined in [`FIELDS.md`](FIELDS.md), generated from the canonical definition;
  the canonical JSON Schema is
  [`schemas/core/v0.1.0/open3dpp-record.schema.json`](schemas/core/v0.1.0/open3dpp-record.schema.json).
  Schemas are **version-exact**: each pins `schema_version` and rejects unknown properties, so a
  record is validated against the schema matching its own `schema_version`. The additive guarantee
  is about column stability across versions, not about one validator accepting every future one.
- Exact equipment, environment, operator/process history, repeatable measurements, external
  artifacts, rights, and sharing controls are out of scope for the core record. They are addressed
  by a planned **Open3DPP Applied-System Addendum** of linked JSON sidecars, which is **not yet
  published**. The addendum keeps its own `schema_version` and points at core records via
  `core_record_ref`, so a core version bump does not invalidate a sidecar.

## Why a geometry block (the ICME thesis)

Material identity + process conditions **do not fully remove property variability.** The same
filament at the same settings yields different strength in different part geometries, because
geometry sets the *thermal and load context*: layer time → interlayer healing window; feature
size / thermal mass → cooling rate → crystallinity; wall/orientation → anisotropy and stress
concentration. **Geometry is therefore a first-class characterization axis**, not metadata — a
settings-only format (OpenPrintTag) structurally cannot carry it, which is exactly why Open3DPP
exists alongside the tag.

## Blocks (152 columns; every column carries type + unit + doc in code)

| Block | Cols | Purpose |
|---|--:|---|
| **A. Identity** | 19 | brand/material/variant UUIDs, GTIN/SKU, colour, vendor-GUID alias, lifecycle, `material_type` enum (OpenPrintTag-aligned) |
| **B. Composition** | 23 | material intrinsics: density, Tg/Tm/softening, crystallinity class + %, filler, hardness, surface-energy & adhesion descriptors, break temps, solubility, controlled `trait_tags` |
| **C. Process** | 37 | print conditions; **every temperature stored as `min`/`max` range** (nozzle, bed, and now chamber), flow-temp graph, material-side hardware requirements (min nozzle Ø, nozzle HRC), shrinkage, drying-as-performed |
| **D. Geometry** | 18 | **shape context**: specimen std/dims, skin thickness, orientation, raster, layer count, layer-time & thermal-mass proxies |
| **E. Structure** | 8 | ICME mediators: as-printed part density, void fraction, degree-of-healing, crystallinity, fiber alignment, roughness |
| **F. Properties** | 17 | tensile/flexural/impact/**interlayer-Z**/HDT — now **every** property has a paired stddev column |
| **M. Moisture** | 11 | hygroscopic class, vendor drying limit, conditioning state, uptake kinetics, property-vs-moisture slopes |
| **G. Provenance** | 19 | DOI, license, TDS/SDS URLs, certifications-as-published, `measurement_confidence`, `is_training_ready`, `n_sources`, record revision/date |

## Governing principles (inherited from Open3DCP)

1. **Preserve, don't presume.** `NULL` for unknown; never invent a value. Ambiguous families
   (generic PA, PET, PVA, …) keep `material_type = NULL` and carry the family in
   `material_abbreviation` rather than being forced to a wrong enum member. **Vendor claims —
   certifications, safety and functional `trait_tags` (`biocompatible`, `self_extinguishing`,
   `antibacterial`, `esd_safe`, …), `max_dry_temperature_c` and `required_nozzle_hrc` — are
   recorded exactly as published and are never inferred, tested or verified.** Carrying such a
   value is not a representation that it is accurate, nor that the material is fit for any
   purpose.
2. **Temperature is stored as a range, never a midpoint.** The useful value is goal-dependent:
   studies report interlayer strength increasing toward the upper part of a vendor range, while
   vendors also cap the range for surface quality and dimensional control. Open3DPP therefore
   preserves `min_/max_print_temperature_c`, `min_/max_bed_temperature_c` and
   `min_/max_chamber_temperature_c`, so an analyst sees the trade-off instead of inheriting
   someone else's collapse of it. `flow_temp_graph` carries the full flow→temperature relation
   when a source publishes one. **This is a data-modelling rationale, not printing advice**: the
   strength relation does not hold for every material — thermally sensitive and filled grades
   behave differently — and the manufacturer's guidance governs.
3. **SI units named in the column; per-property stddev** for uncertainty: every property
   column has a paired standard-deviation column.
4. **One fact, one place.** Traits promoted to typed columns (`is_abrasive`, `solvent_class`,
   reinforcement → `filler_type`) are excluded from the `trait_tags` vocabulary; part-density /
   relative-density / void-fraction are stored as stated by the source, never back-filled from
   each other; drying **as performed** (process, `drying_temperature_c`) is distinct from the
   vendor-published drying limit (`max_dry_temperature_c`, moisture).

## Cross-field invariants (normative)

JSON Schema cannot compare two properties, so these are enforced by the emitter
and the release gate rather than by a validator. A record that violates one is
not conforming, even though a validator will accept it:

| Invariant | Fields |
|---|---|
| `min <= max` | `min_print_temperature_c` / `max_print_temperature_c` |
| `min <= max` | `min_bed_temperature_c` / `max_bed_temperature_c` |
| `min <= max` | `min_chamber_temperature_c` / `max_chamber_temperature_c` |
| `min <= max` | `filament_moisture_min_pct` / `filament_moisture_max_pct` |
| `min <= max` | `fan_min_pct` / `fan_max_pct` |

`flow_temp_graph` is deliberately **not** on this list: the curve is
machine-scoped upstream and routinely extends past both ends of the
material-level temperature range, so the two must not be reconciled.

## Boundaries (what Open3DPP deliberately does NOT carry)

- **Equipment/environment records** — the [Applied-System Addendum](ADDENDUM.md) owns exact system identity,
  components, calibration, environment time series, QMS and rights. The core keeps only
  `printer_model_reported`: the coarse string a harvested source actually stated.
- **Compatibility matrices** (material × printer × hotend → verdict, as in Cura's
  `fdm_material` `<machine>`/`<hotend>` scoping) — a different cardinality from "one row = one
  observation". The material-side part of that story is carried by `min_nozzle_diameter_mm`,
  `required_nozzle_hrc` and `is_abrasive`.
- **Slicer implementation knobs** (purge/park/anti-ooze kinematics, wipe/ramming, G-code) —
  machine mechanics, not material characterization.

## Versioning

Schemas are **version-exact**: each pins `schema_version` with `const` and rejects unknown
properties, so validate a record against the schema matching its own `schema_version`. There is
deliberately no `latest` alias — see [`schemas/README.md`](schemas/README.md).

**Permanence begins at the first announced release.** From that point a published schema artifact
is superseded by a new version, never rewritten in
place and never removed. Column changes are additive within a major series; a column is never
renamed or repurposed, because a consumer that pinned a version must keep resolving the same
bytes. Changes are recorded in [`CHANGELOG.md`](CHANGELOG.md).
