import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

// https://weechat.org/files/doc/stable/weechat_relay_protocol.en.html#messages

class RelayParser {
  final Uint8List _input;
  ByteData? _data;

  RelayParser(input) : _input = input;

  int length() {
    return ByteData.sublistView(_input, 0, 4).getUint32(0);
  }

  bool compressed() {
    return _input[4] == 1;
  }

  void decompress() {
    if (compressed())
      _data = ByteData.sublistView(zlib.decode(_input.sublist(5)) as Uint8List);
    else
      _data = ByteData.sublistView(_input, 5);
  }

  static String _decodeString(ByteData data, [int offset = 0]) {
    final len = data.getUint32(offset);
    return String.fromCharCodes(data.buffer.asUint8List(), offset+4, offset+4+len);
  }

  String id() {
    return _decodeString(_data!);
  }

  Iterable<RelayTypes> types() {

  }

}

class RelayTypes {

}