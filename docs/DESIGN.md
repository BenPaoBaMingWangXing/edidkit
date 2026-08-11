# Design Notes

## Boundary

`edidkit` is a focused EDID 1.x base block parser and audit toolkit. The first release intentionally avoids OS integration, binary file I/O, DisplayID, and CTA extension parsing so the package remains easy to verify and maintain.

## Pipeline

1. `parse_hex_bytes` normalizes hexadecimal text into an `Array[Int]`.
2. `parse_edid_bytes` validates length and header, then decodes the first 128-byte base block.
3. Descriptor parsing decodes detailed timing descriptors and common monitor descriptor tags.
4. `modes_from_edid` turns detailed, standard, and established timings into normalized `DisplayMode` values.
5. `catalog_match_for_mode` maps normalized modes to known timing entries when possible.
6. `audit_edid_with_profile` applies display profile requirements and combines parser/audit diagnostics.
7. Report functions render stable text, Markdown, and JSON strings.

## Data Model

The data model uses explicit MoonBit structures instead of loosely typed maps. This keeps parser output inspectable in tests and makes downstream tools less dependent on string parsing.

Important structures:

- `Edid`: the complete decoded base block.
- `Descriptor`: one 18-byte descriptor slot.
- `DisplayMode`: normalized timing capability.
- `EdidDiagnostic`: parser or audit finding.
- `EdidAudit`: audit result for one profile.
- `TimingCatalogEntry`: known timing catalog record.
- `ProfileCheck`: profile matrix row.

## Diagnostics

Diagnostics are split into:

- Fatal parse errors: invalid hex, short input, invalid header.
- Recoverable parse diagnostics: checksum mismatch, unsupported major version, ignored extension blocks, unknown descriptors.
- Audit diagnostics: missing detailed timing, missing monitor name, invalid size, profile requirement failure, unsupported interlacing, range-limit inconsistencies.

Severity values are `note`, `warning`, and `error`. The final audit status is:

- `accepted`: no warnings or errors.
- `needs-attention`: warnings but no errors.
- `rejected`: at least one error.

## Timing Normalization

EDID exposes timing capabilities through several fields. `edidkit` normalizes them into one `DisplayMode` representation so callers can query resolution support without knowing which EDID section supplied the mode.

The scoring model favors preferred detailed timings, then larger resolution, higher refresh, and progressive scan. This makes `best_mode` deterministic and simple to explain.

## Timing Catalog

The bundled catalog provides stable IDs for common timing families:

- Established EDID timings.
- DMT-style PC display timings.
- CTA-style UHD video timings.
- CVT and reduced-blanking entries.
- Projector room presets.

The catalog is embedded as MoonBit data so examples and tests do not depend on network or external files.

## Profile Matrix

Display profiles represent target environments:

- Legacy XGA
- Baseline
- Embedded panel
- Desktop
- Full-HD video
- Projector room
- Workstation
- Gaming
- Large format
- UHD video

Each profile checks minimum resolution, minimum refresh, preferred timing presence, interlaced mode policy, and extension block count. This gives a compact compatibility matrix for hardware QA and CI validation.

## Maintainability

The package keeps parsing, mode extraction, catalog matching, audit policy, report rendering, sample data, and command examples in separate files. Tests cover each layer directly and use a self-contained synthetic EDID sample to avoid third-party test fixtures.
