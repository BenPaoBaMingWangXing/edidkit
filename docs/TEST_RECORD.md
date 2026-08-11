# Test Record

Date: 2026-08-11

## Commands

```bash
moon check
moon build
moon test
moon doc
moon run cmd/main
moon run cmd/audit
moon package
moon publish --dry-run
moon publish
```

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
- `moon package`: passed and produced `BenPaoBaMingWangXing-edidkit-0.1.1.zip`.
- `moon publish --dry-run`: Mooncakes server accepted the dry run for `BenPaoBaMingWangXing/edidkit` version `0.1.1`.
- `moon publish`: Mooncakes server accepted version `0.1.1`.
- GitHub Actions CI: passed for commit `7fa26d8`.
- Mooncakes manifest: latest version `0.1.1`, build status `success`.
