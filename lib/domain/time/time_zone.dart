/// Converts between instants and the wall-clock time of one time zone, like kotlinx-datetime's `TimeZone` in
/// ToDoList. The app uses [DeviceTimeZone]; tests pass a fixed IANA zone to check DST and zone boundaries.
abstract interface class TimeZone {
  /// The wall-clock fields (year … minute, weekday) of [instant] in this zone.
  DateTime wallClock(DateTime instant);

  /// The UTC instant of a wall-clock time in this zone. Overflowing fields are normalized like
  /// [DateTime]'s constructor does, e.g. day 32 is the first day of the next month.
  DateTime instantOf(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0]);
}

/// The time zone of the device.
class DeviceTimeZone implements TimeZone {
  const DeviceTimeZone();

  @override
  DateTime wallClock(DateTime instant) => instant.toLocal();

  @override
  DateTime instantOf(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0]) =>
      DateTime(year, month, day, hour, minute).toUtc();
}
