class RelayHData {
  final String? hPath;
  final List<RelayHDataKeyNameType>? keys;
  final List<RelayHDataObject> objects;

  int get count => objects.length;

  RelayHData({
    required this.hPath,
    required this.keys,
    required this.objects,
  });

  @override
  String toString() {
    final obj = [];

    for (final o in objects) {
      final val = [];
      for (var i = 0; i < (keys?.length ?? 0); ++i) {
        val.add('${keys![i].name}: [${keys![i].type}] ${o.values[i]}');
      }
      if (val.isNotEmpty)
        obj.add(o.pPath.toString() + ' {\n\t' + val.join(',\n\t') + '\n}');
    }

    return 'RelayHData(hPath: $hPath, objects: {\n${obj.join(",\n\n")}\n})'; // keys: $keys, objects: $objects)';
  }
}

class RelayHDataKeyNameType {
  final String name, type;

  RelayHDataKeyNameType(this.name, this.type);

  @override
  String toString() => '$name [$type]';
}

class RelayHDataObject {
  final List<String> pPath;
  final List<dynamic> values;

  RelayHDataObject({
    required this.pPath,
    required this.values,
  });

  @override
  String toString() => 'RelayHDataObject(pPath: $pPath, values: $values)';
}
