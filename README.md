# edidkit

`edidkit` is a MoonBit native toolkit for parsing, normalizing, auditing, and reporting EDID monitor identification data.

Package: `BenPaoBaMingWangXing/edidkit`  
Repository: `https://github.com/BenPaoBaMingWangXing/edidkit`  
Mooncakes: `https://mooncakes.io/docs/BenPaoBaMingWangXing/edidkit`  
License: MIT

## Purpose

EDID is the data block that a monitor, embedded panel, projector, capture device, or display emulator exposes to describe its identity and supported timings. Driver bring-up, board validation, display QA, firmware testing, KVM compatibility checks, and hardware debugging often need a small parser that can run in a deterministic build environment.

`edidkit` provides that parser in MoonBit. The package focuses on the EDID 1.x base block and keeps a clear boundary: it decodes the base 128-byte block, validates checksum/header/length, extracts display identity and timing data, normalizes display modes, matches common DMT/CTA/CVT/reduced-blanking/projector timing entries, and produces human-readable or machine-readable audit reports.

## Features

- Parse EDID hex strings with spaces, colons, commas, dashes, and underscores.
- Parse EDID bytes into a typed `Edid` value.
- Validate base block length, header, checksum, and version.
- Decode manufacturer ID, product code, serial number, manufacture date, EDID version, digital/analog video input, physical size, gamma, feature flags, chromaticity, established timings, standard timings, detailed timing descriptors, monitor name, serial text, and range limits.
- Extract normalized display modes from detailed, standard, and established timing data.
- Pick preferred/best modes and query resolution or refresh support.
- Match decoded modes against a bundled timing catalog.
- Audit EDID data with baseline, embedded panel, desktop, full-HD video, projector, workstation, gaming, large-format, and UHD profiles.
- Render text, Markdown, and JSON reports.
- Provide runnable examples and MoonBit tests.

## Install

Install from Mooncakes:

```bash
moon add BenPaoBaMingWangXing/edidkit
```

Use it from another package with a MoonBit import alias such as `@edidkit`.

## Quick Start

Run the bundled parser example:

```bash
moon run cmd/main
```

Run the bundled audit example:

```bash
moon run cmd/audit
```

Expected output includes the decoded identity, monitor name, preferred display mode, matched timing catalog entries, audit status, and Markdown report table.

## API Example

```moonbit
match @edidkit.parse_edid_hex(@edidkit.sample_edid_hex()) {
  Ok(edid) => {
    println(@edidkit.edid_to_text(edid))
    let audit = @edidkit.audit_edid_with_profile(
      edid,
      @edidkit.DisplayProfile::desktop(),
    )
    println(@edidkit.audit_to_json(audit))
  }
  Err(err) => println(err.message)
}
```

## Main API Groups

- Parsing: `parse_hex_bytes`, `parse_edid_hex`, `parse_edid_bytes`
- Samples: `sample_edid_hex`, `sample_edid`, `sample_audit`
- EDID helpers: `Edid::identity`, `Edid::version_text`, `Edid::checksum_valid`, `Edid::monitor_name`, `Edid::preferred_timing`, `Edid::display_class`
- Mode extraction: `modes_from_edid`, `preferred_mode`, `best_mode`, `modes_at_least`, `modes_by_resolution`, `supports_resolution`, `supports_mode`, `max_refresh_for_resolution`, `has_interlaced_modes`
- Timing catalog: `timing_catalog`, `catalog_entries_by_family`, `catalog_entries_by_resolution`, `find_catalog_entry`, `catalog_match_for_mode`, `catalog_matches_for_edid`, `highest_catalog_mode`
- Auditing: `audit_edid`, `audit_edid_with_profile`, `summarize_audit`, `DisplayProfile::baseline`, `DisplayProfile::desktop`, `DisplayProfile::embedded_panel`, `DisplayProfile::large_format`
- Profile matrix: `standard_display_profiles`, `profile_matrix`, `check_profile`, `best_profile_match`, `accepted_profiles`, `rejected_profiles`
- Rendering: `edid_to_text`, `audit_to_text`, `modes_to_text`, `modes_to_markdown`, `audit_to_markdown`, `profile_matrix_to_markdown`, `edid_to_json`, `audit_to_json`

More details are in `docs/API.md`.

## Validation

Local validation commands:

```bash
moon check
moon build
moon test
moon run cmd/main
moon run cmd/audit
moon package
```

The repository also contains GitHub Actions CI at `.github/workflows/ci.yml`. The CI runs check, build, test, examples, and package verification on push and pull request.

## Scope and Boundaries

Implemented:

- EDID 1.x base block parsing and validation.
- Descriptor decoding for detailed timing, monitor name, serial text, generic text, range limits, empty descriptors, and unknown descriptors.
- Display mode normalization and timing catalog matching.
- Profile-based audit and report generation.

Outside the version `0.1.2` boundary:

- CTA-861 extension block parsing.
- DisplayID block parsing.
- OS display driver integration.
- Binary file I/O helpers.
- Web protocol tooling, subtitle parsing, license scanning, SBOM generation, or unrelated protocol tooling.

## Mooncakes Collision Check

On 2026-08-18, all 1,974 entries returned by the Mooncakes public module API were checked for EDID, DisplayID, VESA, DMT, CTA, monitor identification, monitor timing, and display timing. No existing Mooncakes package with the same project boundary was found. Nearby keyword matches were unrelated categories such as text layout, regular expression, dotenv, or noise generation.

The detailed check record is in `docs/MOONCAKES_CHECK.md`.

## Project Type

This is an original MoonBit open-source library. It is not a port of an existing library. The bundled synthetic EDID sample is self-contained test data created for examples and tests.

## License and Compliance

The project is released under the MIT License. The source code is written for this package and does not include third-party source code, private code, closed-source code, commercial code, images, binary assets, or copied documentation. The only declared external package import is MoonBit core test support for tests.

## Hackathon Materials

- API documentation: `docs/API.md`
- Design notes: `docs/DESIGN.md`
- Acceptance checklist: `docs/ACCEPTANCE_CHECKLIST.md`
- Mooncakes collision check: `docs/MOONCAKES_CHECK.md`
- Test record: `docs/TEST_RECORD.md`
- Development log: `docs/DEVELOPMENT_LOG.md`
- Changelog: `CHANGELOG.md`
