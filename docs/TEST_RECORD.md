# Test Record

Date: 2026-08-18

## Commands

```bash
moon check
moon build
moon test
moon doc
moon run cmd/main
moon run cmd/audit
moon package
moon check --deny-warn
moon test --deny-warn
moon fmt --check
moon info
```

Mooncakes release commands completed on 2026-08-18 for version `0.1.2`:

```bash
moon publish --dry-run
moon publish
```

## Tooling Note

The repository keeps both `moon.mod` and `moon.mod.json` because the current documentation generator reads the JSON metadata file. MoonBit emits a compatibility notice for the dual metadata files, but the checked commands exit successfully.

## Current Automated Tests

The test suite covers:

- Version availability.
- Sample EDID identity fields.
- Video input and display fields.
- Established, standard, and detailed timing fields.
- Descriptor parsing and range limits.
- Hex parser separators and invalid input errors.
- Short EDID and invalid header rejection.
- Mode extraction from detailed, standard, and established timings.
- Preferred and best mode selection.
- Known DMT timing match.
- Baseline and desktop audit acceptance.
- Large-format audit rejection.
- Bad checksum audit error.
- Text, Markdown, and JSON report output.
- Sample helper functions.
- Timing catalog lookup, matching, summary, and Markdown output.
- Profile matrix classification.
- Best profile match stability.
- Rejected profile requirement visibility.

## Latest Result

- `moon check`: passed.
- `moon build`: passed.
- `moon test`: 20 passed, 0 failed.
- `moon doc`: passed.
- `moon run cmd/main`: passed.
- `moon run cmd/audit`: passed.
- `moon package`: passed and produced `BenPaoBaMingWangXing-edidkit-0.1.2.zip`.
- `moon check --deny-warn`: passed.
- `moon test --deny-warn`: 20 passed, 0 failed.
- `moon fmt --check`: passed.
- `moon info`: passed.
- `moon publish --dry-run`: Mooncakes server accepted the dry run for `BenPaoBaMingWangXing/edidkit` version `0.1.2`.
- `moon publish`: Mooncakes server accepted version `0.1.2`.
- GitHub Actions CI: workflow configured and latest checked remote run passed on default branch `main`.
- Mooncakes manifest: latest version `0.1.2`, build status `success`.
