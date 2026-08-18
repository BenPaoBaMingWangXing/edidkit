# Security Policy

## Supported Versions

Version `0.1.x` receives fixes during the hackathon validation period.

## Input Handling

`edidkit` parses untrusted EDID text or byte arrays without file-system, network, process, or OS display driver access. The parser rejects short inputs and invalid headers, reports checksum mismatch as a diagnostic, and decodes only the first 128-byte base block in version `0.1.2`.

## Reporting Issues

Use the public repository issue tracker:

`https://github.com/BenPaoBaMingWangXing/edidkit/issues`

Please include the input shape, expected behavior, actual behavior, and command used to reproduce the issue.
