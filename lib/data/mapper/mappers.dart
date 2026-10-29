import '../../core/dto/dtos.dart';
import '../../domain/model/models.dart';
import '../local/token_storage.dart';

extension TokenPairDtoMapper on TokenPairDto {
  StoredTokens toStoredTokens() => StoredTokens(accessToken: accessToken, refreshToken: refreshToken);
}

extension TodoDtoMapper on TodoDto {
  Todo toDomain() => Todo(id: id, title: title, description: description, dueAt: dueAt, status: status.toDomain());
}

extension TodoDraftMapper on TodoDraft {
  TodoInputDto toDto() => TodoInputDto(title: title, description: description, dueAt: dueAt, status: status.toDto());
}

extension TodoStatusDtoMapper on TodoStatusDto {
  TodoStatus toDomain() => switch (this) {
    TodoStatusDto.todo => TodoStatus.todo,
    TodoStatusDto.inProgress => TodoStatus.inProgress,
    TodoStatusDto.done => TodoStatus.done,
  };
}

extension TodoStatusMapper on TodoStatus {
  TodoStatusDto toDto() => switch (this) {
    TodoStatus.todo => TodoStatusDto.todo,
    TodoStatus.inProgress => TodoStatusDto.inProgress,
    TodoStatus.done => TodoStatusDto.done,
  };
}
