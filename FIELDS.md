# Open3DPP v0.1.0 — field reference

Generated from the canonical definition (one table: name, type, unit, doc). 
152 columns in 8 blocks. Unknown = NULL, never invented.


## identity (19)

| Column | Type | Unit | Description |
|---|---|---|---|
| `record_id` | str | — | Our stable row id (uuid5 over the record's natural key). |
| `material_uuid` | str | — | OpenPrintTag: deducible from brand_uuid + material_name. |
| `package_uuid` | str | — | OpenPrintTag: the physical package/spool instance. |
| `brand_uuid` | str | — | OpenPrintTag: the brand. |
| `variant_uuid` | str | — | Colour/finish variant identifier, for the variant level OFD models between filament and size. Despite the name it is an OPAQUE identifier, not necessarily a UUID: upstream databases key variants by slug (e.g. 'luminous_blue'), and those are recorded verbatim rather than hashed into a synthetic UUID that would break the join back to the source. |
| `gtin` | str | — | OpenPrintTag key 4 — barcode / free scan-in. |
| `sku` | str | — | Vendor stock code, when the vendor publishes one distinct from GTIN. |
| `brand_name` | str | — | OpenPrintTag key 11 (<=31 chars). |
| `material_name` | str | — | OpenPrintTag key 10 (<=63 chars). |
| `material_abbreviation` | str | — | OpenPrintTag key 52 (<=7) — carries our family when type unspecified. |
| `material_class` | str | — | OpenPrintTag key 8 — 'FFF'. |
| `material_type` | str | — | OpenPrintTag key 9 enum abbreviation, or NULL (unspecified). |
| `material_family` | str | — | Our controlled vocabulary (PLA/PETG/.../OTHER). |
| `color_name` | str | — | Vendor's name for the colour/finish variant. |
| `color_hex` | str | — | A representative '#RRGGBB'. On a variant record it is that variant's colour. On an aggregate settings card it is one deterministically-chosen hex from the material's published variants and is NOT a designated primary — use a variant record when colour matters. |
| `vendor_material_guid` | str | — | NON-AUTHORITATIVE alias: the vendor/slicer-assigned GUID, e.g. the Cura fdm_material GUID element. Vendor-generated, one per profile file, and it folds diameter into identity — never join on it alone. |
| `lifecycle_status` | str | — | active \| discontinued \| unknown (see LIFECYCLE_STATUS). 'unknown' and an absent value mean the same thing; prefer absence, and use 'unknown' only to record that a source was consulted and did not say. Enum: `active` \| `discontinued` \| `unknown`. |
| `record_kind` | str | — | settings_card \| measured_specimen \| moisture_response (see RECORD_KINDS). Enum: `settings_card` \| `measured_specimen` \| `moisture_response`. |
| `schema_version` | str | — | Open3DPP schema version this row conforms to. |

## composition (23)

| Column | Type | Unit | Description |
|---|---|---|---|
| `base_polymer` | str | — | Neat resin designation, e.g. 'PLA', 'PA12'. |
| `filler_type` | str | — | AUTHORITATIVE for reinforcement: CF \| GF \| none \| ... Reinforcement is never restated in trait_tags. |
| `filler_fraction_pct` | float | % | Filler mass fraction. |
| `density_g_cm3` | float | g/cm3 | OpenPrintTag key 29. Filament (not part) density. |
| `glass_transition_c` | float | degC | Tg, from datasheet. A KINETIC relaxation, not a thermodynamic transition: the value depends on method and rate, so keep it with its source and do not compare values obtained by different methods. |
| `melt_temperature_c` | float | degC | Tm — crystalline melt, semi-crystalline grades only. |
| `softening_temperature_c` | float | degC | VENDOR-DECLARED softening / vitrification point (OrcaSlicer temperature_vitrification). Distinct from Tg (thermodynamic) and hdt_c (standard load-deflection test); record whichever the source actually stated, never convert. |
| `is_semicrystalline` | bool | — | Semi-crystalline (True) vs amorphous (False) as stated by a morphology source (datasheet or DSC). NOT a percentage — those are crystallinity_nominal_pct / _measured_pct. NOTE: Cura cura:material_crystallinity is NOT a valid source for this field. It governs filament-break behaviour during material-station unload and is only ever written true, so it can neither express nor evidence amorphousness. |
| `crystallinity_nominal_pct` | float | % | Nominal/datasheet degree of crystallinity. |
| `melt_flow_index_g_10min` | float | g/10min | MFI/MFR. MEANINGLESS without its temperature and load (e.g. 190 degC / 2.16 kg). The schema has no column for them yet: record them in provenance_notes and do not compare values measured under different conditions. |
| `shore_hardness_a` | int | — | OpenPrintTag key 31 (flexibles). |
| `shore_hardness_d` | int | — | OpenPrintTag key 32 (rigids). |
| `surface_energy_pct` | float | % | Vendor-declared surface-energy index (Cura 'surface energy'). Ultimaker-only vocabulary; no OFD or Orca/Prusa equivalent. |
| `adhesion_tendency_idx` | int | — | Ordinal bed-adhesion propensity, 0..4 as published by Cura ('adhesion tendency'). Not comparable to Orca's filament_adhesiveness_category, which is a different scale. |
| `adhesion_note` | str | — | Vendor's free-text first-layer adhesion guidance, verbatim (Cura <adhesion_info>). Never parsed into a setting. |
| `break_temperature_c` | float | degC | Temperature at which the filament fractures cleanly when pulled (Cura 'break temperature'). A thermal-mechanical observable, not a print setting. |
| `break_preparation_temperature_c` | float | degC | Pre-conditioning temperature before the break move (Cura 'break preparation temperature'). |
| `neat_tensile_strength_mpa` | float | MPa | Datasheet intrinsic for the bulk resin (not printed). |
| `neat_modulus_mpa` | float | MPa | Datasheet intrinsic for the bulk resin (not printed). |
| `is_abrasive` | bool | — | Abrades standard brass hardware. Promoted out of trait_tags because it gates hardware selection alongside required_nozzle_hrc. |
| `is_support_material` | bool | — | Intended as a support/interface material (Cura material_is_support_material, Orca filament_is_support). Independent of solubility — breakaway supports are insoluble. |
| `solvent_class` | str | — | Dissolution medium: water \| ipa \| limonene \| other. NULL means insoluble/unknown, so no separate is_soluble flag. Enum: `water` \| `ipa` \| `limonene` \| `other`. |
| `trait_tags` | list[str] | — | Controlled non-filler, non-promoted traits (optical, functional, safety, end-of-life). See TRAIT_TAGS and PROMOTED_TRAITS — a trait appears in exactly one place. Safety and functional tags record a claim published by the source or vendor verbatim; they are never inferred, tested or verified here, and carrying one is not a representation of fitness for any purpose. |

## process (37)

| Column | Type | Unit | Description |
|---|---|---|---|
| `min_print_temperature_c` | float | degC | OpenPrintTag key 34 — nozzle range low. |
| `max_print_temperature_c` | float | degC | OpenPrintTag key 35 — nozzle range high, as published by the source. |
| `print_temperature_c` | float | degC | Chosen/consensus nozzle point (goal-neutral). |
| `min_bed_temperature_c` | float | degC | OpenPrintTag key 37. |
| `max_bed_temperature_c` | float | degC | OpenPrintTag key 38. |
| `bed_temperature_c` | float | degC | Chosen/consensus bed point. Present for symmetry with print_temperature_c; the range columns remain authoritative. |
| `min_chamber_temperature_c` | float | degC | Chamber range low. v0.1 stored chamber as a bare point, which broke the schema's own range rule; both are now available. |
| `max_chamber_temperature_c` | float | degC | Chamber range high. |
| `chamber_temperature_c` | float | degC | OpenPrintTag key 41 — chosen/ideal chamber point. The Orca/Bambu family writes 0 to mean 'no chamber / unset'; that sentinel is dropped at ingest rather than published as an ideal 0 degC chamber. |
| `preheat_temperature_c` | float | degC | OpenPrintTag key 36. |
| `first_layer_print_temperature_c` | float | degC | Nozzle temperature for the FIRST layer, which vendors commonly raise above the bulk value for adhesion. Distinct from print_temperature_c; absent means the source stated one temperature, not that the two are equal. |
| `first_layer_bed_temperature_c` | float | degC | Bed temperature for the FIRST layer, commonly raised above the bulk value. Distinct from bed_temperature_c; absent means the source stated one temperature. |
| `standby_temperature_c` | float | degC | Idle/standby nozzle temperature during tool changes (Cura 'standby temperature', Orca/Prusa idle_temperature). |
| `flow_temp_graph` | list[list[float]] | [[mm3/s,degC]] | Required nozzle temperature as a FUNCTION of volumetric flow, as [[flow, temp], ...]. The only constitutive relation carried by consumer formats (Cura 'processing temperature graph', OrcaSlicer material_flow_temp_graph). The curve is machine-scoped upstream and is NOT bounded by min/max_print_temperature_c — it routinely extends past both ends, so the two must not be reconciled against each other. |
| `nozzle_diameter_mm` | float | mm | As-run nozzle diameter. |
| `min_nozzle_diameter_mm` | float | mm | MATERIAL-SIDE REQUIREMENT: smallest nozzle the vendor supports (filled/abrasive grades). A constraint, not an as-run value. |
| `required_nozzle_hrc` | float | — | MATERIAL-SIDE REQUIREMENT: vendor-declared minimum nozzle hardness, from OrcaSlicer/Bambu required_nozzle_HRC, recorded verbatim. CAVEAT: observed upstream values cluster at 0/3 for unfilled grades and 30/40 for filled ones; the low values are not meaningful Rockwell C hardnesses (the scale is not used below ~20 HRC) and behave as an upstream sentinel for "no special nozzle required". Treat as a vendor code, unvalidated. |
| `filament_diameter_mm` | float | mm | OpenPrintTag key 30 (default 1.75). |
| `filament_diameter_tolerance_mm` | float | mm | Stated +/- diameter tolerance. Bounds the achievable flow accuracy, so it belongs beside the diameter it qualifies. |
| `layer_height_mm` | float | mm | As-run layer height. |
| `line_width_mm` | float | mm | As-run extrusion width. |
| `print_speed_mm_s` | float | mm/s | As-run print speed. |
| `flow_ratio` | float | — | Extrusion multiplier (1.0 = 100%). |
| `max_volumetric_speed_mm3_s` | float | mm3/s | Vendor/slicer volumetric flow ceiling. |
| `pressure_advance` | float | — | Pressure-advance / linear-advance factor. |
| `fan_min_pct` | float | % | Part-cooling fan floor. |
| `fan_max_pct` | float | % | Part-cooling fan ceiling. |
| `shrinkage_xy_pct` | float | % | In-plane shrinkage compensation, 100 = no shrink (Cura cura:material_shrinkage_percentage(_xy), Orca/Prusa filament_shrink). First-order dimensional property. |
| `shrinkage_z_pct` | float | % | Through-thickness shrinkage compensation, 100 = no shrink. |
| `infill_density_pct` | float | % | As-run infill density. |
| `infill_pattern` | str | — | As-run infill pattern. |
| `wall_count` | int | — | Perimeter count; walls carry most load at low infill. |
| `retraction_mm` | float | mm | Retraction distance. |
| `retraction_speed_mm_s` | float | mm/s | Retraction speed. |
| `drying_temperature_c` | float | degC | OpenPrintTag key 57 — drying AS PERFORMED for this observation. The vendor-published limit is max_dry_temperature_c (block M). |
| `drying_time_min` | float | min | OpenPrintTag key 58 — drying time as performed. |
| `printer_model_reported` | str | — | Coarse printer identity EXACTLY as the source reported it. This is provenance-grade text, not an equipment record: the exact system, its components, calibration and environment live in the Applied-System Addendum, which links here via core_record_ref. |

## geometry (18)

| Column | Type | Unit | Description |
|---|---|---|---|
| `specimen_standard` | str | — | ISO 527-2 \| ASTM D638 \| ... |
| `specimen_geometry` | str | — | 1A \| 1BA \| Type IV \| cube \| prism \| as-part. |
| `specimen_length_mm` | float | mm | Overall specimen length. |
| `specimen_width_mm` | float | mm | Overall specimen width. |
| `specimen_thickness_mm` | float | mm | Overall specimen thickness. |
| `gauge_cross_section_mm2` | float | mm2 | Load-bearing cross-section at the gauge. |
| `nominal_wall_thickness_mm` | float | mm | Designed wall thickness of the printed shell. |
| `skin_thickness_mm` | float | mm | Solid top/bottom skin per side. On thin coupons the skins dominate the solid shell ring (0.8 mm skins on a 3.2 mm D638 bar = 50% of the thickness), so it is not derivable from wall thickness. |
| `min_feature_size_mm` | float | mm | Smallest printed feature. |
| `part_height_mm` | float | mm | Build height. |
| `num_layers` | int | — | Layer count. |
| `layer_time_s` | float | s | Per-layer dwell -> interlayer healing window. |
| `toolpath_length_mm` | float | mm | Proxy for layer_time when time is not reported. |
| `characteristic_length_mm` | float | mm | Thermal-mass proxy (V/A). |
| `build_orientation_code` | str | — | X \| Y \| Z \| XY_45 (load vs layers). Enum: `X` \| `Y` \| `Z` \| `XY_45`. |
| `print_orientation` | str | — | flat \| on_edge \| upright. Enum: `flat` \| `on_edge` \| `upright`. |
| `raster_angle_deg` | float | deg | Raster/infill angle relative to the load axis. |
| `is_standard_coupon` | bool | — | Standard test coupon (True) vs real-part geometry (False). NULL when the source does not say — absence of a named standard is not evidence of a non-standard specimen. |

## structure (8)

| Column | Type | Unit | Description |
|---|---|---|---|
| `part_density_g_cm3` | float | g/cm3 | AS-PRINTED part density (not the filament density in block B). The direct observable of infill x flow x (1 - void); when a source reports it, it supersedes every inferred estimate. relative_density_pct and void_fraction_pct are derivable from it given the fully-dense reference. |
| `relative_density_pct` | float | % | Part / fully-dense, when a source reports it that way. |
| `void_fraction_pct` | float | % | Porosity. Complement of relative_density_pct; store whichever the source stated and do not back-fill the other. |
| `degree_of_healing` | float | — | 0..1 interlayer weld/reptation completeness. |
| `interlayer_bond_quality` | str | — | Qualitative interlayer assessment when no number exists. |
| `crystallinity_measured_pct` | float | % | Measured (DSC/XRD) degree of crystallinity for this specimen. |
| `fiber_alignment_factor` | float | — | 0..1 fibre alignment with the load axis. |
| `surface_roughness_ra_um` | float | um | Arithmetic mean roughness Ra. |

## properties (17)

| Column | Type | Unit | Description |
|---|---|---|---|
| `tensile_strength_mpa` | float | MPa | Ultimate tensile strength. On a moisture_response record this is the FITTED dry intercept of the regression, not a value measured on any one specimen — read it with measurement_confidence and record_kind. |
| `tensile_strength_stddev_mpa` | float | MPa | Standard deviation of tensile_strength_mpa. |
| `tensile_modulus_mpa` | float | MPa | Young's modulus in tension. |
| `tensile_modulus_stddev_mpa` | float | MPa | Standard deviation of tensile_modulus_mpa. |
| `elongation_at_break_pct` | float | % | Strain at break. |
| `elongation_at_break_stddev_pct` | float | % | Standard deviation of elongation_at_break_pct. |
| `flexural_strength_mpa` | float | MPa | Flexural strength. |
| `flexural_strength_stddev_mpa` | float | MPa | Standard deviation of flexural_strength_mpa. |
| `flexural_modulus_mpa` | float | MPa | Flexural modulus. |
| `flexural_modulus_stddev_mpa` | float | MPa | Standard deviation of flexural_modulus_mpa. |
| `impact_strength_kj_m2` | float | kJ/m2 | Charpy/Izod impact strength. |
| `impact_strength_stddev_kj_m2` | float | kJ/m2 | Standard deviation of impact_strength_kj_m2. |
| `interlayer_bond_strength_mpa` | float | MPa | Z-direction (interlayer) tensile strength — the property most sensitive to thermal history. |
| `interlayer_bond_strength_stddev_mpa` | float | MPa | Standard deviation of interlayer_bond_strength_mpa. |
| `hdt_c` | float | degC | Heat-deflection temperature. MEANINGLESS without its load and standard (commonly 0.45 or 1.80 MPa; ISO 75 / ASTM D648). The schema has no column for them yet: record them in provenance_notes and do not compare across sources. |
| `hdt_stddev_c` | float | degC | Standard deviation of hdt_c. |
| `n_specimens` | int | — | Replicates behind the values in this row. |

## moisture (11)

| Column | Type | Unit | Description |
|---|---|---|---|
| `hygroscopic_class` | str | — | low \| moderate \| high (see HYGROSCOPIC_CLASS). A compact categorical summary of moisture sensitivity, recorded ONLY when a source states it — it is never derived from family, drying temperature or measured uptake. RESERVED: no current source states it, so the reference implementation leaves it NULL in every record. Enum: `low` \| `moderate` \| `high`. |
| `max_dry_temperature_c` | float | degC | Vendor-published maximum drying temperature (OFD max_dry_temperature, falling back to the material-family default when the product states none; the lowest stated value wins), recorded as published and NOT verified. Distinct from process drying_temperature_c, which is what was actually done. Follow the manufacturer's drying instructions; exceeding them can damage material or equipment. |
| `filament_moisture_pct` | float | % | As-tested filament moisture content by mass. |
| `filament_moisture_min_pct` | float | % | Low end of the conditioned moisture range in this study. |
| `filament_moisture_max_pct` | float | % | High end of the conditioned moisture range in this study. |
| `moisture_conditioning_path` | str | — | How the moisture state was reached, verbatim (e.g. 'dried then humidity-conditioned'). |
| `moisture_uptake_t80_h` | float | h | Hours at ambient to reach 80% of equilibrium uptake. |
| `dtensile_mpa_per_pct_moisture` | float | MPa/% | SIGNED regression slope of tensile strength against moisture content — negative when strength falls, which is the usual case. Compare strength_loss_per_pct_moisture, which is the positive normalised magnitude of the same effect. |
| `dmodulus_gpa_per_pct_moisture` | float | GPa/% | SIGNED regression slope of modulus against moisture content (negative when modulus falls). |
| `strength_loss_per_pct_moisture` | float | 1/% | POSITIVE magnitude of the relative strength loss per percentage point of moisture, referenced to the dry intercept: a FRACTION per percent, not percent per percent. 0.47 means 47% of dry strength lost per 1 wt% moisture. Model: sigma(w) = sigma0 * (1 - loss * w). |
| `moisture_response_r` | float | — | Correlation coefficient of the reported moisture fit. |

## provenance (19)

| Column | Type | Unit | Description |
|---|---|---|---|
| `source` | str | — | Dataset / repo / paper key. Comma-separated when a record aggregates several sources — split on ',' before matching. |
| `doi` | str | — | DOI of the source publication. |
| `source_citation` | str | — | Human-readable citation. |
| `source_license` | str | — | SPDX identifier of the source licence. When a record aggregates several upstream databases this is a comma-separated, sorted list of every SPDX id involved (e.g. 'AGPL-3.0-only,MIT') — split on ',' before matching. Unrecognised upstream strings become SPDX 'LicenseRef-' identifiers rather than being dropped. |
| `technical_data_sheet_url` | str | — | Vendor TDS. Distinct from doi/source_citation: a vendor spec sheet is the primary evidence for datasheet-derived intrinsics. |
| `safety_data_sheet_url` | str | — | Vendor SDS/MSDS. |
| `certifications` | list[str] | — | Certification or compliance claims exactly as published by the source (e.g. "UL94 V-0", "ISO 10993-5", "EU 10/2011"). Never inferred from composition. Marketing phrases with no named scheme ("food-safe", "medical-grade") are preserved verbatim but are vendor claims, not certifications. |
| `lab_name` | str | — | Testing laboratory, when stated. |
| `measurement_confidence` | str | — | measured \| calculated \| estimated \| reported (see MEASUREMENT_CONFIDENCE). Enum: `measured` \| `calculated` \| `estimated` \| `reported`. |
| `n_sources` | int | — | Number of independent sources that agree on this record's values. |
| `has_permissive_source` | bool | — | At least one permissively-licensed source backs this row. |
| `is_training_ready` | bool | — | Row is eligible for the MEASURED-property training set: it carries an observation (not recommended settings) under a verified, redistributable licence with attribution where the licence requires it. Settings cards are False by construction — they are recommendations, not measurements. A workflow flag, not a warranty of accuracy. |
| `is_synthetic` | bool | — | Row was generated rather than observed. |
| `outlier_flag` | bool | — | Flagged as an outlier by a publisher's QA pass. RESERVED: the reference implementation runs no outlier detection, so this is NULL in every record it emits. A NULL means 'not assessed', never 'assessed and clean'. |
| `raw_data_doi` | str | — | DOI of the underlying raw dataset, when separate. |
| `stress_strain_file` | str | — | Pointer to a raw stress-strain artifact. |
| `record_revision` | int | — | Monotonic revision of this record. Mirrors the addendum sidecars, which all carry revision + created_at. |
| `record_created_at` | date | — | ISO-8601 date this record revision was emitted. |
| `provenance_notes` | str | — | Free-text caveats. |

## Controlled trait vocabulary (`trait_tags`)

`translucent` · `transparent` · `matte` · `silk` · `glitter` · `iridescent` · `pearlescent` · `neon` · `glow` · `without_pigments` · `temperature_color_change` · `gradual_color_change` · `coextruded` · `illuminescent_color_change` · `imitates_wood` · `imitates_metal` · `imitates_marble` · `imitates_stone` · `lithophane` · `esd_safe` · `conductive` · `emi_shielding` · `paramagnetic` · `radiation_shielding` · `air_filtering` · `antibacterial` · `biocompatible` · `self_extinguishing` · `high_temperature` · `high_flow` · `low_outgassing` · `foaming` · `castable` · `blend` · `recycled` · `recyclable` · `biodegradable` · `home_compostable` · `industrially_compostable` · `bio_based` · `filtration_recommended` · `limited_edition`

Traits promoted to typed columns (never valid inside `trait_tags`): `abrasive` → `is_abrasive`, `contains_carbon_fiber` → `filler_type`, `contains_carbon_nano_tubes` → `filler_type`, `contains_glass_fiber` → `filler_type`, `contains_kevlar` → `filler_type`, `ipa_soluble` → `solvent_class`, `limonene_soluble` → `solvent_class`, `water_soluble` → `solvent_class`
