import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_flutter/domain/time/time_zone.dart';

/// A fixed IANA zone, so time zone tests do not depend on the machine (CI runs in UTC).
class IanaTimeZone implements TimeZone {
  IanaTimeZone(String name) : _location = _locations(name);

  static tz.Location _locations(String name) {
    if (!_loaded) {
      tz_data.initializeTimeZones();
      _loaded = true;
    }
    return tz.getLocation(name);
  }

  static bool _loaded = false;

  final tz.Location _location;

  @override
  DateTime wallClock(DateTime instant) => tz.TZDateTime.from(instant, _location);

  @override
  DateTime instantOf(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0]) {
    // DateTime.utc normalizes overflowing fields (day 32, month 13) before the zone is applied.
    final fields = DateTime.utc(year, month, day, hour, minute);
    final local = tz.TZDateTime(_location, fields.year, fields.month, fields.day, fields.hour, fields.minute);
    return DateTime.fromMicrosecondsSinceEpoch(local.microsecondsSinceEpoch, isUtc: true);
  }
}

final berlin = IanaTimeZone('Europe/Berlin');
