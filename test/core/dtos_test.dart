import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/core/dto/dtos.dart';

/// The JSON contract shared with the server (`core/dto` in ToDoList).
void main() {
  test('a todo round-trips with ISO instants', () {
    final json =
        jsonDecode('''
      {"id": "5f0c", "title": "Buy milk", "description": "two",
       "dueAt": "2026-10-29T13:00:00Z", "status": "IN_PROGRESS",
       "createdAt": "2026-10-28T10:00:00.123456Z", "updatedAt": "2026-10-28T10:00:00.123456Z"}
    ''')
            as Map<String, dynamic>;

    final dto = TodoDto.fromJson(json);

    expect(dto.dueAt, DateTime.utc(2026, 10, 29, 13));
    expect(dto.status, TodoStatusDto.inProgress);
    // The server stores microseconds; they must survive parsing.
    expect(dto.createdAt, DateTime.utc(2026, 10, 28, 10, 0, 0, 123, 456));

    final input = TodoInputDto(title: dto.title, description: dto.description, dueAt: dto.dueAt, status: dto.status);
    expect(input.toJson(), {
      'title': 'Buy milk',
      'description': 'two',
      'dueAt': '2026-10-29T13:00:00.000Z',
      'status': 'IN_PROGRESS',
    });
    expect(DateTime.parse(input.toJson()['dueAt'] as String), dto.dueAt);
  });

  test('local due dates are sent as UTC instants', () {
    final local = DateTime.utc(2026, 10, 29, 13).toLocal();
    final input = TodoInputDto(title: 't', description: '', dueAt: local, status: TodoStatusDto.todo);
    expect(input.toJson()['dueAt'], '2026-10-29T13:00:00.000Z');
  });

  test('a missing description is read as empty', () {
    final dto = TodoDto.fromJson({
      'id': '1',
      'title': 't',
      'dueAt': '2026-10-29T13:00:00Z',
      'status': 'DONE',
      'createdAt': '2026-10-29T13:00:00Z',
      'updatedAt': '2026-10-29T13:00:00Z',
    });
    expect(dto.description, '');
    expect(dto.status, TodoStatusDto.done);
  });

  test('an unknown status is rejected', () {
    expect(() => TodoStatusDto.fromWireName('ARCHIVED'), throwsFormatException);
  });

  test('auth bodies', () {
    expect(const EmailCredentialsDto(email: 'a@b.co', password: 'secret').toJson(), {
      'email': 'a@b.co',
      'password': 'secret',
    });
    expect(const GoogleLoginDto(idToken: 'id').toJson(), {'idToken': 'id'});
    expect(const RefreshTokenDto(refreshToken: 'r').toJson(), {'refreshToken': 'r'});

    final pair = TokenPairDto.fromJson({'accessToken': 'a', 'refreshToken': 'r', 'expiresInSeconds': 900});
    expect((pair.accessToken, pair.refreshToken, pair.expiresInSeconds), ('a', 'r', 900));
  });

  test('error responses are parsed when they have the expected shape', () {
    final error = ErrorResponse.tryParse({'code': 'EMAIL_TAKEN', 'message': 'taken'});
    expect((error?.code, error?.message), ('EMAIL_TAKEN', 'taken'));
    expect(ErrorResponse.tryParse('<html>Bad gateway</html>'), isNull);
    expect(ErrorResponse.tryParse({'code': 'X'}), isNull);
  });
}
