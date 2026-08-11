# API Reference

This document summarizes the public API of `BenPaoBaMingWangXing/edidkit`.

## Parsing

### `parse_hex_bytes(input : String) -> Result[Array[Int], EdidError]`

Parses hexadecimal text into bytes. Spaces, colons, commas, dashes, and underscores are accepted as separators. Invalid characters and odd-length hex input return `EdidError`.

### `parse_edid_hex(input : String) -> Result[Edid, EdidError]`

Parses an EDID hex string and returns a typed `Edid` value.

### `parse_edid_bytes(data : Array[Int]) -> Result[Edid, EdidError]`

Parses EDID bytes. Inputs shorter than 128 bytes or without the EDID base header are rejected. The parser records checksum, version, descriptor, and extension-block diagnostics inside the returned `Edid`.

## Core Types

- `Edid`: decoded EDID base block.
- `EdidError`: fatal parse error.
- `EdidDiagnostic`: recoverable parser or audit diagnostic.
- `ManufacturerId`: EISA manufacturer ID.
- `ManufactureDate`: week/year or model-year field.
- `VideoInput`: digital/analog input details.
- `BasicDisplay`: physical size, gamma, and feature flags.
- `Chromaticity`: color coordinates scaled by 10000.
- `EstablishedTiming`, `StandardTiming`, `DetailedTimingInfo`: timing fields.
- `DisplayMode`: normalized display mode.
- `TimingCatalogEntry`: known timing catalog entry.
- `Descriptor`: one 18-byte EDID descriptor slot.
- `DisplayProfile`: audit policy.
- `EdidAudit`: audit result.
- `ProfileCheck`: one row in a profile matrix.

## EDID Helpers

- `Edid::identity() -> String`: returns `MANUFACTURER-productCode`.
- `Edid::version_text() -> String`: returns the EDID version text.
- `Edid::checksum_valid() -> Bool`: checks base block checksum.
- `Edid::monitor_name() -> String?`: returns monitor name descriptor text when present.
- `Edid::preferred_timing() -> DetailedTimingInfo?`: returns the first detailed timing descriptor.
- `Edid::detailed_timing_count() -> Int`: counts detailed timing descriptors.
- `Edid::valid_standard_timing_count() -> Int`: counts valid standard timings.
- `Edid::enabled_established_timing_count() -> Int`: counts enabled established timings.
- `Edid::display_class() -> DisplayClass`: derives a high-level display class.

## Mode Extraction

- `modes_from_edid(edid : Edid) -> Array[DisplayMode]`: merges detailed, standard, and established timing data.
- `preferred_mode(edid : Edid) -> DisplayMode?`: returns the preferred mode or best available mode.
- `best_mode(edid : Edid) -> DisplayMode?`: scores modes by resolution, refresh, preference, and interlacing.
- `modes_at_least(edid, width, height, refresh_hz)`: returns modes that meet minimum requirements.
- `modes_by_resolution(edid, width, height)`: filters modes by exact resolution.
- `supports_resolution(edid, width, height) -> Bool`: checks resolution support.
- `supports_mode(edid, width, height, refresh_hz) -> Bool`: checks resolution and refresh support.
- `max_refresh_for_resolution(edid, width, height) -> Int?`: returns the maximum rounded refresh.
- `has_interlaced_modes(edid) -> Bool`: detects interlaced modes.
- `mode_to_text(mode) -> String` and `modes_to_text(modes) -> String`: human-readable output.

## Timing Catalog

- `timing_catalog() -> Array[TimingCatalogEntry]`: bundled known timing entries.
- `catalog_entries_by_family(family)`: filters entries by timing family.
- `catalog_entries_by_resolution(width, height)`: filters entries by resolution.
- `find_catalog_entry(id) -> TimingCatalogEntry?`: looks up an entry by stable ID.
- `catalog_match_for_mode(mode) -> TimingCatalogEntry?`: matches a normalized mode.
- `catalog_matches_for_edid(edid) -> Array[TimingCatalogEntry]`: matches all decoded EDID modes.
- `catalog_summary_for_edid(edid) -> String`: compact comma-separated summary.
- `catalog_to_markdown(entries) -> String`: Markdown table output.
- `highest_catalog_mode() -> TimingCatalogEntry`: highest pixel-count entry.
- `high_refresh_catalog_entries() -> Array[TimingCatalogEntry]`: entries with 120 Hz or higher refresh.

## Audit

- `DisplayProfile::baseline()`
- `DisplayProfile::desktop()`
- `DisplayProfile::embedded_panel()`
- `DisplayProfile::large_format()`
- `DisplayProfile::legacy_xga()`
- `DisplayProfile::full_hd_video()`
- `DisplayProfile::workstation()`
- `DisplayProfile::gaming()`
- `DisplayProfile::uhd_video()`
- `DisplayProfile::projector_room()`

Audit functions:

- `audit_edid(edid : Edid) -> EdidAudit`: baseline audit.
- `audit_edid_with_profile(edid : Edid, profile : DisplayProfile) -> EdidAudit`: profile audit.
- `summarize_audit(edid, diagnostics) -> AuditSummary`: diagnostic counters and final status.
- `EdidAudit::is_ok()`, `has_errors()`, `has_warnings()`: result helpers.
- `EdidAudit::diagnostics_by_severity(severity)`: filters diagnostics.
- `EdidAudit::has_diagnostic(code)`: checks for a diagnostic code.

## Profile Matrix

- `standard_display_profiles() -> Array[DisplayProfile]`: built-in profile list.
- `profile_matrix(edid) -> Array[ProfileCheck]`: runs all standard profiles.
- `check_profile(edid, profile) -> ProfileCheck`: checks one profile.
- `best_profile_match(edid) -> ProfileCheck`: returns the highest-scoring profile row.
- `accepted_profiles(edid)` and `rejected_profiles(edid)`: filters matrix rows.
- `profile_matrix_to_text(checks)` and `profile_matrix_to_markdown(checks)`: report output.
- `ProfileCheck::is_ok()` and `ProfileCheck::failed_requirements()`: row helpers.

## Reporting

- `edid_to_text(edid) -> String`
- `audit_to_text(audit) -> String`
- `audit_summary_to_text(summary) -> String`
- `diagnostic_to_text(diagnostic) -> String`
- `modes_to_markdown(modes) -> String`
- `audit_to_markdown(audit) -> String`
- `edid_to_json(edid) -> String`
- `audit_to_json(audit) -> String`
- `mode_to_json(mode) -> String`
- `diagnostic_to_json(diagnostic) -> String`
- `audit_summary_to_json(summary) -> String`

## Sample Data

- `sample_edid_hex() -> String`: self-contained synthetic EDID hex.
- `sample_edid() -> Edid raise`: parsed sample.
- `sample_audit() -> EdidAudit raise`: baseline audit of the sample.
