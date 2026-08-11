///|
fn main {
  match @edidkit.parse_edid_hex(@edidkit.sample_edid_hex()) {
    Ok(edid) => {
      let audit = @edidkit.audit_edid_with_profile(
        edid,
        @edidkit.DisplayProfile::desktop(),
      )
      println(@edidkit.audit_to_text(audit))
      println("")
      println(@edidkit.audit_to_markdown(audit))
    }
    Err(err) => println(err.message)
  }
}
