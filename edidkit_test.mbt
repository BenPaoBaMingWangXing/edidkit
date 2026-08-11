///|
test "version is available" {
  @test.assert_eq(version(), "0.1.0")
}

///|
fn sample_hex() -> String {
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
fn sample_bad_checksum_hex() -> String {
  sample_hex()[0:sample_hex().length() - 2].to_owned() + "D4"
}

///|
fn must_parse_sample() -> Edid raise {
  match parse_edid_hex(sample_hex()) {
    Ok(value) => value
    Err(err) => fail(err.message)
  }
}

///|
test "parse sample identity fields" {
  let edid = must_parse_sample()
  @test.assert_eq(edid.manufacturer.code, "BNP")
  @test.assert_eq(edid.product_code, 0x1234)
  @test.assert_eq(edid.serial_number, 0x78563412)
  @test.assert_eq(edid.manufacture.year, 2026)
  @test.assert_eq(edid.manufacture.week, 10)
  @test.assert_eq(edid.version_major, 1)
  @test.assert_eq(edid.version_minor, 4)
  @test.assert_eq(edid.checksum, 0xD3)
}

///|
test "parse sample video input and display fields" {
  let edid = must_parse_sample()
  @test.assert_eq(edid.video_input.signal.name(), "digital")
  @test.assert_eq(edid.video_input.interface_name, "DisplayPort")
  @test.assert_eq(edid.video_input.bit_depth, "8-bit")
  @test.assert_eq(edid.display.width_cm, 52)
  @test.assert_eq(edid.display.height_cm, 32)
  @test.assert_eq(edid.display.gamma_x100, Some(220))
  @test.assert_eq(edid.display.preferred_timing, true)
}

///|
test "parse sample timing fields" {
  let edid = must_parse_sample()
  @test.assert_eq(edid.enabled_established_timing_count(), 3)
  @test.assert_eq(edid.valid_standard_timing_count(), 2)
  @test.assert_eq(edid.standard_timings[0].width, 1920)
  @test.assert_eq(edid.standard_timings[0].height, 1080)
  @test.assert_eq(edid.standard_timings[0].aspect.name(), "16:9")
  match edid.preferred_timing() {
    Some(timing) => {
      @test.assert_eq(timing.resolution(), "1920x1080")
      @test.assert_eq(timing.refresh_hz_rounded(), 60)
      @test.assert_eq(timing.pixel_clock_khz, 148500)
    }
    None => fail("expected preferred detailed timing")
  }
}

///|
test "parse sample descriptors" {
  let edid = must_parse_sample()
  @test.assert_eq(edid.descriptors.length(), 4)
  @test.assert_eq(edid.detailed_timing_count(), 1)
  @test.assert_eq(edid.monitor_name(), Some("EDIDKIT LCD"))
  @test.assert_eq(edid.descriptors[2].kind.name(), "range-limits")
  match edid.descriptors[2].range_limits {
    Some(range) => {
      @test.assert_eq(range.min_vertical_hz, 48)
      @test.assert_eq(range.max_vertical_hz, 75)
      @test.assert_eq(range.max_pixel_clock_mhz, 250)
    }
    None => fail("expected range limits")
  }
}

///|
test "hex parser accepts separators and rejects invalid input" {
  match parse_hex_bytes("00:ff-10_20,30") {
    Ok(bytes) => {
      @test.assert_eq(bytes.length(), 5)
      @test.assert_eq(bytes[1], 255)
    }
    Err(err) => fail(err.message)
  }
  match parse_hex_bytes("00 FG") {
    Ok(_) => fail("expected invalid hex character")
    Err(err) => @test.assert_eq(err.code.name(), "invalid-hex-character")
  }
  match parse_hex_bytes("0") {
    Ok(_) => fail("expected odd hex length")
    Err(err) => @test.assert_eq(err.code.name(), "invalid-hex-length")
  }
}

///|
test "parse rejects short and bad header input" {
  match parse_edid_hex("00 FF") {
    Ok(_) => fail("expected short EDID rejection")
    Err(err) => @test.assert_eq(err.code.name(), "invalid-length")
  }
  let bad = "11" + sample_hex()[2:].to_owned()
  match parse_edid_hex(bad) {
    Ok(_) => fail("expected invalid header")
    Err(err) => @test.assert_eq(err.code.name(), "invalid-header")
  }
}

///|
test "modes summarize detailed standard and established timings" {
  let edid = must_parse_sample()
  let modes = modes_from_edid(edid)
  inspect(modes.length() >= 5, content="true")
  @test.assert_eq(supports_resolution(edid, 1920, 1080), true)
  @test.assert_eq(supports_mode(edid, 1280, 1024, 60), true)
  @test.assert_eq(supports_mode(edid, 3840, 2160, 60), false)
  @test.assert_eq(max_refresh_for_resolution(edid, 1920, 1080), Some(60))
}

///|
test "preferred and best mode choose detailed descriptor" {
  let edid = must_parse_sample()
  match preferred_mode(edid) {
    Some(mode) => {
      @test.assert_eq(mode.label(), "1920x1080@60Hz")
      @test.assert_eq(mode.source.name(), "preferred-detailed")
      @test.assert_eq(mode.preferred, true)
    }
    None => fail("expected preferred mode")
  }
  match best_mode(edid) {
    Some(mode) => @test.assert_eq(mode.resolution(), "1920x1080")
    None => fail("expected best mode")
  }
}

///|
test "known timing table matches sample preferred mode" {
  let edid = must_parse_sample()
  match preferred_mode(edid) {
    Some(mode) => @test.assert_eq(dmt_name_for_mode(mode), Some("DMT 1920x1080@60"))
    None => fail("expected preferred mode")
  }
  @test.assert_eq(known_dmt_modes().length() >= 60, true)
}

///|
test "baseline and desktop audits accept sample EDID" {
  let edid = must_parse_sample()
  let baseline = audit_edid(edid)
  @test.assert_eq(baseline.status.name(), "accepted")
  @test.assert_eq(baseline.profile_name, "baseline")
  @test.assert_eq(baseline.summary.errors, 0)
  @test.assert_eq(baseline.display_class.name(), "desktop-monitor")
  let desktop = audit_edid_with_profile(edid, DisplayProfile::desktop())
  @test.assert_eq(desktop.is_ok(), true)
  @test.assert_eq(desktop.has_warnings(), false)
}

///|
test "large format audit rejects sample EDID" {
  let edid = must_parse_sample()
  let audit = audit_edid_with_profile(edid, DisplayProfile::large_format())
  @test.assert_eq(audit.status.name(), "rejected")
  @test.assert_eq(audit.has_errors(), true)
  @test.assert_eq(audit.has_diagnostic(ProfileRequirementNotMet), true)
  @test.assert_eq(audit.diagnostics_by_severity(Error).length(), 1)
}

///|
test "bad checksum produces audit error" {
  match parse_edid_hex(sample_bad_checksum_hex()) {
    Ok(edid) => {
      let audit = audit_edid(edid)
      @test.assert_eq(audit.status.name(), "rejected")
      @test.assert_eq(audit.has_diagnostic(InvalidChecksum), true)
    }
    Err(err) => fail(err.message)
  }
}
