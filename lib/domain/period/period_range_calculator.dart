import '../model/models.dart';
import '../time/time_zone.dart';

/// Weeks start on Monday. Boundaries are local midnights in [_timeZone], so DST changes are handled by the zone.
class PeriodRangeCalculator {
  const PeriodRangeCalculator([this._timeZone = const DeviceTimeZone()]);

  final TimeZone _timeZone;

  TimeRange rangeFor(Period period, DateTime now) {
    final today = _timeZone.wallClock(now);
    final (year, month, day) = (today.year, today.month, today.day);
    final monday = day - (today.weekday - DateTime.monday);
    final (from, to) = switch (period) {
      Period.today => (_timeZone.instantOf(year, month, day), _timeZone.instantOf(year, month, day + 1)),
      Period.week => (_timeZone.instantOf(year, month, monday), _timeZone.instantOf(year, month, monday + 7)),
      Period.month => (_timeZone.instantOf(year, month), _timeZone.instantOf(year, month + 1)),
    };
    return TimeRange(from: from, to: to);
  }
}
