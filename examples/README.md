# Example records

One record per `record_kind`, each validated against
[`../schemas/core/v0.1.0/open3dpp-record.schema.json`](../schemas/core/v0.1.0/open3dpp-record.schema.json) before publication.

> **These are illustrative examples, not reference data.** Values are extracted from the
> cited third-party sources and are provided AS IS, with no warranty of accuracy or
> fitness for any purpose. They are not measurements by, or characterizations by,
> Sunnyday Technologies, and they are not an endorsement or assessment of any product.
> Nothing here is printing or engineering advice. See [`../NOTICE`](../NOTICE).

| File | `record_kind` | Shows |
|---|---|---|
| [`measured-specimen.example.json`](measured-specimen.example.json) | `measured_specimen` | A mechanical test result with its provenance, a stated test standard (ISO 527-type tensile). 33 fields populated. |
| [`moisture-response.example.json`](moisture-response.example.json) | `moisture_response` | A fitted property-vs-moisture relation (block M) - neither a settings card nor a single specimen, a stated test standard (ISO 527), a moisture-response slope. 36 fields populated. |
| [`settings-card.example.json`](settings-card.example.json) | `settings_card` | Recommended conditions with no test attached: temperature ranges rather than midpoints, reinforcement content, vendor drying limits. 41 fields populated. |

## Attribution

Every example is restricted to sources whose licence permits republication, and
attribution-conditional sources carry their attribution **inside the record**
(`source`, `doi`, `source_citation`, `source_license`), so a record stays attributed
wherever it travels.

- **`measured-specimen.example.json`** — source `zenodo_8089569`, licence `CC-BY-4.0`, DOI [10.5281/zenodo.8089569](https://doi.org/10.5281/zenodo.8089569). Values were extracted and mapped onto Open3DPP fields — a modification, indicated as CC BY 4.0 section 3(a)(1)(B) requires.
- **`moisture-response.example.json`** — source `pmc_11084188`, licence `CC-BY-4.0`, DOI [10.3390/ma17091988](https://doi.org/10.3390/ma17091988). Values were extracted and mapped onto Open3DPP fields — a modification, indicated as CC BY 4.0 section 3(a)(1)(B) requires.
- **`settings-card.example.json`** — source `ofd`, licence `MIT`.

## Reading the fields

- **Absent means unknown.** A field is omitted rather than zero-filled or guessed.
  Sparse geometry and property blocks are the honest state of the public literature,
  not an encoding artefact.
- **Vendor claims are pass-throughs.** `certifications`, safety-related `trait_tags`,
  `max_dry_temperature_c` and `required_nozzle_hrc` record what a source published.
  They are never inferred and never verified here.
- **Ranges are deliberate.** `min_`/`max_` temperature pairs are preserved instead of a
  midpoint, because the useful value depends on what the analyst is optimising for.
