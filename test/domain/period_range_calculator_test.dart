import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/domain/period/period_range_calculator.dart';

import '../support/time_zones.dart';

// Every case runs in a fixed zone, independent of the machine; expectations are Berlin wall-clock times.
void main() {
  final calculator = PeriodRangeCalculator(berlin);

  TimeRange range(Period period, DateTime now) => calculator.rangeFor(period, now);

  /// The UTC instant of a Berlin wall-clock time.
  DateTime at(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0]) =>
      berlin.instantOf(year, month, day, hour, minute);

  test('today is local midnight to the next midnight', () {
    final r = range(Period.today, at(2026, 10, 29, 13, 45));
    expect(r.from, at(2026, 10, 29));
    expect(r.to, at(2026, 10, 30));
    expect(r.from, DateTime.utc(2026, 10, 28, 23)); // CET is UTC+1.
  });

  test('week starts on Monday', () {
    // 29 Oct 2026 is a Thursday.
    final r = range(Period.week, at(2026, 10, 29, 8));
    expect(r.from, at(2026, 10, 26));
    expect(r.to, at(2026, 11, 2));
  });

  test('week on Sunday belongs to the previous Monday', () {
    expect(range(Period.week, at(2026, 11, 1, 23, 59)).from, at(2026, 10, 26));
    expect(range(Period.week, at(2026, 10, 26)).from, at(2026, 10, 26));
  });

  test('week can span the year boundary', () {
    // 1 Jan 2027 is a Friday.
    final r = range(Period.week, at(2027, 1, 1, 12));
    expect(r.from, at(2026, 12, 28));
    expect(r.to, at(2027, 1, 4));
  });

  test('month covers the whole calendar month', () {
    final r = range(Period.month, at(2026, 10, 29));
    expect(r.from, at(2026, 10));
    expect(r.to, at(2026, 11));
  });

  test('December rolls over into the next year', () {
    final r = range(Period.month, at(2026, 12, 31, 23, 59));
    expect(r.from, at(2026, 12));
    expect(r.to, at(2027));
  });

  test('February in a leap year', () {
    final r = range(Period.month, at(2028, 2, 10));
    expect(r.to, at(2028, 3));
    expect(r.to.difference(r.from), const Duration(days: 29));
  });

  test('boundaries use the given time zone', () {
    // 23:30 UTC on 29 Oct is already 30 Oct in Berlin and still 29 Oct in New York.
    final now = DateTime.utc(2026, 10, 29, 23, 30);
    expect(range(Period.today, now).from, at(2026, 10, 30));
    final newYork = IanaTimeZone('America/New_York');
    expect(PeriodRangeCalculator(newYork).rangeFor(Period.today, now).from, newYork.instantOf(2026, 10, 29));
  });

  test('the day DST ends is 25 hours long', () {
    // Clocks in Berlin go back from 03:00 to 02:00 on 25 Oct 2026.
    final r = range(Period.today, at(2026, 10, 25, 12));
    expect(r.to.difference(r.from), const Duration(hours: 25));
  });

  test('the day DST starts is 23 hours long', () {
    final r = range(Period.today, at(2026, 3, 29, 12));
    expect(r.to.difference(r.from), const Duration(hours: 23));
  });

  test('the range is half-open and in UTC', () {
    final now = at(2026, 10, 29, 13);
    final r = range(Period.today, now);
    expect(r.from.isUtc, isTrue);
    expect(r.contains(r.from), isTrue);
    expect(r.contains(now), isTrue);
    expect(r.contains(r.to), isFalse);
  });
}
