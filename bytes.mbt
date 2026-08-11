///|
fn char_at(s : String, index : Int) -> Char {
  s.get_char(index).unwrap()
}

///|
fn is_hex(c : Char) -> Bool {
  c.is_ascii_hexdigit()
}

///|
fn hex_value(c : Char) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if c >= 'A' && c <= 'F' {
    c.to_int() - 'A'.to_int() + 10
  } else if c >= 'a' && c <= 'f' {
    c.to_int() - 'a'.to_int() + 10
  } else {
    -1
  }
}

///|
fn is_hex_separator(c : Char) -> Bool {
  c == ' ' ||
  c == '\t' ||
  c == '\n' ||
  c == '\r' ||
  c == ':' ||
  c == '-' ||
  c == '_' ||
  c == ','
}

///|
pub fn parse_hex_bytes(input : String) -> Result[Array[Int], EdidError] {
  let nibbles : Array[Int] = []
  let mut index = 0
  while index < input.length() {
    let c = char_at(input, index)
    if is_hex_separator(c) {
      index = index + c.utf16_len()
      continue
    }
    if !is_hex(c) {
      return Err(
        EdidError::make(
          InvalidHexCharacter,
          "Input contains a non-hexadecimal character",
          Some(index),
        ),
      )
    }
    nibbles.push(hex_value(c))
    index = index + c.utf16_len()
  }
  if nibbles.length() % 2 != 0 {
    return Err(
      EdidError::make(
        InvalidHexLength,
        "Hexadecimal EDID input must contain an even number of digits",
        None,
      ),
    )
  }
  let bytes : Array[Int] = []
  let mut i = 0
  while i < nibbles.length() {
    bytes.push((nibbles[i] << 4) + nibbles[i + 1])
    i = i + 2
  }
  Ok(bytes)
}

///|
fn byte_at(data : Array[Int], index : Int) -> Int {
  data[index] & 0xFF
}

///|
fn u16_le(data : Array[Int], index : Int) -> Int {
  byte_at(data, index) + (byte_at(data, index + 1) << 8)
}

///|
fn u16_be(data : Array[Int], index : Int) -> Int {
  (byte_at(data, index) << 8) + byte_at(data, index + 1)
}

///|
fn u32_le(data : Array[Int], index : Int) -> Int {
  byte_at(data, index) +
  (byte_at(data, index + 1) << 8) +
  (byte_at(data, index + 2) << 16) +
  (byte_at(data, index + 3) << 24)
}

///|
fn bit_set(value : Int, mask : Int) -> Bool {
  (value & mask) != 0
}

///|
fn edid_block_checksum(data : Array[Int], offset : Int) -> Int {
  let mut sum = 0
  let mut i = 0
  while i < 128 {
    sum = (sum + byte_at(data, offset + i)) & 0xFF
    i = i + 1
  }
  sum
}

///|
fn checksum_valid(data : Array[Int], offset : Int) -> Bool {
  edid_block_checksum(data, offset) == 0
}

///|
fn has_edid_header(data : Array[Int]) -> Bool {
  data.length() >= 8 &&
  byte_at(data, 0) == 0x00 &&
  byte_at(data, 1) == 0xFF &&
  byte_at(data, 2) == 0xFF &&
  byte_at(data, 3) == 0xFF &&
  byte_at(data, 4) == 0xFF &&
  byte_at(data, 5) == 0xFF &&
  byte_at(data, 6) == 0xFF &&
  byte_at(data, 7) == 0x00
}

///|
fn ascii_from_byte(value : Int) -> Char {
  if value >= 32 && value <= 126 {
    value.to_char().unwrap()
  } else {
    ' '
  }
}

///|
fn descriptor_text(data : Array[Int], offset : Int) -> String {
  let chars : Array[Char] = []
  let mut i = 5
  while i < 18 {
    let b = byte_at(data, offset + i)
    if b == 0x0A || b == 0x0D {
      break
    }
    chars.push(ascii_from_byte(b))
    i = i + 1
  }
  String::from_array(chars).trim(chars=" \t\r\n").to_owned()
}
