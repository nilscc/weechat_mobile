import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:weechat/relay/protocol/message_body.dart';

// https://weechat.org/files/doc/stable/weechat_relay_protocol.en.html#messages

class RelayParser {
  final Uint8List _input;

  RelayParser(input) : _input = input;

  int length() {
    return ByteData.sublistView(_input, 0, 4).getUint32(0);
  }

  bool compressed() {
    return _input[4] == 1;
  }

  RelayMessageBody body() {
    if (compressed())
      return RelayMessageBody(ByteData.sublistView(zlib.decode(_input.sublist(5)) as Uint8List));
    else
      return RelayMessageBody(ByteData.sublistView(_input.sublist(5)));
  }
}