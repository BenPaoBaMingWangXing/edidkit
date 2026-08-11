///|
pub fn parse_edid_hex(input : String) -> Result[Edid, EdidError] {
  match parse_hex_bytes(input) {
    Ok(bytes) => parse_edid_bytes(bytes)
    Err(err) => Err(err)
  }
}

///|
pub fn parse_edid_bytes(data : Array[Int]) -> Result[Edid, EdidError] {
  if data.length() < 128 {
    return Err(
      EdidError::make(
        InvalidLength,
        "EDID input must contain at least one 128-byte base block",
        Some(data.length()),
      ),
    )
  }
  if !has_edid_header(data) {
    return Err(
      EdidError::make(
        InvalidHeader,
        "EDID base block does not start with 00 FF FF FF FF FF FF 00",
        Some(0),
      ),
    )
  }
  let diagnostics : Array[EdidDiagnostic] = []
  if !checksum_valid(data, 0) {
    diagnostics.push(
      EdidDiagnostic::make(
        InvalidChecksum,
        Error,
        "EDID base block checksum is invalid",
        Some(127),
      ),
    )
  }
  let version_major = byte_at(data, 18)
  let version_minor = byte_at(data, 19)
  if version_major != 1 {
    diagnostics.push(
      EdidDiagnostic::make(
        UnsupportedVersion,
        Warning,
        "Only EDID version 1.x base blocks are fully decoded",
        Some(18),
      ),
    )
  }
  let extension_count = byte_at(data, 126)
  if extension_count > 0 {
    diagnostics.push(
      EdidDiagnostic::make(
        ExtensionBlockIgnored,
        Note,
        "Extension blocks are counted but not decoded by the base parser",
        Some(126),
      ),
    )
  }
  let edid : Edid = {
    bytes: first_base_block(data),
    manufacturer: parse_manufacturer(data),
    product_code: u16_le(data, 10),
    serial_number: u32_le(data, 12),
    manufacture: parse_manufacture_date(data),
    version_major,
    version_minor,
    video_input: parse_video_input(data),
    display: parse_basic_display(data),
    chromaticity: parse_chromaticity(data),
    established_timings: parse_established_timings(data),
    standard_timings: parse_standard_timings(data),
    descriptors: parse_descriptors(data, diagnostics),
    extension_count,
    checksum: byte_at(data, 127),
    diagnostics,
  }
  Ok(edid)
}

///|
fn first_base_block(data : Array[Int]) -> Array[Int] {
  let out : Array[Int] = []
  let mut i = 0
  while i < 128 {
    out.push(byte_at(data, i))
    i = i + 1
  }
  out
}

///|
fn parse_manufacturer(data : Array[Int]) -> ManufacturerId {
  let raw = u16_be(data, 8)
  let c1 = (((raw >> 10) & 31) + 64).to_char().unwrap()
  let c2 = (((raw >> 5) & 31) + 64).to_char().unwrap()
  let c3 = ((raw & 31) + 64).to_char().unwrap()
  { raw, code: String::from_array([c1, c2, c3]) }
}

///|
fn parse_manufacture_date(data : Array[Int]) -> ManufactureDate {
  let week = byte_at(data, 16)
  let year = byte_at(data, 17) + 1990
  { week, year, model_year: week == 0xFF }
}

///|
fn parse_video_input(data : Array[Int]) -> VideoInput {
  let value = byte_at(data, 20)
  if bit_set(value, 0x80) {
    {
      signal: Digital,
      interface_name: digital_interface_name(value & 0x0F),
      bit_depth: digital_bit_depth((value >> 4) & 0x07),
      voltage: "",
      sync: "",
    }
  } else {
    {
      signal: Analog,
      interface_name: "analog",
      bit_depth: "",
      voltage: analog_voltage((value >> 5) & 0x03),
      sync: analog_sync(value),
    }
  }
}

///|
fn digital_bit_depth(code : Int) -> String {
  match code {
    0 => "undefined"
    1 => "6-bit"
    2 => "8-bit"
    3 => "10-bit"
    4 => "12-bit"
    5 => "14-bit"
    6 => "16-bit"
    _ => "reserved"
  }
}

///|
fn digital_interface_name(code : Int) -> String {
  match code {
    0 => "undefined"
    1 => "DVI"
    2 => "HDMI-a"
    3 => "HDMI-b"
    4 => "MDDI"
    5 => "DisplayPort"
    _ => "reserved"
  }
}

///|
fn analog_voltage(code : Int) -> String {
  match code {
    0 => "0.700/0.300 V"
    1 => "0.714/0.286 V"
    2 => "1.000/0.400 V"
    _ => "0.700/0.000 V"
  }
}

///|
fn analog_sync(value : Int) -> String {
  let buf = StringBuilder(size_hint=48)
  if bit_set(value, 0x10) {
    buf.write_string("separate ")
  }
  if bit_set(value, 0x08) {
    buf.write_string("composite ")
  }
  if bit_set(value, 0x04) {
    buf.write_string("sync-on-green ")
  }
  if bit_set(value, 0x02) {
    buf.write_string("serration ")
  }
  let text = buf.to_string().trim(chars=" ").to_owned()
  if text.is_empty() {
    "none"
  } else {
    text
  }
}

///|
fn parse_basic_display(data : Array[Int]) -> BasicDisplay {
  let gamma_byte = byte_at(data, 23)
  let features = byte_at(data, 24)
  {
    width_cm: byte_at(data, 21),
    height_cm: byte_at(data, 22),
    gamma_x100: if gamma_byte == 0xFF {
      None
    } else {
      Some(gamma_byte + 100)
    },
    standby: bit_set(features, 0x80),
    suspend: bit_set(features, 0x40),
    active_off: bit_set(features, 0x20),
    preferred_timing: bit_set(features, 0x02),
    default_srgb: bit_set(features, 0x04),
  }
}

///|
fn parse_chromaticity(data : Array[Int]) -> Chromaticity {
  let lo1 = byte_at(data, 25)
  let lo2 = byte_at(data, 26)
  {
    red_x: chroma_value(byte_at(data, 27), (lo1 >> 6) & 3),
    red_y: chroma_value(byte_at(data, 28), (lo1 >> 4) & 3),
    green_x: chroma_value(byte_at(data, 29), (lo1 >> 2) & 3),
    green_y: chroma_value(byte_at(data, 30), lo1 & 3),
    blue_x: chroma_value(byte_at(data, 31), (lo2 >> 6) & 3),
    blue_y: chroma_value(byte_at(data, 32), (lo2 >> 4) & 3),
    white_x: chroma_value(byte_at(data, 33), (lo2 >> 2) & 3),
    white_y: chroma_value(byte_at(data, 34), lo2 & 3),
  }
}

///|
fn chroma_value(high : Int, low : Int) -> Int {
  (((high << 2) + low) * 10000 + 512) / 1024
}

///|
fn parse_established_timings(data : Array[Int]) -> Array[EstablishedTiming] {
  [
    established("720x400@70", 720, 400, 70, data, 35, 0x80),
    established("720x400@88", 720, 400, 88, data, 35, 0x40),
    established("640x480@60", 640, 480, 60, data, 35, 0x20),
    established("640x480@67", 640, 480, 67, data, 35, 0x10),
    established("640x480@72", 640, 480, 72, data, 35, 0x08),
    established("640x480@75", 640, 480, 75, data, 35, 0x04),
    established("800x600@56", 800, 600, 56, data, 35, 0x02),
    established("800x600@60", 800, 600, 60, data, 35, 0x01),
    established("800x600@72", 800, 600, 72, data, 36, 0x80),
    established("800x600@75", 800, 600, 75, data, 36, 0x40),
    established("832x624@75", 832, 624, 75, data, 36, 0x20),
    established("1024x768@87i", 1024, 768, 87, data, 36, 0x10),
    established("1024x768@60", 1024, 768, 60, data, 36, 0x08),
    established("1024x768@70", 1024, 768, 70, data, 36, 0x04),
    established("1024x768@75", 1024, 768, 75, data, 36, 0x02),
    established("1280x1024@75", 1280, 1024, 75, data, 36, 0x01),
    established("1152x870@75", 1152, 870, 75, data, 37, 0x80),
  ]
}

///|
fn established(
  name : String,
  width : Int,
  height : Int,
  refresh_hz : Int,
  data : Array[Int],
  byte_offset : Int,
  bit_mask : Int,
) -> EstablishedTiming {
  {
    name,
    width,
    height,
    refresh_hz,
    enabled: bit_set(byte_at(data, byte_offset), bit_mask),
    byte_offset,
    bit_mask,
  }
}

///|
fn parse_standard_timings(data : Array[Int]) -> Array[StandardTiming] {
  let timings : Array[StandardTiming] = []
  let mut offset = 38
  while offset < 54 {
    timings.push(parse_standard_timing(data, offset))
    offset = offset + 2
  }
  timings
}

///|
fn parse_standard_timing(data : Array[Int], offset : Int) -> StandardTiming {
  let b1 = byte_at(data, offset)
  let b2 = byte_at(data, offset + 1)
  if b1 == 0x01 && b2 == 0x01 {
    {
      width: 0,
      height: 0,
      refresh_hz: 0,
      aspect: Ratio16_10,
      byte_offset: offset,
      valid: false,
    }
  } else {
    let width = (b1 + 31) * 8
    let aspect = aspect_ratio_from_code((b2 >> 6) & 3)
    {
      width,
      height: standard_height(width, aspect),
      refresh_hz: (b2 & 0x3F) + 60,
      aspect,
      byte_offset: offset,
      valid: true,
    }
  }
}

///|
fn aspect_ratio_from_code(code : Int) -> AspectRatio {
  match code {
    0 => Ratio16_10
    1 => Ratio4_3
    2 => Ratio5_4
    _ => Ratio16_9
  }
}

///|
fn standard_height(width : Int, aspect : AspectRatio) -> Int {
  match aspect {
    Ratio16_10 => width * 10 / 16
    Ratio4_3 => width * 3 / 4
    Ratio5_4 => width * 4 / 5
    Ratio16_9 => width * 9 / 16
  }
}

///|
fn parse_descriptors(
  data : Array[Int],
  diagnostics : Array[EdidDiagnostic],
) -> Array[Descriptor] {
  [
    parse_descriptor(data, 54, 0, diagnostics),
    parse_descriptor(data, 72, 1, diagnostics),
    parse_descriptor(data, 90, 2, diagnostics),
    parse_descriptor(data, 108, 3, diagnostics),
  ]
}

///|
fn parse_descriptor(
  data : Array[Int],
  offset : Int,
  index : Int,
  diagnostics : Array[EdidDiagnostic],
) -> Descriptor {
  let pixel_clock_raw = u16_le(data, offset)
  if pixel_clock_raw > 0 {
    {
      kind: DetailedTiming,
      index,
      text: None,
      detailed_timing: Some(parse_detailed_timing(data, offset)),
      range_limits: None,
    }
  } else if byte_at(data, offset + 2) == 0x00 {
    parse_monitor_descriptor(data, offset, index, diagnostics)
  } else {
    diagnostics.push(
      EdidDiagnostic::make(
        UnknownDescriptor,
        Warning,
        "Descriptor has zero pixel clock but does not use monitor descriptor layout",
        Some(offset),
      ),
    )
    {
      kind: Unknown(byte_at(data, offset + 3)),
      index,
      text: None,
      detailed_timing: None,
      range_limits: None,
    }
  }
}

///|
fn parse_monitor_descriptor(
  data : Array[Int],
  offset : Int,
  index : Int,
  diagnostics : Array[EdidDiagnostic],
) -> Descriptor {
  let tag = byte_at(data, offset + 3)
  if tag == 0xFC {
    text_descriptor(MonitorName, data, offset, index)
  } else if tag == 0xFF {
    text_descriptor(SerialNumberText, data, offset, index)
  } else if tag == 0xFE {
    text_descriptor(Text, data, offset, index)
  } else if tag == 0xFD {
    {
      kind: RangeLimits,
      index,
      text: None,
      detailed_timing: None,
      range_limits: Some(parse_range_limits(data, offset)),
    }
  } else if tag == 0x00 {
    {
      kind: Empty,
      index,
      text: None,
      detailed_timing: None,
      range_limits: None,
    }
  } else {
    diagnostics.push(
      EdidDiagnostic::make(
        UnknownDescriptor,
        Note,
        "Monitor descriptor tag is not decoded by edidkit",
        Some(offset + 3),
      ),
    )
    {
      kind: Unknown(tag),
      index,
      text: Some(descriptor_text(data, offset)),
      detailed_timing: None,
      range_limits: None,
    }
  }
}

///|
fn text_descriptor(
  kind : DescriptorKind,
  data : Array[Int],
  offset : Int,
  index : Int,
) -> Descriptor {
  {
    kind,
    index,
    text: Some(descriptor_text(data, offset)),
    detailed_timing: None,
    range_limits: None,
  }
}

///|
fn parse_range_limits(data : Array[Int], offset : Int) -> RangeLimits {
  {
    min_vertical_hz: byte_at(data, offset + 5),
    max_vertical_hz: byte_at(data, offset + 6),
    min_horizontal_khz: byte_at(data, offset + 7),
    max_horizontal_khz: byte_at(data, offset + 8),
    max_pixel_clock_mhz: byte_at(data, offset + 9) * 10,
  }
}

///|
fn parse_detailed_timing(data : Array[Int], offset : Int) -> DetailedTimingInfo {
  let h_active = byte_at(data, offset + 2) +
    (byte_at(data, offset + 4) >> 4 << 8)
  let h_blanking = byte_at(data, offset + 3) +
    ((byte_at(data, offset + 4) & 0x0F) << 8)
  let v_active = byte_at(data, offset + 5) +
    (byte_at(data, offset + 7) >> 4 << 8)
  let v_blanking = byte_at(data, offset + 6) +
    ((byte_at(data, offset + 7) & 0x0F) << 8)
  let h_sync_offset = byte_at(data, offset + 8) +
    (((byte_at(data, offset + 11) >> 6) & 3) << 8)
  let h_sync_pulse = byte_at(data, offset + 9) +
    (((byte_at(data, offset + 11) >> 4) & 3) << 8)
  let v_sync_offset = ((byte_at(data, offset + 10) >> 4) & 0x0F) +
    (((byte_at(data, offset + 11) >> 2) & 3) << 4)
  let v_sync_pulse = (byte_at(data, offset + 10) & 0x0F) +
    ((byte_at(data, offset + 11) & 3) << 4)
  let h_size_mm = byte_at(data, offset + 12) +
    (byte_at(data, offset + 14) >> 4 << 8)
  let v_size_mm = byte_at(data, offset + 13) +
    ((byte_at(data, offset + 14) & 0x0F) << 8)
  let flags = byte_at(data, offset + 17)
  {
    pixel_clock_khz: u16_le(data, offset) * 10,
    h_active,
    h_blanking,
    v_active,
    v_blanking,
    h_sync_offset,
    h_sync_pulse,
    v_sync_offset,
    v_sync_pulse,
    h_size_mm,
    v_size_mm,
    h_border: byte_at(data, offset + 15),
    v_border: byte_at(data, offset + 16),
    interlaced: bit_set(flags, 0x80),
    positive_hsync: bit_set(flags, 0x02),
    positive_vsync: bit_set(flags, 0x04),
  }
}
