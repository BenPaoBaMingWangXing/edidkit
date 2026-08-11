///|
pub fn edid_to_text(edid : Edid) -> String {
  let buf = StringBuilder(size_hint=512)
  buf.write_string("identity: ")
  buf.write_string(edid.identity())
  buf.write_char('\n')
  buf.write_string("manufacturer: ")
  buf.write_string(edid.manufacturer.code)
  buf.write_char('\n')
  buf.write_string("product-code: ")
  buf.write_string(edid.product_code.to_string())
  buf.write_char('\n')
  buf.write_string("serial-number: ")
  buf.write_string(edid.serial_number.to_string())
  buf.write_char('\n')
  buf.write_string("manufacture-date: ")
  buf.write_string(edid.manufacture.description())
  buf.write_char('\n')
  buf.write_string("version: ")
  buf.write_string(edid.version_text())
  buf.write_char('\n')
  buf.write_string("input: ")
  buf.write_string(edid.video_input.signal.name())
  buf.write_string(" ")
  buf.write_string(edid.video_input.interface_name)
  buf.write_char('\n')
  buf.write_string("size-cm: ")
  buf.write_string(edid.display.width_cm.to_string())
  buf.write_string("x")
  buf.write_string(edid.display.height_cm.to_string())
  buf.write_char('\n')
  match edid.monitor_name() {
    Some(name) => {
      buf.write_string("monitor-name: ")
      buf.write_string(name)
      buf.write_char('\n')
    }
    None => ()
  }
  match preferred_mode(edid) {
    Some(mode) => {
      buf.write_string("preferred-mode: ")
      buf.write_string(mode.label())
      match dmt_name_for_mode(mode) {
        Some(name) => {
          buf.write_string(" (")
          buf.write_string(name)
          buf.write_string(")")
        }
        None => ()
      }
      buf.write_char('\n')
    }
    None => ()
  }
  buf.write_string("extensions: ")
  buf.write_string(edid.extension_count.to_string())
  buf.write_char('\n')
  buf.write_string("catalog: ")
  buf.write_string(catalog_summary_for_edid(edid))
  buf.write_char('\n')
  buf.write_string("checksum-valid: ")
  buf.write_string(if edid.checksum_valid() { "true" } else { "false" })
  buf.to_string()
}

///|
pub fn audit_to_text(audit : EdidAudit) -> String {
  let buf = StringBuilder(size_hint=512)
  buf.write_string("status: ")
  buf.write_string(audit.status.name())
  buf.write_char('\n')
  buf.write_string("profile: ")
  buf.write_string(audit.profile_name)
  buf.write_char('\n')
  buf.write_string("display-class: ")
  buf.write_string(audit.display_class.name())
  buf.write_char('\n')
  buf.write_string("summary: ")
  buf.write_string(audit_summary_to_text(audit.summary))
  match audit.preferred_mode {
    Some(mode) => {
      buf.write_char('\n')
      buf.write_string("preferred-mode: ")
      buf.write_string(mode.label())
    }
    None => ()
  }
  if audit.diagnostics.length() > 0 {
    buf.write_char('\n')
    buf.write_string("diagnostics:")
    for diagnostic in audit.diagnostics {
      buf.write_char('\n')
      buf.write_string("- ")
      buf.write_string(diagnostic_to_text(diagnostic))
    }
  }
  buf.to_string()
}

///|
pub fn audit_summary_to_text(summary : AuditSummary) -> String {
  "status=" +
  summary.status.name() +
  ", diagnostics=" +
  summary.diagnostics.to_string() +
  ", notes=" +
  summary.notes.to_string() +
  ", warnings=" +
  summary.warnings.to_string() +
  ", errors=" +
  summary.errors.to_string() +
  ", detailed=" +
  summary.detailed_timings.to_string() +
  ", standard=" +
  summary.standard_timings.to_string() +
  ", established=" +
  summary.established_timings.to_string()
}

///|
pub fn diagnostic_to_text(diagnostic : EdidDiagnostic) -> String {
  let buf = StringBuilder(size_hint=96)
  buf.write_string(diagnostic.severity.name())
  buf.write_string(": ")
  buf.write_string(diagnostic.code.name())
  match diagnostic.offset {
    Some(offset) => {
      buf.write_string(" @")
      buf.write_string(offset.to_string())
    }
    None => ()
  }
  buf.write_string(" - ")
  buf.write_string(diagnostic.message)
  buf.to_string()
}

///|
pub fn modes_to_markdown(modes : Array[DisplayMode]) -> String {
  let buf = StringBuilder(size_hint=modes.length() * 64 + 96)
  buf.write_string("| Mode | Source | Preferred | Interlaced |\n")
  buf.write_string("| --- | --- | ---: | ---: |")
  for mode in modes {
    buf.write_char('\n')
    buf.write_string("| ")
    buf.write_string(markdown_escape(mode.label()))
    buf.write_string(" | ")
    buf.write_string(markdown_escape(mode.source.name()))
    buf.write_string(" | ")
    buf.write_string(if mode.preferred { "yes" } else { "no" })
    buf.write_string(" | ")
    buf.write_string(if mode.interlaced { "yes" } else { "no" })
    buf.write_string(" |")
  }
  buf.to_string()
}

///|
pub fn audit_to_markdown(audit : EdidAudit) -> String {
  let buf = StringBuilder(size_hint=512)
  buf.write_string("| Field | Value |\n")
  buf.write_string("| --- | --- |\n")
  buf.write_string("| Status | ")
  buf.write_string(markdown_escape(audit.status.name()))
  buf.write_string(" |\n")
  buf.write_string("| Profile | ")
  buf.write_string(markdown_escape(audit.profile_name))
  buf.write_string(" |\n")
  buf.write_string("| Display class | ")
  buf.write_string(markdown_escape(audit.display_class.name()))
  buf.write_string(" |\n")
  buf.write_string("| Diagnostics | ")
  buf.write_string(audit.summary.diagnostics.to_string())
  buf.write_string(" |\n")
  buf.write_string("| Errors | ")
  buf.write_string(audit.summary.errors.to_string())
  buf.write_string(" |\n")
  buf.write_string("| Warnings | ")
  buf.write_string(audit.summary.warnings.to_string())
  buf.write_string(" |")
  if audit.diagnostics.length() > 0 {
    buf.write_string("\n\n| Severity | Code | Message |\n")
    buf.write_string("| --- | --- | --- |")
    for diagnostic in audit.diagnostics {
      buf.write_char('\n')
      buf.write_string("| ")
      buf.write_string(markdown_escape(diagnostic.severity.name()))
      buf.write_string(" | ")
      buf.write_string(markdown_escape(diagnostic.code.name()))
      buf.write_string(" | ")
      buf.write_string(markdown_escape(diagnostic.message))
      buf.write_string(" |")
    }
  }
  buf.to_string()
}

///|
pub fn edid_to_json(edid : Edid) -> String {
  let buf = StringBuilder(size_hint=512)
  buf.write_string("{\"identity\":")
  write_json_string(buf, edid.identity())
  buf.write_string(",\"manufacturer\":")
  write_json_string(buf, edid.manufacturer.code)
  buf.write_string(",\"product_code\":")
  buf.write_string(edid.product_code.to_string())
  buf.write_string(",\"serial_number\":")
  buf.write_string(edid.serial_number.to_string())
  buf.write_string(",\"version\":")
  write_json_string(buf, edid.version_text())
  buf.write_string(",\"monitor_name\":")
  write_json_string_option(buf, edid.monitor_name())
  buf.write_string(",\"checksum_valid\":")
  write_json_bool(buf, edid.checksum_valid())
  buf.write_string(",\"extension_count\":")
  buf.write_string(edid.extension_count.to_string())
  buf.write_string(",\"modes\":[")
  let mut first = true
  for mode in modes_from_edid(edid) {
    if first {
      first = false
    } else {
      buf.write_char(',')
    }
    buf.write_string(mode_to_json(mode))
  }
  buf.write_string("]}")
  buf.to_string()
}

///|
pub fn audit_to_json(audit : EdidAudit) -> String {
  let buf = StringBuilder(size_hint=512)
  buf.write_string("{\"status\":")
  write_json_string(buf, audit.status.name())
  buf.write_string(",\"profile\":")
  write_json_string(buf, audit.profile_name)
  buf.write_string(",\"display_class\":")
  write_json_string(buf, audit.display_class.name())
  buf.write_string(",\"summary\":")
  buf.write_string(audit_summary_to_json(audit.summary))
  buf.write_string(",\"preferred_mode\":")
  match audit.preferred_mode {
    Some(mode) => buf.write_string(mode_to_json(mode))
    None => buf.write_string("null")
  }
  buf.write_string(",\"diagnostics\":[")
  let mut first = true
  for diagnostic in audit.diagnostics {
    if first {
      first = false
    } else {
      buf.write_char(',')
    }
    buf.write_string(diagnostic_to_json(diagnostic))
  }
  buf.write_string("]}")
  buf.to_string()
}

///|
pub fn mode_to_json(mode : DisplayMode) -> String {
  let buf = StringBuilder(size_hint=128)
  buf.write_string("{\"width\":")
  buf.write_string(mode.width.to_string())
  buf.write_string(",\"height\":")
  buf.write_string(mode.height.to_string())
  buf.write_string(",\"refresh_millihz\":")
  buf.write_string(mode.refresh_millihz.to_string())
  buf.write_string(",\"source\":")
  write_json_string(buf, mode.source.name())
  buf.write_string(",\"preferred\":")
  write_json_bool(buf, mode.preferred)
  buf.write_string(",\"interlaced\":")
  write_json_bool(buf, mode.interlaced)
  buf.write_char('}')
  buf.to_string()
}

///|
pub fn diagnostic_to_json(diagnostic : EdidDiagnostic) -> String {
  let buf = StringBuilder(size_hint=128)
  buf.write_string("{\"code\":")
  write_json_string(buf, diagnostic.code.name())
  buf.write_string(",\"severity\":")
  write_json_string(buf, diagnostic.severity.name())
  buf.write_string(",\"message\":")
  write_json_string(buf, diagnostic.message)
  buf.write_string(",\"offset\":")
  write_json_int_option(buf, diagnostic.offset)
  buf.write_char('}')
  buf.to_string()
}

///|
pub fn audit_summary_to_json(summary : AuditSummary) -> String {
  let buf = StringBuilder(size_hint=128)
  buf.write_string("{\"status\":")
  write_json_string(buf, summary.status.name())
  buf.write_string(",\"diagnostics\":")
  buf.write_string(summary.diagnostics.to_string())
  buf.write_string(",\"notes\":")
  buf.write_string(summary.notes.to_string())
  buf.write_string(",\"warnings\":")
  buf.write_string(summary.warnings.to_string())
  buf.write_string(",\"errors\":")
  buf.write_string(summary.errors.to_string())
  buf.write_char('}')
  buf.to_string()
}

///|
fn markdown_escape(value : String) -> String {
  let buf = StringBuilder(size_hint=value.length())
  for c in value.iter() {
    if c == '|' {
      buf.write_string("\\|")
    } else if c == '\n' || c == '\r' {
      buf.write_char(' ')
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn write_json_bool(buf : StringBuilder, value : Bool) -> Unit {
  if value {
    buf.write_string("true")
  } else {
    buf.write_string("false")
  }
}

///|
fn write_json_int_option(buf : StringBuilder, value : Int?) -> Unit {
  match value {
    Some(n) => buf.write_string(n.to_string())
    None => buf.write_string("null")
  }
}

///|
fn write_json_string_option(buf : StringBuilder, value : String?) -> Unit {
  match value {
    Some(s) => write_json_string(buf, s)
    None => buf.write_string("null")
  }
}

///|
fn write_json_string(buf : StringBuilder, value : String) -> Unit {
  buf.write_char('"')
  for c in value.iter() {
    if c == '"' {
      buf.write_string("\\\"")
    } else if c == '\\' {
      buf.write_string("\\\\")
    } else if c == '\n' {
      buf.write_string("\\n")
    } else if c == '\r' {
      buf.write_string("\\r")
    } else if c == '\t' {
      buf.write_string("\\t")
    } else {
      buf.write_char(c)
    }
  }
  buf.write_char('"')
}
