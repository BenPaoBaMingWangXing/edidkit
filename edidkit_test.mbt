///|
test "version is available" {
  @test.assert_eq(version(), "0.1.1")
}

///|
fn sample_hex() -> String {
  sample_edid_hex()
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
    Some(mode) =>
      @test.assert_eq(dmt_name_for_mode(mode), Some("DMT 1920x1080@60"))
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

///|
test "report renderers include stable fields" {
  let edid = must_parse_sample()
  let audit = audit_edid(edid)
  inspect(edid_to_text(edid).contains("manufacturer: BNP"), content="true")
  inspect(
    edid_to_text(edid).contains("preferred-mode: 1920x1080@60Hz"),
    content="true",
  )
  inspect(audit_to_text(audit).contains("status: accepted"), content="true")
  inspect(
    modes_to_markdown(modes_from_edid(edid)).contains("| 1920x1080@60Hz |"),
    content="true",
  )
  inspect(
    edid_to_json(edid).contains("\"identity\":\"BNP-4660\""),
    content="true",
  )
  inspect(
    audit_to_json(audit).contains("\"status\":\"accepted\""),
    content="true",
  )
}

///|
test "sample helpers parse and audit" {
  let edid = sample_edid()
  let audit = sample_audit()
  @test.assert_eq(edid.identity(), "BNP-4660")
  @test.assert_eq(audit.is_ok(), true)
}

///|
test "timing catalog can find and match common modes" {
  let edid = must_parse_sample()
  @test.assert_eq(timing_catalog().length() >= 120, true)
  @test.assert_eq(catalog_entries_by_family(DmtFamily).length() >= 50, true)
  @test.assert_eq(catalog_entries_by_resolution(1920, 1080).length() >= 4, true)
  match find_catalog_entry("dmt-1920x1080-60") {
    Some(entry) => {
      @test.assert_eq(entry.label(), "1920x1080@60Hz")
      @test.assert_eq(entry.family.name(), "dmt")
    }
    None => fail("expected catalog entry")
  }
  match preferred_mode(edid) {
    Some(mode) =>
      match catalog_match_for_mode(mode) {
        Some(entry) => @test.assert_eq(entry.id, "dmt-1920x1080-60")
        None => fail("expected catalog match")
      }
    None => fail("expected preferred mode")
  }
}

///|
test "catalog reports matched modes for EDID" {
  let edid = must_parse_sample()
  let matches = catalog_matches_for_edid(edid)
  inspect(matches.length() >= 4, content="true")
  inspect(
    catalog_summary_for_edid(edid).contains("dmt-1920x1080-60"),
    content="true",
  )
  inspect(
    catalog_to_markdown(matches).contains("| dmt-1920x1080-60 |"),
    content="true",
  )
  @test.assert_eq(high_refresh_catalog_entries().length(), 0)
  @test.assert_eq(highest_catalog_mode().width >= 3840, true)
}

///|
test "profile matrix classifies common display targets" {
  let edid = must_parse_sample()
  let checks = profile_matrix(edid)
  @test.assert_eq(checks.length(), standard_display_profiles().length())
  inspect(
    profile_matrix_to_text(checks).contains("full-hd-video"),
    content="true",
  )
  inspect(
    profile_matrix_to_markdown(checks).contains("| Profile | Status | Score |"),
    content="true",
  )
  inspect(accepted_profiles(edid).length() >= 6, content="true")
  inspect(rejected_profiles(edid).length() >= 3, content="true")
}

///|
test "best profile match remains stable for bundled sample" {
  let edid = must_parse_sample()
  let best = best_profile_match(edid)
  @test.assert_eq(best.profile_name, "legacy-xga")
  @test.assert_eq(best.status.name(), "accepted")
  @test.assert_eq(best.score, 1000)
  @test.assert_eq(best.is_ok(), true)
  @test.assert_eq(best.failed_requirements(), 0)
}

///|
test "profile matrix exposes rejected requirements" {
  let edid = must_parse_sample()
  let large = check_profile(edid, DisplayProfile::large_format())
  @test.assert_eq(large.status.name(), "rejected")
  @test.assert_eq(large.minimum_mode_met, false)
  @test.assert_eq(large.preferred_timing_met, true)
  @test.assert_eq(large.interlaced_policy_met, true)
  @test.assert_eq(large.extension_policy_met, true)
  @test.assert_eq(large.failed_requirements(), 1)
}
