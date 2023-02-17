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
        final ty = keys![i].type;
        var v = o.values[i];
        if (ty == 'chr') v = v.codeUnits.toString();
        val.add('${keys![i].name}: [$ty] $v');
      }
      if (val.isNotEmpty) {
        obj.add('${o.pPath} {\n\t${val.join(',\n\t')}\n}');
      }
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
