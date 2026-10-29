import '../domain_result.dart';
import '../error/domain_error.dart';
import '../model/models.dart';
import '../period/period_range_calculator.dart';
import '../repository/repositories.dart';
import '../time/time_zone.dart';
import '../validation/validators.dart';

/// Returns the current moment; injected so that tests can fix the time.
typedef Clock = DateTime Function();

class GetTodosForPeriodUseCase {
  const GetTodosForPeriodUseCase(this._todoRepository, this._rangeCalculator, this._clock);

  final TodoRepository _todoRepository;
  final PeriodRangeCalculator _rangeCalculator;
  final Clock _clock;

  Future<DomainResult<List<Todo>>> call(Period period) =>
      _todoRepository.getTodos(_rangeCalculator.rangeFor(period, _clock()));
}

class GetTodoUseCase {
  const GetTodoUseCase(this._todoRepository);

  final TodoRepository _todoRepository;

  Future<DomainResult<Todo>> call(String id) => _todoRepository.getTodo(id);
}

/// Creates a todo when `id` is null, otherwise updates the existing one.
class SaveTodoUseCase {
  const SaveTodoUseCase(this._todoRepository);

  final TodoRepository _todoRepository;

  Future<DomainResult<Todo>> call(String? id, TodoDraft draft) async {
    final errors = TodoValidator.validate(draft);
    if (errors.isNotEmpty) return Failure(ValidationFailure(errors: errors));
    final normalized = draft.copyWith(title: draft.title.trim());
    return id == null ? _todoRepository.create(normalized) : _todoRepository.update(id, normalized);
  }
}

class DeleteTodoUseCase {
  const DeleteTodoUseCase(this._todoRepository);

  final TodoRepository _todoRepository;

  Future<DomainResult<void>> call(String id) => _todoRepository.delete(id);
}

/// Default due date for a new todo: the next full hour in the user's time zone, as a UTC instant.
class DefaultDueDateUseCase {
  const DefaultDueDateUseCase(this._clock, [this._timeZone = const DeviceTimeZone()]);

  final Clock _clock;
  final TimeZone _timeZone;

  DateTime call() {
    final now = _timeZone.wallClock(_clock());
    return _timeZone.instantOf(now.year, now.month, now.day, now.hour).add(const Duration(hours: 1));
  }
}
