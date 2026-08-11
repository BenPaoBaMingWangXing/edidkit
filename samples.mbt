///|
/// Self-contained synthetic EDID sample used by examples and tests.
pub fn sample_edid_hex() -> String {
  "00 FF FF FF FF FF FF 00 09 D0 34 12 12 34 56 78 " +
  "0A 24 01 04 A5 34 20 78 06 00 00 00 00 00 00 00 " +
  "00 00 00 21 08 00 D1 C0 81 C0 01 01 01 01 01 01 " +
  "01 01 01 01 01 01 02 3A 80 18 71 38 2D 40 58 2C " +
  "45 00 FD 1E 11 00 00 1E 00 00 00 FC 00 45 44 49 " +
  "44 4B 49 54 20 4C 43 44 0A 20 00 00 00 FD 00 30 " +
  "4B 1E 55 19 00 0A 20 20 20 20 20 20 00 00 00 FF " +
  "00 45 4B 32 30 32 36 30 38 31 31 0A 20 20 00 D3"
}

///|
pub fn sample_edid() -> Edid raise {
  match parse_edid_hex(sample_edid_hex()) {
    Ok(value) => value
    Err(err) => fail(err.message)
  }
}

///|
pub fn sample_audit() -> EdidAudit raise {
  audit_edid(sample_edid())
}
