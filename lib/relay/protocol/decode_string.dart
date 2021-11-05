import 'dart:convert';
import 'dart:typed_data';

int stringLength(ByteData data, {int offset: 0, int lengthSize: 4}) {
  if (lengthSize == 1) return data.getInt8(offset);
  if (lengthSize == 4) return data.getInt32(offset);

  throw 'Impossible string length size: $lengthSize';
}

String? decodeString(ByteData data, {int offset = 0, int lengthSize: 4}) {
  final len = stringLength(data, offset: offset, lengthSize: lengthSize);
  if (len == -1) return null;

  offset += lengthSize;

  return utf8.decode(data.buffer.asUint8List().sublist(offset, offset + len));
}

List<int> encodeString(String s, {lengthSize: 4}) {
  if (lengthSize == 4) {
    int l = s.length;
    return [
          (l & 0xFF000000) >> 6,
          (l & 0x00FF0000) >> 4,
          (l & 0x0000FF00) >> 2,
          (l & 0x000000FF) >> 0,
        ] +
        s.codeUnits;
  }
  else if (lengthSize == 1)
    return [ (s.length & 0xFF) ] + s.codeUnits;
  else
    throw 'Impossible encode for length size: $lengthSize';
}
