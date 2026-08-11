# Crosswalk — arriving from a format you already have

You almost certainly have this data already, in a slicer profile or a filament
database. This page maps those fields onto Open3DPP columns so you can start from
what you have rather than from a blank record.

**Every row below is generated from the reference implementation that performs the
mapping**, and annotated with how many published records the mapping actually
populates. A hand-written crosswalk drifts into fiction; this one fails to build if
it names a column the schema does not have, and its counts come from the emitted
corpus rather than from intent.

> Counts are from the reference corpus of 4058 records. A count of 0 means the mapping
> exists but no source in that corpus states the field — not that it is unsupported.

## Cura `fdm_material` XML

| Source field | Open3DPP column | Records populated | How |
|---|---|--:|---|
| `<name><brand>` | `brand_name` | 3,955 | direct |
| `<name><material>` + `<label>` | `material_name` | 3,955 | direct |
| `<name><color>` | `color_name` | 2,024 | direct |
| `<GUID>` | `vendor_material_guid` | 270 | direct |
| `<color_code>` | `color_hex` | 2,159 | direct |
| `<properties><density>` | `density_g_cm3` | 3,683 | direct |
| `<properties><diameter>` | `filament_diameter_mm` | 3,689 | direct |
| `setting[print temperature]` | `print_temperature_c` | 3,601 | direct |
| `setting[heated bed temperature]` | `bed_temperature_c` | 3,491 | direct |
| `setting[build volume temperature]` | `chamber_temperature_c` | 345 | direct |
| `setting[retraction amount]` | `retraction_mm` | 775 | direct |
| `setting[retraction speed]` | `retraction_speed_mm_s` | 335 | direct |
| `setting[print cooling]` | `fan_min_pct / fan_max_pct` | 50 | direct |
| `cura:material_print_temperature_layer_0` | `first_layer_print_temperature_c` | 1,826 | direct |
| `cura:material_flow` | `flow_ratio` | 1,720 | direct |
| `<EAN>` | `gtin` | 1 | direct |
| `adhesion tendency` | `adhesion_tendency_idx` | 127 | rollup (`mode`) |
| `adhesion_info` | `adhesion_note` | 197 | rollup (`first`) |
| `break preparation temperature` | `break_preparation_temperature_c` | 103 | rollup (`mode`) |
| `break temperature` | `break_temperature_c` | 103 | rollup (`mode`) |
| `cura:material_is_support_material` | `is_support_material` | 907 | rollup (`any_true`) |
| `cura:material_shrinkage_percentage_xy` | `shrinkage_xy_pct` | 731 | rollup (`mode`) |
| `cura:material_shrinkage_percentage_z` | `shrinkage_z_pct` | 217 | rollup (`mode`) |
| `cura:material_shrinkage_percentage` | `shrinkage_xy_pct` | 731 | rollup (`mode`) |
| `guid` | `vendor_material_guid` | 270 | rollup (`first`) |
| `standby temperature` | `standby_temperature_c` | 246 | rollup (`mode`) |
| `surface energy` | `surface_energy_pct` | 119 | rollup (`mode`) |

## Open Filament Database (OFD)

| Source field | Open3DPP column | Records populated | How |
|---|---|--:|---|
| `brand.json` `name` | `brand_name` | 3,955 | direct |
| `filament.json` `name` | `material_name` | 3,955 | direct |
| `variant.json` `name` | `color_name` | 2,024 | direct |
| `variant.json` `color_hex` | `color_hex` | 2,159 | direct |
| `filament.json` `density` | `density_g_cm3` | 3,683 | direct |
| `sizes.json` `diameter` | `filament_diameter_mm` | 3,689 | direct |
| `sizes.json` `gtin` | `gtin` | 1 | direct |
| `min_print_temperature` | `min_print_temperature_c` | 3,299 | direct |
| `max_print_temperature` | `max_print_temperature_c` | 3,299 | direct |
| `min_bed_temperature` | `min_bed_temperature_c` | 3,272 | direct |
| `max_bed_temperature` | `max_bed_temperature_c` | 3,272 | direct |
| `slicer_settings.*.nozzle_temp` | `print_temperature_c` | 3,601 | direct |
| `slicer_settings.*.bed_temp` | `bed_temperature_c` | 3,491 | direct |
| `slicer_settings.*.first_layer_nozzle_temp` | `first_layer_print_temperature_c` | 1,826 | direct |
| `slicer_settings.*.first_layer_bed_temp` | `first_layer_bed_temperature_c` | 1,823 | direct |
| `color_hex` | `color_hex` | 2,159 | rollup (`first`) |
| `data_sheet_url` | `technical_data_sheet_url` | 164 | rollup (`first`) |
| `diameter_tolerance` | `filament_diameter_tolerance_mm` | 1,998 | rollup (`mode`) |
| `gtin` | `gtin` | 1 | rollup (`first`) |
| `material_default_max_dry_temperature` | `max_dry_temperature_c` | 208 | rollup (`min_of`) |
| `max_chamber_temperature` | `max_chamber_temperature_c` | 16 | rollup (`max_of`) |
| `max_dry_temperature` | `max_dry_temperature_c` | 208 | rollup (`min_of`) |
| `min_chamber_temperature` | `min_chamber_temperature_c` | 19 | rollup (`min_of`) |
| `min_nozzle_diameter` | `min_nozzle_diameter_mm` | 14 | rollup (`max_of`) |
| `preheat_temperature` | `preheat_temperature_c` | 19 | rollup (`mode`) |
| `safety_sheet_url` | `safety_data_sheet_url` | 139 | rollup (`first`) |
| `shore_hardness_a` | `shore_hardness_a` | 6 | rollup (`mode`) |
| `shore_hardness_d` | `shore_hardness_d` | 0 | rollup (`mode`) |
| `sku` | `sku` | 0 | rollup (`first`) |
| `variant_id` | `variant_uuid` | 1,904 | rollup (`first`) |

## OrcaSlicer / Bambu Studio / PrusaSlicer

| Source field | Open3DPP column | Records populated | How |
|---|---|--:|---|
| `filament_vendor` | `brand_name` | 3,955 | direct |
| `filament_settings_id` / `name` | `material_name` | 3,955 | direct |
| `filament_type` | `material_family` | 4,058 | direct |
| `filament_density` | `density_g_cm3` | 3,683 | direct |
| `filament_diameter` | `filament_diameter_mm` | 3,689 | direct |
| `nozzle_temperature` / `temperature` | `print_temperature_c` | 3,601 | direct |
| `hot_plate_temp` / `bed_temperature` | `bed_temperature_c` | 3,491 | direct |
| `nozzle_temperature_initial_layer` / `first_layer_temperature` | `first_layer_print_temperature_c` | 1,826 | direct |
| `filament_max_volumetric_speed` | `max_volumetric_speed_mm3_s` | 1,707 | direct |
| `filament_retraction_length` | `retraction_mm` | 775 | direct |
| `filament_flow_ratio` / `extrusion_multiplier` | `flow_ratio` | 1,720 | direct |
| `temperature_vitrification` | `softening_temperature_c` | 1,322 | direct |
| `filament_cost` | `— (not carried: commercial, not characterization)` | — | **not carried** |
| `filament_is_support` | `is_support_material` | 907 | rollup (`any_true`) |
| `filament_shrink` | `shrinkage_xy_pct` | 731 | rollup (`mode`) |
| `filament_shrinkage_compensation_z` | `shrinkage_z_pct` | 217 | rollup (`mode`) |
| `required_nozzle_HRC` | `required_nozzle_hrc` | 902 | rollup (`max_of`) |

## How the rollup rules resolve disagreement

A settings card aggregates every source that describes the same product, so two
sources can disagree. The rule is chosen so nothing is invented:

| Rule | Meaning | Why |
|---|---|---|
| `min_of` | the lowest stated value wins | a drying ceiling must satisfy every source |
| `max_of` | the highest stated value wins | a hardware requirement is a constraint |
| `mode` | the most-stated value, ties by value | declared constants, not measurements |
| `any_true` | asserted by any source | traits are assert-only upstream |
| `first` | first non-empty, sorted | deterministic, for free text and URLs |

Composition claims (`filler_type`, `is_abrasive`) require **unanimity** across a
product's variants: one aramid-filled colour must not label the whole product line.

## What does not cross over

Some fields have no Open3DPP column on purpose, not by omission:

- **Slicer mechanics** — purge, park, anti-ooze, wipe, ramming, G-code. Machine
  behaviour, not material characterization.
- **Commercial fields** — price, stock, purchase links. Not characterization.
- **Compatibility matrices** — Cura's `<machine>`/`<hotend>` scoping is a different
  cardinality from "one row = one observation". The material-side part of that story
  is carried by `min_nozzle_diameter_mm`, `required_nozzle_hrc` and `is_abrasive`.
- **Equipment and environment** — carried by the
  [Applied-System Addendum](ADDENDUM.md) sidecars, not the core record.

## Something missing?

If a field you need has no column, that is a gap worth reporting rather than a
reason to bend an existing column. **Anyone can propose one through GitHub** — open a
[field proposal](https://github.com/sunnyday-technologies/Open3DPP/issues/new?template=field-proposal.md)
and say what observation cannot be recorded today and which source would populate it.
Corrections to a mapping on this page use the
[correction template](https://github.com/sunnyday-technologies/Open3DPP/issues/new?template=data-correction.md).
Both are read; see [CONTRIBUTING.md](CONTRIBUTING.md) for how a change lands.
