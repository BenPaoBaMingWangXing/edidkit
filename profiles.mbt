///|
pub fn DisplayProfile::legacy_xga() -> DisplayProfile {
  {
    name: "legacy-xga",
    min_width: 1024,
    min_height: 768,
    min_refresh_hz: 60,
    require_preferred_timing: false,
    allow_interlaced: true,
    max_extension_blocks: 8,
  }
}

///|
pub fn DisplayProfile::full_hd_video() -> DisplayProfile {
  {
    name: "full-hd-video",
    min_width: 1920,
    min_height: 1080,
    min_refresh_hz: 60,
    require_preferred_timing: true,
    allow_interlaced: false,
    max_extension_blocks: 4,
  }
}

///|
pub fn DisplayProfile::workstation() -> DisplayProfile {
  {
    name: "workstation",
    min_width: 2560,
    min_height: 1440,
    min_refresh_hz: 60,
    require_preferred_timing: true,
    allow_interlaced: false,
    max_extension_blocks: 4,
  }
}

///|
pub fn DisplayProfile::gaming() -> DisplayProfile {
  {
    name: "gaming",
    min_width: 1920,
    min_height: 1080,
    min_refresh_hz: 120,
    require_preferred_timing: true,
    allow_interlaced: false,
    max_extension_blocks: 4,
  }
}

///|
pub fn DisplayProfile::uhd_video() -> DisplayProfile {
  {
    name: "uhd-video",
    min_width: 3840,
    min_height: 2160,
    min_refresh_hz: 60,
    require_preferred_timing: true,
    allow_interlaced: false,
    max_extension_blocks: 6,
  }
}

///|
pub fn DisplayProfile::projector_room() -> DisplayProfile {
  {
    name: "projector-room",
    min_width: 1280,
    min_height: 800,
    min_refresh_hz: 60,
    require_preferred_timing: false,
    allow_interlaced: true,
    max_extension_blocks: 6,
  }
}

///|
pub fn standard_display_profiles() -> Array[DisplayProfile] {
  [
    DisplayProfile::legacy_xga(),
    DisplayProfile::baseline(),
    DisplayProfile::embedded_panel(),
    DisplayProfile::desktop(),
    DisplayProfile::full_hd_video(),
    DisplayProfile::projector_room(),
    DisplayProfile::workstation(),
    DisplayProfile::gaming(),
    DisplayProfile::large_format(),
    DisplayProfile::uhd_video(),
  ]
}

///|
pub fn profile_matrix(edid : Edid) -> Array[ProfileCheck] {
  let out : Array[ProfileCheck] = []
  for profile in standard_display_profiles() {
    out.push(check_profile(edid, profile))
  }
  out
}

///|
pub fn check_profile(edid : Edid, profile : DisplayProfile) -> ProfileCheck {
  let minimum_mode_met = supports_mode(
    edid,
    profile.min_width,
    profile.min_height,
    profile.min_refresh_hz,
  )
  let preferred_timing_met = !profile.require_preferred_timing ||
    preferred_mode(edid) is Some(_)
  let interlaced_policy_met = profile.allow_interlaced ||
    !has_interlaced_modes(edid)
  let extension_policy_met = edid.extension_count <=
    profile.max_extension_blocks
  let status = if minimum_mode_met &&
    preferred_timing_met &&
    interlaced_policy_met &&
    extension_policy_met {
    Accepted
  } else if minimum_mode_met && preferred_timing_met {
    NeedsAttention
  } else {
    Rejected
  }
  {
    profile_name: profile.name,
    status,
    score: profile_score(edid, profile),
    minimum_mode_met,
    preferred_timing_met,
    interlaced_policy_met,
    extension_policy_met,
  }
}

///|
pub fn best_profile_match(edid : Edid) -> ProfileCheck {
  let checks = profile_matrix(edid)
  let mut best = checks[0]
  for check in checks {
    if check.score > best.score {
      best = check
    }
  }
  best
}

///|
pub fn accepted_profiles(edid : Edid) -> Array[ProfileCheck] {
  let out : Array[ProfileCheck] = []
  for check in profile_matrix(edid) {
    if check.status == Accepted {
      out.push(check)
    }
  }
  out
}

///|
pub fn rejected_profiles(edid : Edid) -> Array[ProfileCheck] {
  let out : Array[ProfileCheck] = []
  for check in profile_matrix(edid) {
    if check.status == Rejected {
      out.push(check)
    }
  }
  out
}

///|
pub fn profile_matrix_to_text(checks : Array[ProfileCheck]) -> String {
  let buf = StringBuilder(size_hint=checks.length() * 64)
  let mut first = true
  for check in checks {
    if first {
      first = false
    } else {
      buf.write_char('\n')
    }
    buf.write_string(check.profile_name)
    buf.write_string(": ")
    buf.write_string(check.status.name())
    buf.write_string(" score=")
    buf.write_string(check.score.to_string())
  }
  buf.to_string()
}

///|
pub fn profile_matrix_to_markdown(checks : Array[ProfileCheck]) -> String {
  let buf = StringBuilder(size_hint=checks.length() * 96 + 96)
  buf.write_string(
    "| Profile | Status | Score | Mode | Preferred | Interlaced | Extensions |\n",
  )
  buf.write_string("| --- | --- | ---: | ---: | ---: | ---: | ---: |")
  for check in checks {
    buf.write_char('\n')
    buf.write_string("| ")
    buf.write_string(check.profile_name)
    buf.write_string(" | ")
    buf.write_string(check.status.name())
    buf.write_string(" | ")
    buf.write_string(check.score.to_string())
    buf.write_string(" | ")
    buf.write_string(yes_no(check.minimum_mode_met))
    buf.write_string(" | ")
    buf.write_string(yes_no(check.preferred_timing_met))
    buf.write_string(" | ")
    buf.write_string(yes_no(check.interlaced_policy_met))
    buf.write_string(" | ")
    buf.write_string(yes_no(check.extension_policy_met))
    buf.write_string(" |")
  }
  buf.to_string()
}

///|
pub fn ProfileCheck::is_ok(self : ProfileCheck) -> Bool {
  self.status == Accepted
}

///|
pub fn ProfileCheck::failed_requirements(self : ProfileCheck) -> Int {
  bool_failure(self.minimum_mode_met) +
  bool_failure(self.preferred_timing_met) +
  bool_failure(self.interlaced_policy_met) +
  bool_failure(self.extension_policy_met)
}

///|
fn profile_score(edid : Edid, profile : DisplayProfile) -> Int {
  let mut score = 0
  if supports_mode(
      edid,
      profile.min_width,
      profile.min_height,
      profile.min_refresh_hz,
    ) {
    score = score + 400
  }
  if !profile.require_preferred_timing || preferred_mode(edid) is Some(_) {
    score = score + 250
  }
  if profile.allow_interlaced || !has_interlaced_modes(edid) {
    score = score + 150
  }
  if edid.extension_count <= profile.max_extension_blocks {
    score = score + 100
  }
  match best_mode(edid) {
    Some(mode) => {
      if mode.width >= profile.min_width && mode.height >= profile.min_height {
        score = score + 80
      }
      if mode.refresh_hz_rounded() >= profile.min_refresh_hz {
        score = score + 20
      }
    }
    None => ()
  }
  score
}

///|
fn yes_no(value : Bool) -> String {
  if value {
    "yes"
  } else {
    "no"
  }
}

///|
fn bool_failure(value : Bool) -> Int {
  if value {
    0
  } else {
    1
  }
}
