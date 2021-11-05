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
}

class RelayHDataKeyNameType {
  final String name, type;

  RelayHDataKeyNameType(this.name, this.type);
}

class RelayHDataObject {
  final List<String> pPath;
  final List<dynamic> values;

  RelayHDataObject({
    required this.pPath,
    required this.values,
  });
}
