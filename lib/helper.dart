/// ====== CORE LOGIC ======
String buildDynamicQris(String staticQris, String amount) {
  if (staticQris.isEmpty) {
    throw Exception("Static QRIS kosong.");
  }
  if (!RegExp(r'^\d+$').hasMatch(amount)) {
    throw Exception("Amount harus angka bulat (tanpa titik/koma).");
  }

  // Parse TLV ke map berurut
  final entries = parseTlv(staticQris);

  // 1) PIM (Tag '01') jadi '12'
  upsert(entries, '01', '12');

  // 2) Amount (Tag '54')
  upsert(entries, '54', amount);

  // 3) Buang CRC lama (Tag '63') kalau ada — nanti dihitung ulang
  entries.removeWhere((e) => e.tag == '63');

  // Rebuild tanpa CRC
  final payloadNoCRC = buildTlv(entries);

  // Tambahin tag CRC ('63' + '04' + value) — value dihitung dari payloadNoCRC + '6304'
  final crc = crc16('${payloadNoCRC}6304');
  final full = '${payloadNoCRC}6304$crc';
  return full;
}

/// Representasi TLV
class Tlv {
  final String tag; // 2 chars
  String value; // length dinamis
  Tlv(this.tag, this.value);
}

/// Parse TLV generic (2-digit tag, 2-digit length, value)
List<Tlv> parseTlv(String data) {
  final list = <Tlv>[];
  int i = 0;
  while (i + 4 <= data.length) {
    final tag = data.substring(i, i + 2);
    final lenStr = data.substring(i + 2, i + 4);
    final len = int.tryParse(lenStr);
    if (len == null || len < 0) {
      throw Exception("Format TLV salah di posisi $i (length).");
    }
    final start = i + 4;
    final end = start + len;
    if (end > data.length) {
      throw Exception("Format TLV salah (value out of range).");
    }
    final value = data.substring(start, end);
    list.add(Tlv(tag, value));
    i = end;
  }

  // minimal harus ada CRC (atau bekasnya). Kalau parsing pas, i==data.length
  if (i != data.length) {
    throw Exception("Sisa data TLV tidak terbaca. QRIS mungkin korup.");
  }
  return list;
}

/// Build TLV kembali dari list (tanpa CRC otomatis)
String buildTlv(List<Tlv> entries) {
  final sb = StringBuffer();
  for (final e in entries) {
    final len = e.value.length.toString().padLeft(2, '0');
    sb.write(e.tag);
    sb.write(len);
    sb.write(e.value);
  }
  return sb.toString();
}

/// Insert/Update tag (jaga urutan: QRIS biasanya urut numerik)
void upsert(List<Tlv> entries, String tag, String value) {
  final idx = entries.indexWhere((e) => e.tag == tag);
  if (idx >= 0) {
    entries[idx].value = value;
  } else {
    // sisipin sesuai urutan numeric tag
    int insertAt = entries.length;
    for (int i = 0; i < entries.length; i++) {
      if (int.parse(tag) < int.parse(entries[i].tag)) {
        insertAt = i;
        break;
      }
    }
    entries.insert(insertAt, Tlv(tag, value));
  }
}

/// CRC16-CCITT (poly 0x1021), initial 0xFFFF, big-endian, over ASCII bytes
String crc16(String str) {
  int crc = 0xFFFF;
  for (int i = 0; i < str.length; i++) {
    crc ^= (str.codeUnitAt(i) << 8);
    for (int j = 0; j < 8; j++) {
      if ((crc & 0x8000) != 0) {
        crc = (crc << 1) ^ 0x1021;
      } else {
        crc <<= 1;
      }
      crc &= 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}
