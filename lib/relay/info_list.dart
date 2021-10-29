class RelayInfoList {
  final String name;
  final List<RelayInfoListItem> items;

  int get count => items.length;

  RelayInfoList({
    required this.name,
    required this.items,
  });
}

class RelayInfoListItem {
  List<RelayInfoListItemEntry> entries;

  int get count => entries.length;

  RelayInfoListItem({
    required this.entries,
  });
}

class RelayInfoListItemEntry {
  final String? name;
  final dynamic value;

  RelayInfoListItemEntry({
    required this.name,
    required this.value,
  });
}
