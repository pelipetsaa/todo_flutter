import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/domain/period/period_range_calculator.dart';

// Boundaries are local midnights; the calculator returns them in UTC, and DateTime equality
// also compares isUtc, so expectations are local calendar values converted to UTC.
DateTime at(int year, [int month = 1, int day = 1]) => DateTime(year, month, day).toUtc();

void main() {
  const calculator = PeriodRangeCalculator();

  TimeRange range(Period period, DateTime now) => calculator.rangeFor(period, now);

  test('today spans from local midnight to the next one', () {
    final r = range(Period.today, DateTime(2026, 10, 29, 13, 45));
    expect(r.from, at(2026, 10, 29));
    expect(r.to, at(2026, 10, 30));
  });

  test('week starts on Monday', () {
    // 29 Oct 2026 is a Thursday.
    final r = range(Period.week, DateTime(2026, 10, 29, 8));
    expect(r.from, at(2026, 10, 26));
    expect(r.to, at(2026, 11, 2));
  });

  test('week on Monday and Sunday stays the same week', () {
    expect(range(Period.week, DateTime(2026, 10, 26)).from, at(2026, 10, 26));
    expect(range(Period.week, DateTime(2026, 11, 1, 23, 59)).from, at(2026, 10, 26));
  });

  test('week crossing the year boundary', () {
    // 1 Jan 2027 is a Friday.
    final r = range(Period.week, DateTime(2027, 1, 1, 12));
    expect(r.from, at(2026, 12, 28));
    expect(r.to, at(2027, 1, 4));
  });

  test('month spans from the first day to the first day of the next month', () {
    final r = range(Period.month, DateTime(2026, 10, 29));
    expect(r.from, at(2026, 10));
    expect(r.to, at(2026, 11));
  });

  test('December rolls over into the next year', () {
    final r = range(Period.month, DateTime(2026, 12, 31, 23, 59));
    expect(r.from, at(2026, 12));
    expect(r.to, at(2027));
  });

  test('February in a leap year', () {
    final r = range(Period.month, DateTime(2028, 2, 10));
    expect(r.to.difference(r.from).inDays, closeTo(29, 1)); // DST may shift the length by an hour.
    expect(r.to, at(2028, 3));
  });

  test('the range is in UTC and contains now', () {
    final now = DateTime(2026, 10, 29, 13);
    final r = range(Period.today, now);
    expect(r.from.isUtc, isTrue);
    expect(r.contains(now), isTrue);
    expect(r.contains(r.to), isFalse);
  });
}
