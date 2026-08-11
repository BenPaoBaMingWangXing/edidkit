///|
pub fn DisplayProfile::baseline() -> DisplayProfile {
  {
    name: "baseline",
    min_width: 1024,
    min_height: 768,
    min_refresh_hz: 60,
    require_preferred_timing: true,
    allow_interlaced: false,
    max_extension_blocks: 4,
  }
}

///|
pub fn DisplayProfile::desktop() -> DisplayProfile {
  {
    name: "desktop",
    min_width: 1920,
    min_height: 1080,
    min_refresh_hz: 60,
    require_preferred_timing: true,
    allow_interlaced: false,
    max_extension_blocks: 4,
  }
}

///|
pub fn DisplayProfile::embedded_panel() -> DisplayProfile {
  {
    name: "embedded-panel",
    min_width: 1280,
    min_height: 720,
    min_refresh_hz: 60,
    require_preferred_timing: true,
    allow_interlaced: false,
    max_extension_blocks: 1,
  }
}

///|
pub fn DisplayProfile::large_format() -> DisplayProfile {
  {
    name: "large-format",
    min_width: 3840,
    min_height: 2160,
    min_refresh_hz: 60,
    require_preferred_timing: true,
    allow_interlaced: false,
    max_extension_blocks: 6,
  }
}

///|
pub fn audit_edid(edid : Edid) -> EdidAudit {
  audit_edid_with_profile(edid, DisplayProfile::baseline())
}

///|
pub fn audit_edid_with_profile(
  edid : Edid,
  profile : DisplayProfile,
) -> EdidAudit {
  let diagnostics : Array[EdidDiagnostic] = []
  append_parse_diagnostics(diagnostics, edid.diagnostics)
  append_basic_diagnostics(diagnostics, edid)
  append_timing_diagnostics(diagnostics, edid)
  append_descriptor_diagnostics(diagnostics, edid)
  append_range_diagnostics(diagnostics, edid)
  append_profile_diagnostics(diagnostics, edid, profile)
  let summary = summarize_audit(edid, diagnostics)
  {
    status: summary.status,
    profile_name: profile.name,
    diagnostics,
    summary,
    preferred_mode: preferred_mode(edid),
    display_class: edid.display_class(),
  }
}

///|
pub fn summarize_audit(
  edid : Edid,
  diagnostics : Array[EdidDiagnostic],
) -> AuditSummary {
  let mut notes = 0
  let mut warnings = 0
  let mut errors = 0
  for diagnostic in diagnostics {
    match diagnostic.severity {
      Note => notes = notes + 1
      Warning => warnings = warnings + 1
      Error => errors = errors + 1
    }
  }
  let status = if errors > 0 {
    Rejected
  } else if warnings > 0 {
    NeedsAttention
  } else {
    Accepted
  }
  {
    status,
    diagnostics: diagnostics.length(),
    notes,
    warnings,
    errors,
    detailed_timings: edid.detailed_timing_count(),
    standard_timings: edid.valid_standard_timing_count(),
    established_timings: edid.enabled_established_timing_count(),
  }
}

///|
pub fn EdidAudit::is_ok(self : EdidAudit) -> Bool {
  self.status == Accepted
}

///|
pub fn EdidAudit::has_errors(self : EdidAudit) -> Bool {
  self.summary.errors > 0
}

///|
pub fn EdidAudit::has_warnings(self : EdidAudit) -> Bool {
  self.summary.warnings > 0
}

///|
pub fn EdidAudit::diagnostics_by_severity(
  self : EdidAudit,
  severity : Severity,
) -> Array[EdidDiagnostic] {
  let out : Array[EdidDiagnostic] = []
  for diagnostic in self.diagnostics {
    if diagnostic.severity == severity {
      out.push(diagnostic)
    }
  }
  out
}

///|
pub fn EdidAudit::has_diagnostic(
  self : EdidAudit,
  code : DiagnosticCode,
) -> Bool {
  for diagnostic in self.diagnostics {
    if diagnostic.code == code {
      return true
    }
  }
  false
}

///|
fn append_parse_diagnostics(
  out : Array[EdidDiagnostic],
  diagnostics : Array[EdidDiagnostic],
) -> Unit {
  for diagnostic in diagnostics {
    out.push(diagnostic)
  }
}

///|
fn append_basic_diagnostics(out : Array[EdidDiagnostic], edid : Edid) -> Unit {
  if !edid.checksum_valid() {
    out.push(
      EdidDiagnostic::make(
        InvalidChecksum,
        Error,
        "Base block checksum is not valid",
        Some(127),
      ),
    )
  }
  if edid.version_major != 1 {
    out.push(
      EdidDiagnostic::make(
        UnsupportedVersion,
        Warning,
        "Only EDID 1.x base blocks are fully supported",
        Some(18),
      ),
    )
  }
  if edid.manufacture.week > 53 && !edid.manufacture.model_year {
    out.push(
      EdidDiagnostic::make(
        SuspiciousManufactureDate,
        Warning,
        "Manufacture week is outside the common 1..53 range",
        Some(16),
      ),
    )
  }
  if edid.manufacture.year < 1990 || edid.manufacture.year > 2050 {
    out.push(
      EdidDiagnostic::make(
        SuspiciousManufactureDate,
        Warning,
        "Manufacture year is outside expected EDID range",
        Some(17),
      ),
    )
  }
  if !edid.display.has_physical_size() {
    out.push(
      EdidDiagnostic::make(
        InvalidDisplaySize,
        Warning,
        "Physical display size is missing",
        Some(21),
      ),
    )
  }
  match edid.display.gamma_x100 {
    Some(gamma) =>
      if gamma < 120 || gamma > 350 {
        out.push(
          EdidDiagnostic::make(
            UnusualGamma,
            Note,
            "Gamma value is outside the common display range",
            Some(23),
          ),
        )
      }
    None => ()
  }
}

///|
fn append_timing_diagnostics(out : Array[EdidDiagnostic], edid : Edid) -> Unit {
  if edid.detailed_timing_count() == 0 {
    out.push(
      EdidDiagnostic::make(
        MissingDetailedTiming,
        Warning,
        "No detailed timing descriptor is present",
        Some(54),
      ),
    )
  }
  if edid.display.preferred_timing && preferred_mode(edid) is None {
    out.push(
      EdidDiagnostic::make(
        MissingPreferredTiming,
        Warning,
        "EDID marks preferred timing support but no preferred mode was decoded",
        Some(24),
      ),
    )
  }
}

///|
fn append_descriptor_diagnostics(
  out : Array[EdidDiagnostic],
  edid : Edid,
) -> Unit {
  match edid.monitor_name() {
    Some(name) =>
      if name.is_empty() {
        out.push(
          EdidDiagnostic::make(
            EmptyMonitorName,
            Note,
            "Monitor name descriptor is empty",
            None,
          ),
        )
      }
    None =>
      out.push(
        EdidDiagnostic::make(
          MissingMonitorName,
          Note,
          "Monitor name descriptor is not present",
          None,
        ),
      )
  }
}

///|
fn append_range_diagnostics(out : Array[EdidDiagnostic], edid : Edid) -> Unit {
  for descriptor in edid.descriptors {
    match descriptor.range_limits {
      Some(range) =>
        if range.min_vertical_hz > range.max_vertical_hz ||
          range.min_horizontal_khz > range.max_horizontal_khz {
          out.push(
            EdidDiagnostic::make(
              RangeLimitInconsistent,
              Warning,
              "Range limits descriptor has inverted min/max values",
              None,
            ),
          )
        }
      None => ()
    }
  }
}

///|
fn append_profile_diagnostics(
  out : Array[EdidDiagnostic],
  edid : Edid,
  profile : DisplayProfile,
) -> Unit {
  if profile.require_preferred_timing && preferred_mode(edid) is None {
    out.push(
      EdidDiagnostic::make(
        ProfileRequirementNotMet,
        Error,
        "Profile requires a preferred timing",
        None,
      ),
    )
  }
  if !supports_mode(
      edid,
      profile.min_width,
      profile.min_height,
      profile.min_refresh_hz,
    ) {
    out.push(
      EdidDiagnostic::make(
        ProfileRequirementNotMet,
        Error,
        "Display does not meet the profile minimum resolution and refresh rate",
        None,
      ),
    )
  }
  if !profile.allow_interlaced && has_interlaced_modes(edid) {
    out.push(
      EdidDiagnostic::make(
        InterlacedModeUnsupported,
        Warning,
        "Profile does not allow interlaced modes",
        None,
      ),
    )
  }
  if edid.extension_count > profile.max_extension_blocks {
    out.push(
      EdidDiagnostic::make(
        ExtensionBlockIgnored,
        Warning,
        "EDID declares more extension blocks than the profile accepts",
        Some(126),
      ),
    )
  }
}
