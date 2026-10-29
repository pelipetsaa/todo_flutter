/// JSON bodies of the ToDo REST API; field names match `core/dto` in ToDoList.
/// Timestamps travel as ISO-8601 UTC instants, e.g. `2026-10-29T13:00:00Z`.
library;

class EmailCredentialsDto {
  const EmailCredentialsDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class GoogleLoginDto {
  const GoogleLoginDto({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() => {'idToken': idToken};
}

class RefreshTokenDto {
  const RefreshTokenDto({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

class TokenPairDto {
  const TokenPairDto({required this.accessToken, required this.refreshToken, required this.expiresInSeconds});

  factory TokenPairDto.fromJson(Map<String, dynamic> json) => TokenPairDto(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
  );

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
}

enum TodoStatusDto {
  todo('TODO'),
  inProgress('IN_PROGRESS'),
  done('DONE');

  const TodoStatusDto(this.wireName);

  final String wireName;

  static TodoStatusDto fromWireName(String value) => values.firstWhere(
    (status) => status.wireName == value,
    orElse: () => throw FormatException('Unknown todo status: $value'),
  );
}

class TodoInputDto {
  const TodoInputDto({required this.title, required this.description, required this.dueAt, required this.status});

  final String title;
  final String description;
  final DateTime dueAt;
  final TodoStatusDto status;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'dueAt': formatInstant(dueAt),
    'status': status.wireName,
  };
}

class TodoDto {
  const TodoDto({
    required this.id,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoDto.fromJson(Map<String, dynamic> json) => TodoDto(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    dueAt: DateTime.parse(json['dueAt'] as String),
    status: TodoStatusDto.fromWireName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String id;
  final String title;
  final String description;
  final DateTime dueAt;
  final TodoStatusDto status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// `{"code": "...", "message": "..."}`, returned with every non-2xx response.
class ErrorResponse {
  const ErrorResponse({required this.code, required this.message});

  static ErrorResponse? tryParse(Object? json) {
    if (json is! Map) return null;
    final code = json['code'];
    final message = json['message'];
    if (code is! String || message is! String) return null;
    return ErrorResponse(code: code, message: message);
  }

  final String code;
  final String message;
}

String formatInstant(DateTime instant) => instant.toUtc().toIso8601String();
