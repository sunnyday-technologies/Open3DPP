# Cura `fdm_material` XML — field taxonomy harvest for Open3DPP

**Read-only analysis, 2026-08-10.** Sources analysed (read-only):
`Ultimaker/fdm_materials` @ `886e7ad` (2026-06-03), **281** `*.xml.fdm_material` files, all
format `version="1.3"`; `Ultimaker/Cura` @ `63f92d4` (2026-08-10), parser
`plugins/XmlMaterialProfile/XmlMaterialProfile.py` (1,239 lines) + `XmlMaterialValidator.py`.
Census: **55** distinct structural element/attribute XPaths plus **61** distinct `@key`
setting names = **116** fields observed in the corpus. `fields.csv` carries **132** rows:
those 116 plus 16 fields the parser supports that no file uses. All coverage numbers below
come from parsing the corpus, not from any spec.

**Documentation status:** there is **no** fdm_material spec page on the Cura wiki (index checked,
28 pages, none material-format related), and none in the `fdm_materials` repo. The parser is not
merely ground truth over the wiki — it is the *only* normative description. Consequently the
divergences reported below are code-vs-corpus, not code-vs-wiki. Nothing here is inferred from
prose.

---

## 1. Override / scoping mechanism — the machine-material pairing analog

`<settings>` is a **three-level cascade, most-specific-wins**:

```
<settings>                       ROOT   — applies to every printer + every hotend
  <setting key="…">              (direct children)
  <machine>                      MACHINE — one or more <machine_identifier> children
    <machine_identifier manufacturer="…" product="…"/>
    <setting key="…">
    <hotend id="…">              HOTEND — print core / nozzle
      <setting key="…">
      <buildplate id="…">        BUILDPLATE — implemented in code, used by 0/281 files
```

Mechanics, from the parser:

- **Multi-identifier shorthand.** A `<machine>` may carry several `<machine_identifier>` children.
  `_expandMachinesXML()` deep-copies the block once per identifier before any merge, so this is
  purely a file-size optimisation, not a distinct semantic.
- **Product resolution is by human-readable name, not id.** `@product` (e.g. `"Ultimaker S5"`) is
  looked up in `FormatMaps.getProductIdMap()`; on a miss it falls back to
  `getPossibleDefinitionIDsFromName()`, which mangles the string (strip spaces, underscore spaces,
  glue trailing digits to the previous word). `@manufacturer` is optional and defaults to the
  printer definition's own manufacturer. **This is a fuzzy join, and it is the format's weakest
  link.**
- **Materialisation, not traversal.** `deserialize()` does not resolve the cascade at slice time.
  It *pre-merges* and emits one container per scope: `<base>`, `<base>_<machine_id>`,
  `<base>_<machine_id>_<hotend_name>` (spaces → `_`). Each child copies the parent's merged dict
  then applies its own deltas. Lookup at slice time is a dict hit.
- **Compatibility is a separate, inherited gate.** `hardware compatible` (`yes|no|unknown`) is not
  a setting — it becomes the boolean `compatible` metadata entry via
  `_parseCompatibleValue()`, which returns **True for both `yes` and `unknown`**. Absent at a scope
  → inherit the enclosing scope; absent everywhere → `True`. The format is
  **compatible-by-default**; only an explicit `no` excludes.
- **File-level inheritance** (`<inherits>`) is implemented in `deserialize()` but carries a
  `TODO: unimplemented` in `deserializeMetadata()`. Used by **0/281** files.

**Why this matters to us.** The corpus contains **5,273** distinct (material × product × hotend)
triples, of which **940 (17.8%)** are declared incompatible, across **66** materials. `<hotend>@id`
is free text with **51** distinct values that mix core codes with bare diameters (`"AA 0.4"`,
`"CC 0.4"`, `"0.4 mm"`, `"0.4mm"`, `"Smart Extruder+"`). Crucially **AA 0.4, BB 0.4, CC 0.4 and
DD 0.4 all exist**, and in `ultimaker_petcf` the AA/BB/DD variants are `no` while CC is `yes` —
**identical nozzle diameter, opposite verdict**. Any pairing key of the form
`(printer_model, nozzle_diameter_mm)` is therefore provably lossy. Our schema currently has exactly
that shape (`printer_vendor`, `printer_model`, `nozzle_diameter_mm`), so the
main structural harvest is a **hotend/core identity column distinct from nozzle diameter**, plus a
**tri-state pairing verdict** rather than presence/absence of a row.

Caveat on generality: **1,250 of 1,454** `machine_identifier` elements name an Ultimaker printer,
and **96 of 281** files carry no `<machine>` block at all. The scoping machinery is real but is
overwhelmingly exercised by one vendor's hardware.

---

## 2. Identity model

- `<GUID>` is **required** (`XmlMaterialValidator`: GUID, brand, material, version). It is a
  UUIDv4, **vendor-generated, not centrally issued** — nothing in the repo or CI assigns or
  validates it. In the corpus: **281 GUIDs / 281 files, zero collisions.**
- Granularity is **one GUID per profile file**, i.e. per (brand × product × colour × diameter).
  Colour variants each get their own GUID (`ultimaker_petcf_black`, `_blue`, `_gray` are three
  GUIDs). There is **no** vendor-family or product-level identifier. `<reference_material_id>`
  (19 files, free string) is the only lineage hint and has **no reader anywhere in the Cura tree**.
- `<version>` is a per-profile monotonic revision counter (1–57 observed), unrelated to the root
  `@version` format number.
- GUID → spool linkage: the GUID is what NFC tags / Material Station / Digital Factory carry;
  `material_guid` is exposed as a slicing setting so G-code can name it.

**Versus OFD.** OFD addresses by **path** (`data/<brand>/<material>/<product>/<variant>/`) plus a
`uuid` that is *CI-assigned on merge* and carries a `moved_from` array of superseded UUIDs — i.e.
OFD has a rename/merge story and Cura has none. OFD's identity is hierarchical (brand → material →
filament → variant → size, each with its own uuid); Cura's is flat.

**Collision / keying risk if we key to both:** low for uniqueness (no observed collisions on
either side), but the two systems are **not at the same granularity**. Cura GUID ≈ OFD *variant*
level, not filament level, and Cura folds diameter into the GUID (`Extrudr_GreenTECPro_Black_175`)
whereas OFD splits it into `sizes[]`. A Cura GUID therefore maps to (OFD variant × one size), which
is many-to-one in the OFD direction and cannot be inverted without the diameter. Recommendation:
store `vendor_material_guid` as a **non-authoritative alias column**, keep our own key, and never
join OFD↔Cura on GUID alone — join on (brand, product, colour, diameter).

---

## 3. Census highlights and code-vs-corpus divergences

Coverage of every field is in `fields.csv`. Notable structural facts:

- **No unit conversion happens in the parser.** Every value is handed to the container as a raw
  string. Units are declared only in `resources/definitions/fdmprinter.def.json` on the *target*
  setting (e.g. `print temperature` → `default_material_print_temperature`, °C, default 210).
  The two exceptions: `processing temperature graph` `<point>`s are cast to `float` pairs, and
  `approximate_diameter = str(round(float(diameter)))`.
- `<density>` (100%) and `<weight>` (59.4%) are read into `metadata["properties"]` and shown in the
  UI model but **never used to slice**. No unit is declared or validated: density is g/cm³ by
  convention only, and `eazao_clay` states `1600` (kg/m³) — a real unit error in the source data
  that a unit-sanity pass must correct.
- **`retract compensation` is in 103 files (36.7%) and in no parser map** → Cura logs
  `"Unsupported material setting"` and drops it. Written by a third of the corpus, read by nobody.
  (`purge speed coefficient`, 5 files, same fate.) *Unresolved: no documentation states its
  meaning; do not adopt.*
- **Two shrinkage vocabularies.** The parser's `keep_serialized` set contains the `um`-namespace
  key `shrinkage percentage`, used by **0** files; the corpus instead uses
  `cura:material_shrinkage_percentage` (34.9%), `…_z` (17.1%), `…_xy` (0.4%). Only the `cura:`
  form is actually consumed (`BuildVolume.py`, `ConvexHullDecorator.py`).
- **13 parser-supported keys have zero occurrences**, including `hardware recommended`,
  `maximum heated chamber temperature`, `material bed adhesion temperature`,
  `recommend cleaning after n prints` — and the entire `<buildplate>` scope.
- `instruction_link` (36.3%), `reference_material_id` (6.8%), `EAN` (0.4%),
  `cura:pva_compatible` / `cura:breakaway_compatible` (~37%) have **no reader in the Cura source
  tree** at this revision.

---

## 4. Harvest list proposed for Open3DPP (adoption status noted per tier)

**Tier A — true delta (present in Cura, absent from both OFD and the Orca/Prusa family).**
Gate: >20% coverage **or** clear ICME value. Adoption status is marked per row: Tier A was
adopted in full, Tier B only in part, and Tier C in part — see the notes under each table.

| Cura field | Cov. | Proposed Open3DPP name | Type / unit | Why |
|---|---|---|---|---|
| `setting[@key='adhesion tendency']` | 47.0% | `adhesion_tendency_idx` | int 0–4 | ordinal bed-adhesion propensity; Orca's `filament_adhesiveness_category` is a different, incomparable scale |
| `setting[@key='surface energy']` | 44.1% | `surface_energy_pct` | int %, 65/70/100 | surface-energy proxy; nothing equivalent anywhere |
| `metadata/adhesion_info` | 74.0% | `adhesion_note` | str (47 distinct) | first-layer method as stated by the vendor; the element appears in 91.8% of files but is empty in 50 of them |
| `setting[@key='break temperature']` | 36.7% | `break_temperature_c` | float °C, 60–280 | clean-fracture temperature — a thermal-mechanical observable |
| `setting[@key='break preparation temperature']` | 36.7% | `break_preparation_temperature_c` | float °C, 210–320 | pre-conditioning temperature for the same |
| `cura:setting[@key='material_crystallinity']` | 16.4% | `is_semicrystalline` | bool | semi-crystalline vs amorphous — first-order ICME classifier; qualifies on ICME value, not coverage |
| `setting[@key='processing temperature graph']` | 4.6% | `flow_temp_graph` | list[[mm³/s, °C]] | the only constitutive relation in the format; absent from OFD, **but OrcaSlicer has adopted the same key** (`material_flow_temp_graph`), so it is dual-sourced and cheap to populate |

**Tier B — structural harvest (the actual reason we looked).** Not new *fields* but a new *key*.
**Adoption status: partial.** Only `printer_model_reported` was adopted, as a coarse
provenance string. A per-hotend identity column and a tri-state pairing verdict were
*not* adopted: a compatibility matrix has a different cardinality from "one row = one
observation", and the material-side part of that story is carried instead by
`min_nozzle_diameter_mm`, `required_nozzle_hrc` and `is_abrasive`.

| Concept | Proposed name | Note |
|---|---|---|
| `<hotend>@id` | `hotend_id` (str) | new identity column; **must not** be collapsed to `nozzle_diameter_mm` |
| `<machine_identifier>@product` | `printer_product_name` (str) | keep the vendor's human-readable string verbatim alongside our normalised `printer_model`, because that string *is* the join key upstream |
| `hardware compatible` | `pairing_verdict` | enum `compatible \| incompatible \| unknown` — keep `unknown` distinct; Cura conflates it with `compatible`, which is a lossy default we should not inherit |

**Tier C — not novel to Cura** (all have Orca/Prusa equivalents, so they fail the delta
test). **Adoption status: partial** — `standby_temperature_c`, `shrinkage_xy_pct`,
`shrinkage_z_pct`, `is_support_material` and solubility (as `solvent_class`) were adopted;
spool weight was not, being packaging logistics rather than characterization: `standby_temperature_c`
(`standby temperature`, 92.2% / Orca+Prusa `idle_temperature`); `shrinkage_xy_pct` /
`shrinkage_z_pct` (`filament_shrink`, `filament_shrinkage_compensation_z`); `spool_weight_g`
(currently only in `extra_json`); `is_support_material`; `is_soluble`.

**Explicitly not harvested:** the material-station kinematics family (`anti ooze *`, `break
position/speed`, `*purge*`, `no load move factor`, `maximum park duration`, `relative extrusion`,
`flow sensor detection margin`) — Ultimaker-hardware mechanics with no material meaning; and
`retract compensation`, whose meaning is undocumented and unparsed.

---

## 5. Liveness verdict

**Verdict: maintained, not growing — a vendor-internal release artefact, not a living community
database.** Numbers:

- **Corpus growth has stopped.** Material files: 98 (2018) → 231 (2021) → 258 (2023) → 273 (2024) →
  **281 (2025) → 281 (2026)**. Net new files in 2026: **0**.
- **Commit volume** (all commits / commits touching `*.xml.fdm_material`): 2021 153/134 ·
  2022 111/36 · 2023 91/37 · 2024 158/64 · 2025 123/51 · **2026 (to 2026-06-03) 21/4**.
- **Last substantive material change: 2026-05-21** — "Release Factor 4+", "Support BAM on BB core",
  "Remove AA+ 0.6 core". All three are Ultimaker *hardware* enablement; everything after that date
  is CI/version bumps. **Last new material file of any kind: 2025-12-18** (`generic_asa`, again for
  the Ultimaker Factor line). The last outside brands to be added were BASF, Jabil and Polymaker on
  2024-09-30 — and those were committed by Ultimaker/MakerBot staff for their own Method printers.
  **The last material contributed by an outside author was Eazao Clay, 2024-07-24** — one community
  material in the last two years.
- **Contributors 2024-01-01 → now:** 19 distinct commit authors; **11** touched material data, and
  the three most active of those account for **81 of 119** material-file commits. Effective bus
  factor ≈ 3. (Individual contributors are not named here: the aggregate carries the finding.)
- **PR staleness: 21 open PRs, median age 1,453 days (~4.0 years).** 16 older than 1 year, 15
  older than 2 years; the oldest is 2,152 days. Open PRs by year opened: 2020:2, 2021:3, 2022:8,
  2023:2, 2025:1, 2026:5. Merged PRs by year created: 2024:45, 2025:41, **2026:3**. Third-party
  "add my filament" PRs (e.g. #378 FilAr, #275 Eolas, #230 Krei 3D, #222 VOXELPLA) sit unmerged
  for years, so in practice outside contributions are not being merged.

Summary, as of the revision analysed (`886e7ad`, 2026-06-03; PR data retrieved 2026-08-10):
*"Ultimaker's fdm_materials database added no new material files in 2026 and carried 21 open pull
requests with a median age of about four years; its last substantive change, 2026-05-21, was
first-party printer enablement."* These are observations about a specific commit, not a prediction
about the project's future.

---

## 6. Licensing

`fdm_materials/LICENSE` is **CC0 1.0 Universal** (public-domain dedication), and the README states
it plainly: the copyright holder waives all rights to the extent of the law; copy, modify and
distribute freely, **including commercially**, with no attribution requirement.

What the dedication does and does not cover:

- **Reuse and redistribution.** To the extent of the rights each contributor held and dedicated,
  CC0 permits reproduction, adaptation and redistribution, including commercially, and permits the
  result to be released under different terms. CC0 is one-way compatible in that direction.
- **Attribution.** CC0 imposes no attribution condition. Crediting the upstream project is
  nonetheless good practice and is what this analysis does.
- **§4(a) — trademark and patent are NOT waived.** "Ultimaker", "PolyFlex", "GreenTEC Pro",
  print-core designations such as "AA 0.4", and vendor logos remain the marks of their owners; use
  them nominatively, to identify the product, without implying endorsement.
- **§4(b) — no warranty.** The data is offered as-is with no representation of accuracy. The
  `eazao_clay` density stated in kg/m³ in a g/cm³ field is a concrete instance.
- **§4(c) — no rights clearance.** The affirmer expressly disclaims responsibility for clearing
  rights that other persons may hold in the work. The dedication reaches only rights held by the
  contributors themselves, so profiles contributed on behalf of third-party brands carry residual
  clearance risk. That risk is mitigated, but not eliminated, by the fact that the reused content
  is numeric process parameters — facts rather than expression.
- **Source asymmetry.** Cura's fdm_materials is CC0-1.0; the Open Filament Database is MIT; the
  Orca/Prusa-family profile trees are AGPL-3.0/LGPL-3.0-adjacent. A record aggregating several of
  these must retain per-source provenance; Open3DPP does so in the per-row `source_license`
  column, and rows are only republished when every licence involved independently permits it.

---

### Files alongside this report

- `fields.csv` — 132 rows: xpath, scope, type, units (as used and as handled in code),
  occurrences, file coverage %, value range/enum, category, OFD equivalent, Orca/Prusa
  equivalent, harvest flag, notes. Includes parser-supported fields with **zero** corpus
  occurrences. Observed example values are redacted for the `<author>` and `<supplier>`
  contact blocks, which carry personal data.
- Three annotated profiles: `generic_pla` (canonical, all block types, flow-temp graph),
  `ultimaker_petcf` (39 hotends, pure compatibility matrix), `polyflex_pla` (floor of the
  format, no machine scoping).
