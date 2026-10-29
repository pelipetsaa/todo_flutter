/// REST paths of the ToDo backend; the same contract as `core/api/ApiRoutes.kt` in ToDoList.
abstract final class ApiRoutes {
  static const base = '/api/v1';

  static const authPrefix = '$base/auth';
  static const authRegister = '$authPrefix/register';
  static const authLogin = '$authPrefix/login';
  static const authGoogle = '$authPrefix/google';
  static const authRefresh = '$authPrefix/refresh';
  static const authLogout = '$authPrefix/logout';

  static const me = '$base/me';

  static const todos = '$base/todos';
  static const queryFrom = 'from';
  static const queryTo = 'to';

  static const health = '/health';

  static String todo(String id) => '$todos/$id';
}
