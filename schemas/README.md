# Schemas

Every version of Open3DPP ships its own JSON Schema (Draft 2020-12) under
`core/v<version>/open3dpp-record.schema.json`.

### Core record

| Version | Status | Schema |
|---|---|---|
| v0.1.0 | **current** | [`core/v0.1.0/open3dpp-record.schema.json`](core/v0.1.0/open3dpp-record.schema.json) |

### Applied-System Addendum

Linked sidecars for the applied context a core record deliberately excludes:
equipment, environment, measurement method and external artifacts. Each
references a core record through `core_record_ref` and versions independently,
so a core bump never invalidates a sidecar. See [`../ADDENDUM.md`](../ADDENDUM.md).

| Version | Sidecar | Schema |
|---|---|---|
| v0.1.0 | Applied system | [`addendum/v0.1.0/applied-system-context.schema.json`](addendum/v0.1.0/applied-system-context.schema.json) |
| v0.1.0 | Measurement / outcome | [`addendum/v0.1.0/measurement-outcome-bundle.schema.json`](addendum/v0.1.0/measurement-outcome-bundle.schema.json) |
| v0.1.0 | Artifacts / time series | [`addendum/v0.1.0/artifact-timeseries-manifest.schema.json`](addendum/v0.1.0/artifact-timeseries-manifest.schema.json) |

## There is deliberately no `latest` pointer

Schemas are **version-exact**: each pins `schema_version` with `const` and
rejects unknown properties. A `latest` alias would therefore break every
consumer the moment a new version shipped, because a record declaring the old
version would start failing against a schema that pins the new one. Resolve the
schema from the record's own `schema_version` instead:

```python
import json, urllib.request, jsonschema

record = json.load(open("my-record.json"))
# Resolve the schema named by the record's own schema_version.
url = ("https://open3dpp.org/schemas/core/v%s/open3dpp-record.schema.json"
       % record["schema_version"])
schema = json.load(urllib.request.urlopen(url))
jsonschema.validate(record, schema)
```

Each schema's `$id` is both its identifier and its location: `open3dpp.org` serves this
directory verbatim. A local clone works identically — the bytes are the same, and the release
gate checks that they are.

## Permanence

A published artifact is permanent: it is superseded by a new version, never
rewritten in place and never removed. A consumer that pinned a version must
keep resolving the same bytes.

The release gate enforces this on every publish: each version directory present
must still carry the `$id` and `schema_version` it was released with, and the
current artifact must match the canonical field definition property for
property, including every enum and value assertion.
