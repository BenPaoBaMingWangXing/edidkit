# Changelog

## 0.1.1 - 2026-08-11

### Changed

- Added `moon.mod.json` metadata alongside `moon.mod` so Mooncakes documentation generation can read module metadata.
- Kept the public API and behavior unchanged from `0.1.0`.

## 0.1.0 - 2026-08-11

Initial public release candidate.

### Added

- EDID hex string parser.
- EDID 1.x base block parser.
- Header, length, checksum, and version diagnostics.
- Manufacturer, product, serial, manufacture date, version, video input, display size, gamma, feature flag, and chromaticity decoding.
- Established, standard, and detailed timing decoding.
- Monitor name, serial text, generic text, empty descriptor, unknown descriptor, and range limits descriptor support.
- Normalized display mode extraction.
- Preferred and best display mode helpers.
- DMT/CTA/CVT/reduced-blanking/projector timing catalog.
- Timing catalog lookup, matching, summary, and Markdown output.
- Baseline, desktop, embedded panel, large-format, legacy XGA, full-HD video, workstation, gaming, UHD video, and projector room profiles.
- EDID audit result model and profile matrix.
- Text, Markdown, and JSON report renderers.
- Runnable parser and audit examples.
- MoonBit tests and GitHub Actions CI.
- README, project proposal, API documentation, design notes, test record, acceptance checklist, development log, and Mooncakes collision check.

### Known Limits

- CTA-861 extension blocks are counted but not decoded.
- DisplayID blocks are not decoded.
- Binary file I/O helpers are not included.
- OS display driver bindings are not included.
