import 'package:flutter/widgets.dart';

import '../../domain/error/domain_error.dart';
import '../../domain/model/models.dart';

/// UI texts in English and Russian, the same as `composeResources/values*/strings.xml` in ToDoList.
class AppStrings {
  const AppStrings._(this._ru);

  static const en = AppStrings._(false);
  static const ru = AppStrings._(true);

  static const supportedLocales = [Locale('en'), Locale('ru')];

  static AppStrings of(BuildContext context) => Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

  final bool _ru;

  String _t(String en, String ru) => _ru ? ru : en;

  String get appName => 'ToDo';

  String get loginTitle => _t('Sign in', 'Вход');
  String get loginSubtitle =>
      _t('Welcome back! Sign in to see your todos.', 'С возвращением! Войдите, чтобы увидеть свои задачи.');
  String get email => _t('Email', 'Эл. почта');
  String get password => _t('Password', 'Пароль');
  String get confirmPassword => _t('Confirm password', 'Повторите пароль');
  String get signIn => _t('Sign in', 'Войти');
  String get signInWithGoogle => _t('Continue with Google', 'Войти через Google');
  String get or => _t('or', 'или');
  String get noAccount => _t('No account yet? Create one', 'Нет аккаунта? Зарегистрируйтесь');
  String get registerTitle => _t('Create account', 'Регистрация');
  String get registerSubtitle => _t(
    'Use your email and a password with at least 8 characters.',
    'Укажите эл. почту и пароль не короче 8 символов.',
  );
  String get createAccount => _t('Create account', 'Зарегистрироваться');
  String get back => _t('Back', 'Назад');

  String get todosTitle => _t('My todos', 'Мои задачи');
  String get logout => _t('Log out', 'Выйти');
  String get addTodo => _t('Add todo', 'Добавить задачу');
  String get emptyHint => _t('Tap + to add a todo', 'Нажмите +, чтобы добавить задачу');
  String get retry => _t('Retry', 'Повторить');

  String get newTodoTitle => _t('New todo', 'Новая задача');
  String get editTodoTitle => _t('Edit todo', 'Редактирование');
  String get fieldTitle => _t('Title', 'Название');
  String get fieldDescription => _t('Description', 'Описание');
  String get fieldDate => _t('Date', 'Дата');
  String get fieldTime => _t('Time', 'Время');
  String get fieldStatus => _t('Status', 'Статус');
  String get save => _t('Save', 'Сохранить');
  String get delete => _t('Delete', 'Удалить');
  String get cancel => _t('Cancel', 'Отмена');
  String get ok => _t('OK', 'ОК');
  String get deleteConfirmTitle => _t('Delete this todo?', 'Удалить задачу?');
  String get deleteConfirmMessage => _t('This action cannot be undone.', 'Это действие нельзя отменить.');

  String get errorInvalidCredentials => _t('Invalid email or password.', 'Неверная эл. почта или пароль.');
  String get errorGoogleFailed =>
      _t('Google sign-in failed. Please try again.', 'Не удалось войти через Google. Попробуйте ещё раз.');
  String get errorEmailTaken =>
      _t('An account with this email already exists.', 'Аккаунт с этой эл. почтой уже существует.');

  String period(Period period) => switch (period) {
    Period.today => _t('Today', 'Сегодня'),
    Period.week => _t('This week', 'Неделя'),
    Period.month => _t('This month', 'Месяц'),
  };

  String emptyPeriod(Period period) => switch (period) {
    Period.today => _t('Nothing planned for today', 'На сегодня ничего не запланировано'),
    Period.week => _t('Nothing planned for this week', 'На эту неделю ничего не запланировано'),
    Period.month => _t('Nothing planned for this month', 'На этот месяц ничего не запланировано'),
  };

  String status(TodoStatus status) => switch (status) {
    TodoStatus.todo => _t('To do', 'К выполнению'),
    TodoStatus.inProgress => _t('In progress', 'В работе'),
    TodoStatus.done => _t('Done', 'Готово'),
  };

  String error(DomainError error) => switch (error) {
    NetworkError() => _t(
      'No connection to the server. Check your network and try again.',
      'Нет связи с сервером. Проверьте подключение и попробуйте ещё раз.',
    ),
    UnauthorizedError() => _t('Your session has expired. Please sign in again.', 'Сессия истекла. Войдите снова.'),
    NotFoundError() => _t('This todo no longer exists.', 'Эта задача больше не существует.'),
    ConflictError() => _t('This item already exists.', 'Такая запись уже существует.'),
    TooManyRequestsError() => _t(
      'Too many attempts. Please wait a minute and try again.',
      'Слишком много попыток. Подождите минуту и попробуйте снова.',
    ),
    ValidationFailure() => _t('Please check the entered data.', 'Проверьте введённые данные.'),
    UnknownError() => _t('Something went wrong. Please try again.', 'Что-то пошло не так. Попробуйте ещё раз.'),
  };

  String validation(ValidationError error) => switch (error) {
    ValidationError.emailBlank => _t('Enter your email', 'Введите эл. почту'),
    ValidationError.emailInvalid => _t('Enter a valid email', 'Введите корректный адрес эл. почты'),
    ValidationError.passwordBlank => _t('Enter your password', 'Введите пароль'),
    ValidationError.passwordTooShort => _t(
      'Password must be at least 8 characters',
      'Пароль должен быть не короче 8 символов',
    ),
    ValidationError.passwordTooLong => _t(
      'Password must be at most 128 characters',
      'Пароль должен быть не длиннее 128 символов',
    ),
    ValidationError.passwordMismatch => _t('Passwords do not match', 'Пароли не совпадают'),
    ValidationError.titleBlank => _t('Enter a title', 'Введите название'),
    ValidationError.titleTooLong => _t(
      'Title must be at most 200 characters',
      'Название должно быть не длиннее 200 символов',
    ),
    ValidationError.descriptionTooLong => _t(
      'Description must be at most 2000 characters',
      'Описание должно быть не длиннее 2000 символов',
    ),
  };

  /// Monday first, matching [DateTime.weekday] - 1.
  List<String> get _dayNamesShort =>
      _ru ? const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'] : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<String> get _monthNamesShort => _ru
      ? const ['янв.', 'февр.', 'мар.', 'апр.', 'мая', 'июн.', 'июл.', 'авг.', 'сент.', 'окт.', 'нояб.', 'дек.']
      : const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// "Thu, 29 Oct 2026" / "Чт, 29 окт. 2026".
  String formatDate(DateTime date) =>
      '${_dayNamesShort[date.weekday - 1]}, ${date.day} ${_monthNamesShort[date.month - 1]} ${date.year}';

  /// 24-hour "09:05".
  String formatTime(int hour, int minute) => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
