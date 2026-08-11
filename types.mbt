///|
/// Severity used by parser and audit diagnostics.
pub(all) enum Severity {
  Note
  Warning
  Error
} derive(Eq, Debug)

///|
/// Stable machine-readable diagnostic codes.
pub(all) enum DiagnosticCode {
  InvalidLength
  InvalidHexLength
  InvalidHexCharacter
  InvalidHeader
  InvalidChecksum
  UnsupportedVersion
  SuspiciousManufactureDate
  MissingDetailedTiming
  EmptyMonitorName
  MissingPreferredTiming
  ExtensionBlockIgnored
  NonSquarePhysicalSize
  UnusualGamma
  UnknownDescriptor
} derive(Eq, Debug)

///|
/// Overall EDID audit status.
pub(all) enum AuditStatus {
  Accepted
  NeedsAttention
  Rejected
} derive(Eq, Debug)

///|
/// Display color/input family reported by the video input byte.
pub(all) enum VideoSignal {
  Digital
  Analog
} derive(Eq, Debug)

///|
/// Standard timing aspect ratio code.
pub(all) enum AspectRatio {
  Ratio16_10
  Ratio4_3
  Ratio5_4
  Ratio16_9
} derive(Eq, Debug)

///|
/// EDID base block descriptor kind.
pub(all) enum DescriptorKind {
  DetailedTiming
  SerialNumberText
  MonitorName
  RangeLimits
  DisplayProductName
  DisplayProductSerial
  Text
  Empty
  Unknown(Int)
} derive(Eq, Debug)

///|
/// Parse error returned when an EDID input cannot produce a base block.
pub(all) struct EdidError {
  code : DiagnosticCode
  message : String
  offset : Int?
} derive(Eq, Debug)

///|
/// Recoverable diagnostic produced while parsing or auditing EDID data.
pub(all) struct EdidDiagnostic {
  code : DiagnosticCode
  severity : Severity
  message : String
  offset : Int?
} derive(Eq, Debug)

///|
/// Three-letter EISA manufacturer identifier.
pub(all) struct ManufacturerId {
  raw : Int
  code : String
} derive(Eq, Debug)

///|
/// EDID manufacture date fields.
pub(all) struct ManufactureDate {
  week : Int
  year : Int
  model_year : Bool
} derive(Eq, Debug)

///|
/// Video input information decoded from byte 20.
pub(all) struct VideoInput {
  signal : VideoSignal
  interface_name : String
  bit_depth : String
  voltage : String
  sync : String
} derive(Eq, Debug)

///|
/// Basic display dimensions and gamma.
pub(all) struct BasicDisplay {
  width_cm : Int
  height_cm : Int
  gamma_x100 : Int?
  standby : Bool
  suspend : Bool
  active_off : Bool
  preferred_timing : Bool
  default_srgb : Bool
} derive(Eq, Debug)

///|
/// Chromaticity coordinates scaled by 10000.
pub(all) struct Chromaticity {
  red_x : Int
  red_y : Int
  green_x : Int
  green_y : Int
  blue_x : Int
  blue_y : Int
  white_x : Int
  white_y : Int
} derive(Eq, Debug)

///|
/// One established timing capability.
pub(all) struct EstablishedTiming {
  name : String
  width : Int
  height : Int
  refresh_hz : Int
  enabled : Bool
  byte_offset : Int
  bit_mask : Int
} derive(Eq, Debug)

///|
/// One standard timing capability.
pub(all) struct StandardTiming {
  width : Int
  height : Int
  refresh_hz : Int
  aspect : AspectRatio
  byte_offset : Int
  valid : Bool
} derive(Eq, Debug)

///|
/// Detailed timing descriptor decoded from an 18-byte EDID descriptor.
pub(all) struct DetailedTimingInfo {
  pixel_clock_khz : Int
  h_active : Int
  h_blanking : Int
  v_active : Int
  v_blanking : Int
  h_sync_offset : Int
  h_sync_pulse : Int
  v_sync_offset : Int
  v_sync_pulse : Int
  h_size_mm : Int
  v_size_mm : Int
  h_border : Int
  v_border : Int
  interlaced : Bool
  positive_hsync : Bool
  positive_vsync : Bool
} derive(Eq, Debug)

///|
/// Range limits descriptor decoded from tag `0xFD`.
pub(all) struct RangeLimits {
  min_vertical_hz : Int
  max_vertical_hz : Int
  min_horizontal_khz : Int
  max_horizontal_khz : Int
  max_pixel_clock_mhz : Int
} derive(Eq, Debug)

///|
/// One EDID descriptor slot.
pub(all) struct Descriptor {
  kind : DescriptorKind
  index : Int
  text : String?
  detailed_timing : DetailedTimingInfo?
  range_limits : RangeLimits?
} derive(Eq, Debug)

///|
/// Parsed EDID base block.
pub(all) struct Edid {
  bytes : Array[Int]
  manufacturer : ManufacturerId
  product_code : Int
  serial_number : Int
  manufacture : ManufactureDate
  version_major : Int
  version_minor : Int
  video_input : VideoInput
  display : BasicDisplay
  chromaticity : Chromaticity
  established_timings : Array[EstablishedTiming]
  standard_timings : Array[StandardTiming]
  descriptors : Array[Descriptor]
  extension_count : Int
  checksum : Int
  diagnostics : Array[EdidDiagnostic]
} derive(Eq, Debug)

///|
/// Aggregate counters for EDID diagnostics.
pub(all) struct AuditSummary {
  status : AuditStatus
  diagnostics : Int
  notes : Int
  warnings : Int
  errors : Int
  detailed_timings : Int
  standard_timings : Int
  established_timings : Int
} derive(Eq, Debug)

///|
pub fn Severity::name(self : Severity) -> String {
  match self {
    Note => "note"
    Warning => "warning"
    Error => "error"
  }
}

///|
pub fn DiagnosticCode::name(self : DiagnosticCode) -> String {
  match self {
    InvalidLength => "invalid-length"
    InvalidHexLength => "invalid-hex-length"
    InvalidHexCharacter => "invalid-hex-character"
    InvalidHeader => "invalid-header"
    InvalidChecksum => "invalid-checksum"
    UnsupportedVersion => "unsupported-version"
    SuspiciousManufactureDate => "suspicious-manufacture-date"
    MissingDetailedTiming => "missing-detailed-timing"
    EmptyMonitorName => "empty-monitor-name"
    MissingPreferredTiming => "missing-preferred-timing"
    ExtensionBlockIgnored => "extension-block-ignored"
    NonSquarePhysicalSize => "non-square-physical-size"
    UnusualGamma => "unusual-gamma"
    UnknownDescriptor => "unknown-descriptor"
  }
}

///|
pub fn AuditStatus::name(self : AuditStatus) -> String {
  match self {
    Accepted => "accepted"
    NeedsAttention => "needs-attention"
    Rejected => "rejected"
  }
}

///|
pub fn VideoSignal::name(self : VideoSignal) -> String {
  match self {
    Digital => "digital"
    Analog => "analog"
  }
}

///|
pub fn AspectRatio::name(self : AspectRatio) -> String {
  match self {
    Ratio16_10 => "16:10"
    Ratio4_3 => "4:3"
    Ratio5_4 => "5:4"
    Ratio16_9 => "16:9"
  }
}

///|
pub fn DescriptorKind::name(self : DescriptorKind) -> String {
  match self {
    DetailedTiming => "detailed-timing"
    SerialNumberText => "serial-number-text"
    MonitorName => "monitor-name"
    RangeLimits => "range-limits"
    DisplayProductName => "display-product-name"
    DisplayProductSerial => "display-product-serial"
    Text => "text"
    Empty => "empty"
    Unknown(tag) => "unknown-" + tag.to_string()
  }
}

///|
pub fn EdidError::make(
  code : DiagnosticCode,
  message : String,
  offset : Int?,
) -> EdidError {
  { code, message, offset }
}

///|
pub fn EdidDiagnostic::make(
  code : DiagnosticCode,
  severity : Severity,
  message : String,
  offset : Int?,
) -> EdidDiagnostic {
  { code, severity, message, offset }
}

///|
pub fn EdidDiagnostic::to_error(self : EdidDiagnostic) -> EdidError {
  { code: self.code, message: self.message, offset: self.offset }
}

///|
pub fn ManufactureDate::description(self : ManufactureDate) -> String {
  if self.model_year {
    "model-year " + self.year.to_string()
  } else if self.week == 0 {
    "year " + self.year.to_string()
  } else {
    "week " + self.week.to_string() + " of " + self.year.to_string()
  }
}

///|
pub fn BasicDisplay::has_physical_size(self : BasicDisplay) -> Bool {
  self.width_cm > 0 && self.height_cm > 0
}

///|
pub fn BasicDisplay::aspect_x1000(self : BasicDisplay) -> Int? {
  if self.height_cm == 0 {
    None
  } else {
    Some(self.width_cm * 1000 / self.height_cm)
  }
}

///|
pub fn DetailedTimingInfo::resolution(self : DetailedTimingInfo) -> String {
  self.h_active.to_string() + "x" + self.v_active.to_string()
}

///|
pub fn DetailedTimingInfo::refresh_millihz(
  self : DetailedTimingInfo,
) -> Int {
  let h_total = self.h_active + self.h_blanking
  let v_total = self.v_active + self.v_blanking
  if h_total <= 0 || v_total <= 0 {
    0
  } else {
    (self.pixel_clock_khz * 1000 / h_total) * 1000 / v_total
  }
}

///|
pub fn DetailedTimingInfo::refresh_hz_rounded(
  self : DetailedTimingInfo,
) -> Int {
  (self.refresh_millihz() + 500) / 1000
}

///|
pub fn Descriptor::is_detailed_timing(self : Descriptor) -> Bool {
  self.kind == DetailedTiming
}

///|
pub fn Edid::monitor_name(self : Edid) -> String? {
  for descriptor in self.descriptors {
    if descriptor.kind == MonitorName {
      return descriptor.text
    }
  }
  None
}

///|
pub fn Edid::preferred_timing(self : Edid) -> DetailedTimingInfo? {
  for descriptor in self.descriptors {
    if descriptor.kind == DetailedTiming {
      return descriptor.detailed_timing
    }
  }
  None
}

///|
pub fn Edid::detailed_timing_count(self : Edid) -> Int {
  let mut count = 0
  for descriptor in self.descriptors {
    if descriptor.kind == DetailedTiming {
      count = count + 1
    }
  }
  count
}

///|
pub fn Edid::valid_standard_timing_count(self : Edid) -> Int {
  let mut count = 0
  for timing in self.standard_timings {
    if timing.valid {
      count = count + 1
    }
  }
  count
}

///|
pub fn Edid::enabled_established_timing_count(self : Edid) -> Int {
  let mut count = 0
  for timing in self.established_timings {
    if timing.enabled {
      count = count + 1
    }
  }
  count
}
