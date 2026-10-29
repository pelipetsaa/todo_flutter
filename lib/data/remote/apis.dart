import 'package:dio/dio.dart';

import '../../core/api/api_routes.dart';
import '../../core/dto/dtos.dart';

class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  Future<TokenPairDto> login(EmailCredentialsDto credentials) => _tokens(ApiRoutes.authLogin, credentials.toJson());

  Future<TokenPairDto> register(EmailCredentialsDto credentials) =>
      _tokens(ApiRoutes.authRegister, credentials.toJson());

  Future<TokenPairDto> loginWithGoogle(String idToken) =>
      _tokens(ApiRoutes.authGoogle, GoogleLoginDto(idToken: idToken).toJson());

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(ApiRoutes.authLogout, data: RefreshTokenDto(refreshToken: refreshToken).toJson());
  }

  Future<TokenPairDto> _tokens(String path, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: body);
    return TokenPairDto.fromJson(response.data!);
  }
}

class TodoApi {
  const TodoApi(this._dio);

  final Dio _dio;

  Future<List<TodoDto>> getTodos(DateTime from, DateTime to) async {
    final response = await _dio.get<List<dynamic>>(
      ApiRoutes.todos,
      queryParameters: {ApiRoutes.queryFrom: formatInstant(from), ApiRoutes.queryTo: formatInstant(to)},
    );
    return response.data!.map((json) => TodoDto.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<TodoDto> getTodo(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiRoutes.todo(id));
    return TodoDto.fromJson(response.data!);
  }

  Future<TodoDto> create(TodoInputDto input) async {
    final response = await _dio.post<Map<String, dynamic>>(ApiRoutes.todos, data: input.toJson());
    return TodoDto.fromJson(response.data!);
  }

  Future<TodoDto> update(String id, TodoInputDto input) async {
    final response = await _dio.put<Map<String, dynamic>>(ApiRoutes.todo(id), data: input.toJson());
    return TodoDto.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>(ApiRoutes.todo(id));
  }
}
