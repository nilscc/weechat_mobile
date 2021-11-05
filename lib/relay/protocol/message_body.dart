import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/relay/protocol/decode_string.dart';
import 'package:weechat/relay/protocol/hdata.dart';
import 'package:weechat/relay/protocol/info_list.dart';

class RelayMessageBody {
  final ByteData _data;
  List<dynamic> objects() {
    final l = [];
    final length = _data.lengthInBytes;

    // skip ID
    int offset = strLength(0);

    while (offset < length) {
      final ty = objectType(offset);
      offset += 3;

      l.add(decodeObject(ty, offset));
      offset += objectLength(ty, offset);
    }

    return l;
  }

  RelayMessageBody(ByteData data) : _data = data;

  ByteBuffer get buffer => _data.buffer;

  String get id => decodeString(_data)!;

  String objectType(int offset) => String.fromCharCodes([
        _data.getUint8(offset),
        _data.getUint8(offset + 1),
        _data.getUint8(offset + 2),
      ]);

  int chrLength(int offset) => 1;
  String chrObject(int offset) => String.fromCharCode(_data.getUint8(offset));

  int intLength(int offset) => 4;
  int intObject(int offset) => _data.getInt32(offset);

  int lonLength(int offset) =>
      1 + stringLength(_data, offset: offset, lengthSize: 1);
  int lonObject(int offset) =>
      int.parse(decodeString(_data, offset: offset, lengthSize: 1)!);

  int strLength(int offset) => 4 + max(0, stringLength(_data, offset: offset));
  String? strObject(int offset) => decodeString(_data, offset: offset);

  int bufLength(int offset) => strLength(offset);
  ByteData? bufObject(int offset) {
    final len = _data.getInt32(offset);
    if (len == -1) return null;
    offset += 4;
    return _data.buffer.asByteData(offset, len);
  }

  int ptrLength(int offset) =>
      1 + stringLength(_data, offset: offset, lengthSize: 1);
  String ptrObject(int offset) =>
      '0x' + decodeString(_data, offset: offset, lengthSize: 1)!;

  int timLength(int offset) =>
      1 + stringLength(_data, offset: offset, lengthSize: 1);
  int timObject(int offset) =>
      int.parse(decodeString(_data, offset: offset, lengthSize: 1)!);

  int htbLength(int offset) {
    final typeKeys = objectType(offset);
    int res = 3;
    final typeValues = objectType(offset + res);
    res += 3;

    final count = intObject(offset + res);
    res += intLength(offset + res);

    for (var i = 0; i < count; ++i) {
      res += objectLength(typeKeys, offset + res);
      res += objectLength(typeValues, offset + res);
    }

    return res;
  }

  HashMap<dynamic, dynamic> htbObject(int offset) {
    HashMap<dynamic, dynamic> res = HashMap();

    final typeKeys = objectType(offset);
    offset += 3;
    final typeValues = objectType(offset);
    offset += 3;

    final count = intObject(offset);
    offset += intLength(offset);

    for (var i = 0; i < count; ++i) {
      final key = decodeObject(typeKeys, offset);
      offset += objectLength(typeKeys, offset);

      final value = decodeObject(typeValues, offset);
      offset += objectLength(typeValues, offset);

      res[key] = value;
    }

    return res;
  }

  int hdaLength(int offset) {
    int res = 0;

    final hPath = strObject(offset);
    res += strLength(offset);

    final keys = strObject(offset + res);
    res += strLength(offset + res);

    final count = intObject(offset + res);
    res += intLength(offset + res);

    if (hPath != null && keys != null && count > 0) {
      final hPathElements = hPath.split('/').length;

      // convert string of keys into list with name/type tuples
      final List<RelayHDataKeyNameType> keyTypes = [];
      for (var nameType in keys.split(',')) {
        final t = nameType.split(':');
        keyTypes.add(RelayHDataKeyNameType(t[0], t[1]));
      }

      for (var i = 0; i < count; ++i) {
        for (var p = 0; p < hPathElements; ++p) {
          res += ptrLength(offset + res);
        }
        for (var nameType in keyTypes) {
          res += objectLength(nameType.type, offset + res);
        }
      }
    }

    return res;
  }

  RelayHData hdaObject(int offset) {
    final hPath = strObject(offset);
    offset += strLength(offset);

    final keys = strObject(offset);
    offset += strLength(offset);

    final count = intObject(offset);
    offset += intLength(offset);

    if (hPath != null && keys != null && count > 0) {
      final hPathElements = hPath.split('/').length;

      // convert string of keys into list with name/type tuples
      final List<RelayHDataKeyNameType> keyTypes = [];
      for (var nameType in keys.split(',')) {
        final t = nameType.split(':');
        keyTypes.add(RelayHDataKeyNameType(t[0], t[1]));
      }

      final List<RelayHDataObject> objects = [];
      for (var i = 0; i < count; ++i) {
        // parse all p-path pointers
        final List<String> pPath = [];
        for (var p = 0; p < hPathElements; ++p) {
          pPath.add(ptrObject(offset));
          offset += ptrLength(offset);
        }

        final List<dynamic> values = [];
        for (var nameType in keyTypes) {
          values.add(decodeObject(nameType.type, offset));
          offset += objectLength(nameType.type, offset);
        }

        objects.add(RelayHDataObject(
          pPath: pPath,
          values: values,
        ));
      }

      return RelayHData(
        hPath: hPath,
        keys: keyTypes,
        objects: objects,
      );
    } else
      return RelayHData(hPath: null, keys: null, objects: []);
  }

  int infLength(int offset) {
    final l1 = max(0, stringLength(_data, offset: offset));
    final l2 = max(0, stringLength(_data, offset: offset + 4 + l1));
    return 8 + l1 + l2;
  }

  Tuple2<String?, String?> infObject(int offset) {
    final s1 = decodeString(_data, offset: offset);
    final int l1 = max(0, stringLength(_data, offset: offset));
    final s2 = decodeString(_data, offset: offset + 4 + l1);
    return Tuple2(s1, s2);
  }

  int inlLength(int offset) {
    int res = 0;

    res += strLength(offset + res);
    final count = intObject(offset + res);
    res += intLength(offset + res);

    for (var i = 0; i < count; ++i) {
      final itemCount = intObject(offset + res);
      res += intLength(offset + res);

      for (var e = 0; e < itemCount; ++e) {
        res += strLength(offset + res);
        final entryType = objectType(offset + res);
        res += 3;
        res += objectLength(entryType, offset + res);
      }
    }

    return res;
  }

  RelayInfoList inlObject(int offset) {
    final name = strObject(offset);
    offset += strLength(offset);

    final count = intObject(offset);
    offset += intLength(offset);

    final List<RelayInfoListItem> items = [];
    for (var i = 0; i < count; ++i) {
      final itemCount = intObject(offset);
      offset += intLength(offset);

      final List<RelayInfoListItemEntry> entries = [];
      for (var e = 0; e < itemCount; ++e) {
        final entryName = strObject(offset);
        offset += strLength(offset);

        final entryType = objectType(offset);
        offset += 3;

        final dynamic entryValue = decodeObject(entryType, offset);
        offset += objectLength(entryType, offset);

        entries.add(RelayInfoListItemEntry(
          name: entryName,
          value: entryValue,
        ));
      }

      items.add(RelayInfoListItem(entries: entries));
    }

    return RelayInfoList(name: name!, items: items);
  }

  int arrLength(int offset) {
    final String elemType = objectType(offset);
    final int numElems = _data.getUint32(offset + 3);

    int res = 7; // current position in array
    for (var i = 0; i < numElems; ++i) {
      res += objectLength(elemType, offset + res);
    }

    return res;
  }

  List<dynamic> arrObject(int offset) {
    final String elemType = objectType(offset);
    offset += 3;

    final int numElems = _data.getUint32(offset);
    offset += 4;

    final res = [];
    for (var i = 0; i < numElems; ++i) {
      res.add(decodeObject(elemType, offset));
      offset += objectLength(elemType, offset);
    }
    return res;
  }

  dynamic decodeObject(type, offset) {
    switch (type) {
      case 'chr':
        return chrObject(offset);
      case 'int':
        return intObject(offset);
      case 'lon':
        return lonObject(offset);
      case 'str':
        return strObject(offset);
      case 'buf':
        return bufObject(offset);
      case 'ptr':
        return ptrObject(offset);
      case 'tim':
        return timObject(offset);
      case 'htb':
        return htbObject(offset);
      case 'hda':
        return hdaObject(offset);
      case 'inf':
        return infObject(offset);
      case 'inl':
        return inlObject(offset);
      case 'arr':
        return arrObject(offset);
      default:
        throw 'Decode object not implemented for type: $type';
    }
  }

  int objectLength(type, offset) {
    switch (type) {
      case 'chr':
        return chrLength(offset);
      case 'int':
        return intLength(offset);
      case 'lon':
        return lonLength(offset);
      case 'str':
        return strLength(offset);
      case 'buf':
        return bufLength(offset);
      case 'ptr':
        return ptrLength(offset);
      case 'tim':
        return timLength(offset);
      case 'htb':
        return htbLength(offset);
      case 'hda':
        return hdaLength(offset);
      case 'inf':
        return infLength(offset);
      case 'inl':
        return inlLength(offset);
      case 'arr':
        return arrLength(offset);
      default:
        throw 'Object length not implemented for type: $type';
    }
  }
}
