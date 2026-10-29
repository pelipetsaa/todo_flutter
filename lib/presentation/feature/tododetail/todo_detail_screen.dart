import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/model/models.dart';
import '../../ui/components/progress_button.dart';
import '../../ui/components/synced_text_field.dart';
import '../../ui/strings.dart';
import 'todo_detail_contract.dart';
import 'todo_detail_view_model.dart';

class TodoDetailRoute extends StatefulWidget {
  const TodoDetailRoute({super.key, required this.createViewModel, required this.onClose});

  final TodoDetailViewModel Function() createViewModel;
  final VoidCallback onClose;

  @override
  State<TodoDetailRoute> createState() => _TodoDetailRouteState();
}

class _TodoDetailRouteState extends State<TodoDetailRoute> {
  late final TodoDetailViewModel _viewModel;
  late final StreamSubscription<TodoDetailEffect> _effects;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.createViewModel();
    _effects = _viewModel.effects.listen(_onEffect);
  }

  Future<void> _onEffect(TodoDetailEffect effect) async {
    final strings = AppStrings.of(context);
    switch (effect) {
      case TodoDetailClose():
        widget.onClose();
      case TodoDetailShowError(:final error):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.error(error))));
      case TodoDetailPickDate(:final initial):
        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1970),
          lastDate: DateTime(2100),
        );
        if (date != null) _viewModel.onIntent(TodoDetailDateSelected(date));
      case TodoDetailPickTime(:final initial):
        final time = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
        );
        if (time != null) _viewModel.onIntent(TodoDetailTimeSelected(time));
      case TodoDetailConfirmDelete():
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.deleteConfirmTitle),
            content: Text(strings.deleteConfirmMessage),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(strings.cancel)),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) _viewModel.onIntent(const TodoDetailDeleteConfirmed());
    }
  }

  @override
  void dispose() {
    _effects.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // The system back gesture goes through the view model too, so it is ignored while saving.
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _viewModel.onIntent(const TodoDetailBackClicked());
    },
    child: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => TodoDetailScreen(state: _viewModel.state, onIntent: _viewModel.onIntent),
    ),
  );
}

class TodoDetailScreen extends StatelessWidget {
  const TodoDetailScreen({super.key, required this.state, required this.onIntent});

  final TodoDetailState state;
  final ValueChanged<TodoDetailIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final loadError = state.loadError;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => onIntent(const TodoDetailBackClicked())),
        title: Text(state.isNew ? strings.newTodoTitle : strings.editTodoTitle),
        actions: [
          if (!state.isNew)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: strings.delete,
              onPressed: state.canEdit ? () => onIntent(const TodoDetailDeleteClicked()) : null,
            ),
        ],
      ),
      body: switch (state) {
        TodoDetailState(isLoading: true) => const Center(child: CircularProgressIndicator()),
        _ when loadError != null => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  strings.error(loadError),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                FilledButton(onPressed: () => onIntent(const TodoDetailRetry()), child: Text(strings.retry)),
              ],
            ),
          ),
        ),
        _ => _TodoForm(state: state, onIntent: onIntent),
      },
    );
  }
}

class _TodoForm extends StatelessWidget {
  const _TodoForm({required this.state, required this.onIntent});

  final TodoDetailState state;
  final ValueChanged<TodoDetailIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final enabled = state.canEdit;
    final titleError = state.titleError;
    final descriptionError = state.descriptionError;
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                SyncedTextField(
                  value: state.title,
                  onChanged: (value) => onIntent(TodoDetailTitleChanged(value)),
                  label: strings.fieldTitle,
                  errorText: titleError == null ? null : strings.validation(titleError),
                  enabled: enabled,
                  textInputAction: TextInputAction.next,
                ),
                SyncedTextField(
                  value: state.description,
                  onChanged: (value) => onIntent(TodoDetailDescriptionChanged(value)),
                  label: strings.fieldDescription,
                  errorText: descriptionError == null ? null : strings.validation(descriptionError),
                  enabled: enabled,
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _PickerField(
                        label: strings.fieldDate,
                        value: strings.formatDate(state.date),
                        enabled: enabled,
                        onTap: () => onIntent(const TodoDetailDateClicked()),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _PickerField(
                        label: strings.fieldTime,
                        value: strings.formatTime(state.time.hour, state.time.minute),
                        enabled: enabled,
                        onTap: () => onIntent(const TodoDetailTimeClicked()),
                      ),
                    ),
                  ],
                ),
                Text(strings.fieldStatus, style: Theme.of(context).textTheme.labelLarge),
                SegmentedButton<TodoStatus>(
                  showSelectedIcon: false,
                  segments: [
                    for (final status in TodoStatus.values)
                      ButtonSegment(
                        value: status,
                        label: Text(strings.status(status), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  selected: {state.status},
                  onSelectionChanged: enabled
                      ? (selected) => onIntent(TodoDetailStatusSelected(selected.single))
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ProgressButton(
                    text: strings.save,
                    inProgress: state.isSaving,
                    enabled: enabled,
                    onPressed: () => onIntent(const TodoDetailSaveClicked()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A read-only field that opens a picker.
class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, required this.enabled, required this.onTap});

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(4),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, enabled: enabled, border: const OutlineInputBorder()),
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}
