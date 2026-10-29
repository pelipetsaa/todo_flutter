import '../model/models.dart';

/// Weeks start on Monday. Boundaries are local midnights in the device time zone; [DateTime]'s
/// calendar constructor normalizes overflowing days and months and handles DST changes.
class PeriodRangeCalculator {
  const PeriodRangeCalculator();

  TimeRange rangeFor(Period period, DateTime now) {
    final local = now.toLocal();
    final (start, endExclusive) = switch (period) {
      Period.today => (DateTime(local.year, local.month, local.day), DateTime(local.year, local.month, local.day + 1)),
      Period.week => (
        DateTime(local.year, local.month, local.day - (local.weekday - DateTime.monday)),
        DateTime(local.year, local.month, local.day - (local.weekday - DateTime.monday) + 7),
      ),
      Period.month => (DateTime(local.year, local.month), DateTime(local.year, local.month + 1)),
    };
    return TimeRange(from: start.toUtc(), to: endExclusive.toUtc());
  }
}
