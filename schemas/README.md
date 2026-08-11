# Schemas

Every version of Open3DPP ships its own JSON Schema (Draft 2020-12) under
`core/v<version>/open3dpp-record.schema.json`.

| Version | Status | Schema |
|---|---|---|
| v0.1.0 | **current** | [`core/v0.1.0/open3dpp-record.schema.json`](core/v0.1.0/open3dpp-record.schema.json) |

## There is deliberately no `latest` pointer

Schemas are **version-exact**: each pins `schema_version` with `const` and
rejects unknown properties. A `latest` alias would therefore break every
consumer the moment a new version shipped, because a record declaring the old
version would start failing against a schema that pins the new one. Resolve the
schema from the record's own `schema_version` instead:

```python
import json, urllib.request, jsonschema

record = json.load(open("my-record.json"))
# Resolve from the release tag matching the record's own schema_version. Tags
# are immutable, so a pinned record keeps resolving the same bytes.
url = ("https://raw.githubusercontent.com/sunnyday-technologies/Open3DPP"
       "/v{v}/schemas/core/v{v}/open3dpp-record.schema.json").format(
           v=record["schema_version"])
schema = json.load(urllib.request.urlopen(url))
jsonschema.validate(record, schema)
```

The `$id` inside each schema (`https://open3dpp.org/schemas/core/v<version>/…`) is the stable
identifier for that schema. It is **not currently served** — hosting is configured but not yet
deployed — so resolve schemas from this repository, as above.

## Permanence

A published artifact is permanent: it is superseded by a new version, never
rewritten in place and never removed. A consumer that pinned a version must
keep resolving the same bytes.

The release gate enforces this on every publish: each version directory present
must still carry the `$id` and `schema_version` it was released with, and the
current artifact must match the canonical field definition property for
property, including every enum and value assertion.
