class Event {
  final String eventName;
  final int? bufferId; // not sure if this is always set
  final dynamic body;

  Event(this.eventName, this.bufferId, [this.body]);

  @override
  String toString() =>
      "Event {eventName: $eventName, bufferId: $bufferId, body: $body}";
}
