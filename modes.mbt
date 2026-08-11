///|
pub fn modes_from_edid(edid : Edid) -> Array[DisplayMode] {
  let modes : Array[DisplayMode] = []
  append_detailed_modes(modes, edid)
  append_standard_modes(modes, edid)
  append_established_modes(modes, edid)
  unique_modes(modes)
}

///|
pub fn preferred_mode(edid : Edid) -> DisplayMode? {
  for mode in modes_from_edid(edid) {
    if mode.preferred {
      return Some(mode)
    }
  }
  best_mode(edid)
}

///|
pub fn best_mode(edid : Edid) -> DisplayMode? {
  let modes = modes_from_edid(edid)
  if modes.is_empty() {
    None
  } else {
    let mut best = modes[0]
    for mode in modes {
      if mode_score(mode) > mode_score(best) {
        best = mode
      }
    }
    Some(best)
  }
}

///|
pub fn modes_at_least(
  edid : Edid,
  width : Int,
  height : Int,
  refresh_hz : Int,
) -> Array[DisplayMode] {
  let found : Array[DisplayMode] = []
  let refresh_millihz = refresh_hz * 1000
  for mode in modes_from_edid(edid) {
    if mode.width >= width &&
      mode.height >= height &&
      mode.refresh_millihz >= refresh_millihz {
      found.push(mode)
    }
  }
  found
}

///|
pub fn modes_by_resolution(
  edid : Edid,
  width : Int,
  height : Int,
) -> Array[DisplayMode] {
  let found : Array[DisplayMode] = []
  for mode in modes_from_edid(edid) {
    if mode.width == width && mode.height == height {
      found.push(mode)
    }
  }
  found
}

///|
pub fn supports_resolution(edid : Edid, width : Int, height : Int) -> Bool {
  !modes_by_resolution(edid, width, height).is_empty()
}

///|
pub fn supports_mode(
  edid : Edid,
  width : Int,
  height : Int,
  refresh_hz : Int,
) -> Bool {
  !modes_at_least(edid, width, height, refresh_hz).is_empty()
}

///|
pub fn max_refresh_for_resolution(
  edid : Edid,
  width : Int,
  height : Int,
) -> Int? {
  let modes = modes_by_resolution(edid, width, height)
  if modes.is_empty() {
    None
  } else {
    let mut best = modes[0].refresh_hz_rounded()
    for mode in modes {
      if mode.refresh_hz_rounded() > best {
        best = mode.refresh_hz_rounded()
      }
    }
    Some(best)
  }
}

///|
pub fn has_interlaced_modes(edid : Edid) -> Bool {
  for mode in modes_from_edid(edid) {
    if mode.interlaced {
      return true
    }
  }
  false
}

///|
pub fn mode_to_text(mode : DisplayMode) -> String {
  let buf = StringBuilder(size_hint=96)
  buf.write_string(mode.label())
  buf.write_string(" ")
  buf.write_string(mode.source.name())
  if mode.preferred {
    buf.write_string(" preferred")
  }
  if mode.interlaced {
    buf.write_string(" interlaced")
  }
  match mode.pixel_clock_khz {
    Some(clock) => {
      buf.write_string(" ")
      buf.write_string(clock.to_string())
      buf.write_string("kHz")
    }
    None => ()
  }
  buf.to_string()
}

///|
pub fn modes_to_text(modes : Array[DisplayMode]) -> String {
  let buf = StringBuilder(size_hint=modes.length() * 48)
  let mut first = true
  for mode in modes {
    if first {
      first = false
    } else {
      buf.write_char('\n')
    }
    buf.write_string("- ")
    buf.write_string(mode_to_text(mode))
  }
  buf.to_string()
}

///|
fn append_detailed_modes(modes : Array[DisplayMode], edid : Edid) -> Unit {
  let mut seen_detailed = false
  for descriptor in edid.descriptors {
    match descriptor.detailed_timing {
      Some(timing) => {
        modes.push(mode_from_detailed(timing, !seen_detailed))
        seen_detailed = true
      }
      None => ()
    }
  }
}

///|
fn append_standard_modes(modes : Array[DisplayMode], edid : Edid) -> Unit {
  for timing in edid.standard_timings {
    if timing.valid {
      modes.push(mode_from_standard(timing))
    }
  }
}

///|
fn append_established_modes(modes : Array[DisplayMode], edid : Edid) -> Unit {
  for timing in edid.established_timings {
    if timing.enabled {
      modes.push(mode_from_established(timing))
    }
  }
}

///|
fn mode_from_detailed(
  timing : DetailedTimingInfo,
  preferred : Bool,
) -> DisplayMode {
  {
    width: timing.h_active,
    height: timing.v_active,
    refresh_millihz: timing.refresh_millihz(),
    pixel_clock_khz: Some(timing.pixel_clock_khz),
    source: if preferred {
      PreferredDetailed
    } else {
      DetailedDescriptor
    },
    interlaced: timing.interlaced,
    preferred,
    name: timing.resolution(),
  }
}

///|
fn mode_from_standard(timing : StandardTiming) -> DisplayMode {
  {
    width: timing.width,
    height: timing.height,
    refresh_millihz: timing.refresh_hz * 1000,
    pixel_clock_khz: None,
    source: StandardTimingSource,
    interlaced: false,
    preferred: false,
    name: timing.width.to_string() + "x" + timing.height.to_string(),
  }
}

///|
fn mode_from_established(timing : EstablishedTiming) -> DisplayMode {
  {
    width: timing.width,
    height: timing.height,
    refresh_millihz: timing.refresh_hz * 1000,
    pixel_clock_khz: None,
    source: EstablishedTimingSource,
    interlaced: timing.name.contains("i"),
    preferred: false,
    name: timing.name,
  }
}

///|
fn unique_modes(modes : Array[DisplayMode]) -> Array[DisplayMode] {
  let out : Array[DisplayMode] = []
  for mode in modes {
    if !contains_similar_mode(out, mode) {
      out.push(mode)
    }
  }
  out
}

///|
fn contains_similar_mode(
  modes : Array[DisplayMode],
  mode : DisplayMode,
) -> Bool {
  for existing in modes {
    if existing.width == mode.width &&
      existing.height == mode.height &&
      refresh_close(existing.refresh_millihz, mode.refresh_millihz) {
      return true
    }
  }
  false
}

///|
fn refresh_close(left : Int, right : Int) -> Bool {
  let diff = if left > right { left - right } else { right - left }
  diff <= 1000
}

///|
fn mode_score(mode : DisplayMode) -> Int {
  let base = mode.pixel_count()
  let refresh_bonus = mode.refresh_hz_rounded() * 100
  let preferred_bonus = if mode.preferred { 10000000 } else { 0 }
  let interlace_penalty = if mode.interlaced { 1000000 } else { 0 }
  base + refresh_bonus + preferred_bonus - interlace_penalty
}

///|
pub fn dmt_name_for_mode(mode : DisplayMode) -> String? {
  let table = known_dmt_modes()
  for known in table {
    if known.width == mode.width &&
      known.height == mode.height &&
      refresh_close(known.refresh_millihz, mode.refresh_millihz) {
      return Some(known.name)
    }
  }
  None
}

///|
pub fn known_dmt_modes() -> Array[DisplayMode] {
  [
    known_mode(640, 350, 85000, "DMT 640x350@85"),
    known_mode(640, 400, 85000, "DMT 640x400@85"),
    known_mode(720, 400, 70000, "DMT 720x400@70"),
    known_mode(720, 400, 85000, "DMT 720x400@85"),
    known_mode(640, 480, 60000, "DMT 640x480@60"),
    known_mode(640, 480, 72000, "DMT 640x480@72"),
    known_mode(640, 480, 75000, "DMT 640x480@75"),
    known_mode(640, 480, 85000, "DMT 640x480@85"),
    known_mode(800, 600, 56000, "DMT 800x600@56"),
    known_mode(800, 600, 60000, "DMT 800x600@60"),
    known_mode(800, 600, 72000, "DMT 800x600@72"),
    known_mode(800, 600, 75000, "DMT 800x600@75"),
    known_mode(800, 600, 85000, "DMT 800x600@85"),
    known_mode(848, 480, 60000, "DMT 848x480@60"),
    known_mode(1024, 768, 87000, "DMT 1024x768@87i"),
    known_mode(1024, 768, 60000, "DMT 1024x768@60"),
    known_mode(1024, 768, 70000, "DMT 1024x768@70"),
    known_mode(1024, 768, 75000, "DMT 1024x768@75"),
    known_mode(1024, 768, 85000, "DMT 1024x768@85"),
    known_mode(1152, 864, 75000, "DMT 1152x864@75"),
    known_mode(1280, 768, 60000, "DMT 1280x768@60"),
    known_mode(1280, 768, 75000, "DMT 1280x768@75"),
    known_mode(1280, 768, 85000, "DMT 1280x768@85"),
    known_mode(1280, 800, 60000, "DMT 1280x800@60"),
    known_mode(1280, 800, 75000, "DMT 1280x800@75"),
    known_mode(1280, 800, 85000, "DMT 1280x800@85"),
    known_mode(1280, 960, 60000, "DMT 1280x960@60"),
    known_mode(1280, 960, 85000, "DMT 1280x960@85"),
    known_mode(1280, 1024, 60000, "DMT 1280x1024@60"),
    known_mode(1280, 1024, 75000, "DMT 1280x1024@75"),
    known_mode(1280, 1024, 85000, "DMT 1280x1024@85"),
    known_mode(1360, 768, 60000, "DMT 1360x768@60"),
    known_mode(1366, 768, 60000, "DMT 1366x768@60"),
    known_mode(1400, 1050, 60000, "DMT 1400x1050@60"),
    known_mode(1400, 1050, 75000, "DMT 1400x1050@75"),
    known_mode(1400, 1050, 85000, "DMT 1400x1050@85"),
    known_mode(1440, 900, 60000, "DMT 1440x900@60"),
    known_mode(1440, 900, 75000, "DMT 1440x900@75"),
    known_mode(1440, 900, 85000, "DMT 1440x900@85"),
    known_mode(1600, 900, 60000, "DMT 1600x900@60"),
    known_mode(1600, 1200, 60000, "DMT 1600x1200@60"),
    known_mode(1600, 1200, 65000, "DMT 1600x1200@65"),
    known_mode(1600, 1200, 70000, "DMT 1600x1200@70"),
    known_mode(1600, 1200, 75000, "DMT 1600x1200@75"),
    known_mode(1600, 1200, 85000, "DMT 1600x1200@85"),
    known_mode(1680, 1050, 60000, "DMT 1680x1050@60"),
    known_mode(1680, 1050, 75000, "DMT 1680x1050@75"),
    known_mode(1680, 1050, 85000, "DMT 1680x1050@85"),
    known_mode(1792, 1344, 60000, "DMT 1792x1344@60"),
    known_mode(1792, 1344, 75000, "DMT 1792x1344@75"),
    known_mode(1856, 1392, 60000, "DMT 1856x1392@60"),
    known_mode(1856, 1392, 75000, "DMT 1856x1392@75"),
    known_mode(1920, 1080, 60000, "DMT 1920x1080@60"),
    known_mode(1920, 1200, 60000, "DMT 1920x1200@60"),
    known_mode(1920, 1200, 85000, "DMT 1920x1200@85"),
    known_mode(1920, 1440, 60000, "DMT 1920x1440@60"),
    known_mode(1920, 1440, 75000, "DMT 1920x1440@75"),
    known_mode(2048, 1152, 60000, "DMT 2048x1152@60"),
    known_mode(2560, 1440, 60000, "DMT 2560x1440@60"),
    known_mode(2560, 1600, 60000, "DMT 2560x1600@60"),
    known_mode(3840, 2160, 30000, "CTA 3840x2160@30"),
    known_mode(3840, 2160, 60000, "CTA 3840x2160@60"),
    known_mode(4096, 2160, 60000, "CTA 4096x2160@60"),
  ]
}

///|
fn known_mode(
  width : Int,
  height : Int,
  refresh_millihz : Int,
  name : String,
) -> DisplayMode {
  {
    width,
    height,
    refresh_millihz,
    pixel_clock_khz: None,
    source: DmtDatabase,
    interlaced: name.contains("i"),
    preferred: false,
    name,
  }
}
