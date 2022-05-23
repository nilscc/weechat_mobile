import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/relay/protocol/decode_string.dart';
import 'package:weechat/relay/protocol/message_body.dart';

import 'parser_data.dart';

void main() {
  group('RelayMessageBody', () {
    test('Body ID', _bodyId);
  });

  group('Decoders', () {
    test('Decode char', _decodeChar);
    test('Decode integer', _decodeInteger);
    test('Decode long integer', _decodeLongInteger);
    test('Decode string', _decodeString);
    test('Decode buffer', _decodeBuffer);
    test('Decode pointer', _decodePointer);
    test('Decode time', _decodeTime);
    test('Decode hash table', _decodeHashTable);
    test('Decode hdata', _decodeHData);
    test('Decode info', _decodeInfo);
    test('Decode info list', _decodeInfoList);
    test('Decode array', _decodeArray);
    test('Other objects', _decodeObject);
  });
}

void _bodyId() {
  final b =
      RelayMessageBody(ByteData.sublistView(Uint8List.fromList(DECOMP_DATA)));
  expect(b.id, equals('handshake'));
}

ByteData _fromList(list) => ByteData.sublistView(Uint8List.fromList(list));

final _chr01 = _fromList([0x41]);

void _decodeChar() {
  expect(RelayMessageBody(_chr01).chrObject(0), equals('A'));
  expect(RelayMessageBody(_chr01).chrLength(0), equals(_chr01.lengthInBytes));
}

final _int01 = _fromList([0x00, 0x01, 0xE2, 0x40]);
final _int02 = _fromList([0xFF, 0xFE, 0x1D, 0xC0]);

void _decodeInteger() {
  expect(RelayMessageBody(_int01).intObject(0), equals(123456));
  expect(RelayMessageBody(_int01).intLength(0), equals(_int01.lengthInBytes));
  expect(RelayMessageBody(_int02).intObject(0), equals(-123456));
  expect(RelayMessageBody(_int02).intLength(0), equals(_int02.lengthInBytes));
}

final _lon01 = _fromList(
    [0x0A, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30]);
final _lon02 = _fromList(
    [0x0B, 0x2D, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30]);

void _decodeLongInteger() {
  expect(RelayMessageBody(_lon01).lonObject(0), equals(1234567890));
  expect(RelayMessageBody(_lon01).lonLength(0), equals(_lon01.lengthInBytes));

  expect(RelayMessageBody(_lon02).lonObject(0), equals(-1234567890));
  expect(RelayMessageBody(_lon02).lonLength(0), equals(_lon02.lengthInBytes));
}

final _str01 =
    _fromList([0x00, 0x00, 0x00, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F]);
final _str02 = _fromList([0x00, 0x00, 0x00, 0x00]);
final _str03 = _fromList([0xFF, 0xFF, 0xFF, 0xFF]);

void _decodeString() {
  expect(RelayMessageBody(_str01).strObject(0), equals('hello'));
  expect(RelayMessageBody(_str01).strLength(0), equals(_str01.lengthInBytes));

  expect(RelayMessageBody(_str02).strObject(0), equals(''));
  expect(RelayMessageBody(_str02).strLength(0), equals(_str02.lengthInBytes));

  expect(RelayMessageBody(_str03).strObject(0), equals(null));
  expect(RelayMessageBody(_str02).strLength(0), equals(_str03.lengthInBytes));
}

void _decodeBuffer() {
  final b1 = RelayMessageBody(_str01).bufObject(0)!;
  expect(b1.lengthInBytes, equals(5));
  expect(b1.offsetInBytes, equals(4));
  expect(b1.getUint8(0), equals(0x68));
  expect(b1.getUint8(1), equals(0x65));
  expect(b1.getUint8(2), equals(0x6C));
  expect(b1.getUint8(3), equals(0x6C));
  expect(b1.getUint8(4), equals(0x6F));
  expect(RelayMessageBody(_str01).bufLength(0), equals(_str01.lengthInBytes));

  final b2 = RelayMessageBody(_str02).bufObject(0)!;
  expect(b2.lengthInBytes, equals(0));
  expect(RelayMessageBody(_str02).bufLength(0), equals(_str02.lengthInBytes));

  expect(RelayMessageBody(_str03).bufObject(0), equals(null));
  expect(RelayMessageBody(_str03).bufLength(0), equals(_str03.lengthInBytes));
}

final _ptr01 =
    _fromList([0x09, 0x31, 0x61, 0x32, 0x62, 0x33, 0x63, 0x34, 0x64, 0x35]);
final _ptr02 = _fromList([0x01, 0x30]);

void _decodePointer() {
  expect(RelayMessageBody(_ptr01).ptrObject(0), equals('0x1a2b3c4d5'));
  expect(RelayMessageBody(_ptr01).ptrLength(0), equals(_ptr01.lengthInBytes));
  expect(RelayMessageBody(_ptr02).ptrObject(0), equals('0x0'));
  expect(RelayMessageBody(_ptr02).ptrLength(0), equals(_ptr02.lengthInBytes));
}

final _tim01 = _fromList(
    [0x0A, 0x31, 0x33, 0x32, 0x31, 0x39, 0x39, 0x33, 0x34, 0x35, 0x36]);

void _decodeTime() {
  expect(RelayMessageBody(_tim01).timObject(0), equals(1321993456));
  expect(RelayMessageBody(_tim01).timLength(0), equals(_tim01.lengthInBytes));
}

final _htb01 = _fromList('str'.codeUnits +
    'str'.codeUnits +
    [0x00, 0x00, 0x00, 0x02] +
    encodeString('key1') +
    encodeString('abc') +
    encodeString('key2') +
    encodeString('def'));

void _decodeHashTable() {
  final h01 = RelayMessageBody(_htb01).htbObject(0);

  expect(h01['key1'], equals('abc'));
  expect(h01['key2'], equals('def'));

  expect(RelayMessageBody(_htb01).htbLength(0), equals(_htb01.lengthInBytes));
}

final _hda01 = _fromList(encodeString('buffer') +
    encodeString('number:int,full_name:str') +
    [0x00, 0x00, 0x00, 0x02] +
    encodeString('12345', lengthSize: 1) +
    [0x00, 0x00, 0x00, 0x01] +
    encodeString('core.weechat') +
    encodeString('6789a', lengthSize: 1) +
    [0x00, 0x00, 0x00, 0x02] +
    encodeString('irc.server.libera'));

void _decodeHData() {
  final h01 = RelayMessageBody(_hda01).hdaObject(0);

  expect(h01.hPath, equals('buffer'));

  // test key/type pairs
  expect(h01.keys![0].name, equals('number'));
  expect(h01.keys![0].type, equals('int'));
  expect(h01.keys![1].name, equals('full_name'));
  expect(h01.keys![1].type, equals('str'));

  // test number of objects
  expect(h01.count, equals(2));

  // test first object
  expect(h01.objects[0].pPath.length, equals(1));
  expect(h01.objects[0].pPath[0], equals('0x12345'));
  expect(h01.objects[0].values.length, equals(2));
  expect(h01.objects[0].values[0], equals(1));
  expect(h01.objects[0].values[1], equals('core.weechat'));

  // test second object
  expect(h01.objects[1].pPath.length, equals(1));
  expect(h01.objects[1].pPath[0], equals('0x6789a'));
  expect(h01.objects[1].values[0], equals(2));
  expect(h01.objects[1].values[1], equals('irc.server.libera'));

  expect(RelayMessageBody(_hda01).hdaLength(0), equals(_hda01.lengthInBytes));
}

final _inf01 = _fromList(encodeString('name') + encodeString('value'));

void _decodeInfo() {
  final i01 = RelayMessageBody(_inf01).infObject(0);
  expect(i01.item1, equals('name'));
  expect(i01.item2, equals('value'));

  expect(RelayMessageBody(_inf01).infLength(0), equals(_inf01.lengthInBytes));
}

final _inl01 = _fromList(encodeString('buffer') +
    [0x00, 0x00, 0x00, 0x02] +
    [0x00, 0x00, 0x00, 0x03] +
    encodeString('pointer01') +
    'ptr'.codeUnits +
    encodeString('12345', lengthSize: 1) +
    encodeString('pointer02') +
    'ptr'.codeUnits +
    encodeString('23456', lengthSize: 1) +
    encodeString('pointer03') +
    'ptr'.codeUnits +
    encodeString('34567', lengthSize: 1) +
    [0x00, 0x00, 0x00, 0x01] +
    encodeString('pointer') +
    'ptr'.codeUnits +
    encodeString('6789a', lengthSize: 1));

void _decodeInfoList() {
  final i01 = RelayMessageBody(_inl01).inlObject(0);
  expect(i01.name, equals('buffer'));
  expect(i01.count, equals(2));

  expect(i01.items[0].count, equals(3));
  expect(i01.items[0].entries[0].name, equals('pointer01'));
  expect(i01.items[0].entries[0].value, equals('0x12345'));
  expect(i01.items[0].entries[1].name, equals('pointer02'));
  expect(i01.items[0].entries[1].value, equals('0x23456'));
  expect(i01.items[0].entries[2].name, equals('pointer03'));
  expect(i01.items[0].entries[2].value, equals('0x34567'));

  expect(i01.items[1].count, equals(1));
  expect(i01.items[1].entries[0].name, equals('pointer'));
  expect(i01.items[1].entries[0].value, equals('0x6789a'));

  expect(RelayMessageBody(_inl01).inlLength(0), equals(_inl01.lengthInBytes));
}

final _arr01 = _fromList('str'.codeUnits +
    [0x00, 0x00, 0x00, 0x02] +
    encodeString('abc') +
    encodeString('de'));

final _arr02 = _fromList('int'.codeUnits +
    [0x00, 0x00, 0x00, 0x03] +
    [0x00, 0x00, 0x00, 0x7B] +
    [0x00, 0x00, 0x01, 0xC8] +
    [0x00, 0x00, 0x03, 0x15]);

final _arr03 = _fromList('str'.codeUnits + [0x00, 0x00, 0x00, 0x00]);

void _decodeArray() {
  expect(RelayMessageBody(_arr01).arrObject(0), equals(['abc', 'de']));
  expect(RelayMessageBody(_arr01).arrLength(0),
      equals(_arr01.buffer.lengthInBytes));

  expect(RelayMessageBody(_arr02).arrObject(0), equals([123, 456, 789]));
  expect(RelayMessageBody(_arr03).arrLength(0),
      equals(_arr03.buffer.lengthInBytes));

  expect(RelayMessageBody(_arr03).arrObject(0), equals([]));
  expect(RelayMessageBody(_arr03).arrLength(0),
      equals(_arr03.buffer.lengthInBytes));
}

final _obj01 = _fromList([
  0,
  0,
  0,
  1,
  48,
  104,
  100,
  97,
  255,
  255,
  255,
  255,
  255,
  255,
  255,
  255,
  0,
  0,
  0,
  0
]);

void _decodeObject() {
  final b = RelayMessageBody(_obj01);
  print(b.id);
  print(b.objects());
}
