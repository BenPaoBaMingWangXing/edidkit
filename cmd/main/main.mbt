///|
fn main {
  match @edidkit.parse_edid_hex(@edidkit.sample_edid_hex()) {
    Ok(edid) => {
      println(@edidkit.edid_to_text(edid))
      println("")
      println(@edidkit.modes_to_text(@edidkit.modes_from_edid(edid)))
    }
    Err(err) => println(err.message)
  }
}
