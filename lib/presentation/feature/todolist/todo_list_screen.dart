import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/model/models.dart';
import '../../ui/components/status_badge.dart';
import '../../ui/strings.dart';
import 'todo_list_contract.dart';
import 'todo_list_view_model.dart';

class TodoListRoute extends StatefulWidget {
  const TodoListRoute({super.key, required this.createViewModel, required this.onOpenTodo});

  final TodoListViewModel Function() createViewModel;

  /// Completes when the detail screen is closed; the list then reloads.
  final Future<void> Function(String? id) onOpenTodo;

  @override
  State<TodoListRoute> createState() => _TodoListRouteState();
}

class _TodoListRouteState extends State<TodoListRoute> {
  late final TodoListViewModel _viewModel;
  late final StreamSubscription<TodoListEffect> _effects;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.createViewModel();
    _effects = _viewModel.effects.listen(_onEffect);
    _viewModel.onIntent(const TodoListScreenShown());
  }

  Future<void> _onEffect(TodoListEffect effect) async {
    switch (effect) {
      case TodoListOpenTodo(:final id):
        await widget.onOpenTodo(id);
        if (mounted) _viewModel.onIntent(const TodoListScreenShown());
      case TodoListShowError(:final error):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.of(context).error(error))));
    }
  }

  /// Completes once the pull-to-refresh load finishes, which hides the refresh indicator.
  Future<void> _refresh() {
    final done = Completer<void>();
    void listener() {
      if (_viewModel.state.isRefreshing) return;
      _viewModel.removeListener(listener);
      done.complete();
    }

    _viewModel.onIntent(const TodoListRefresh());
    _viewModel.addListener(listener);
    listener();
    return done.future;
  }

  @override
  void dispose() {
    _effects.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) =>
        TodoListScreen(state: _viewModel.state, onIntent: _viewModel.onIntent, onRefresh: _refresh),
  );
}

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key, required this.state, required this.onIntent, required this.onRefresh});

  final TodoListState state;
  final ValueChanged<TodoListIntent> onIntent;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final error = state.error;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.todosTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: strings.logout,
            onPressed: () => onIntent(const TodoListLogoutClicked()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: strings.addTodo,
        onPressed: () => onIntent(const TodoListAddClicked()),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _PeriodTabs(period: state.period, onSelected: (period) => onIntent(TodoListPeriodSelected(period))),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: onRefresh,
                    child: switch (state) {
                      _ when error != null => _Placeholder(
                        title: strings.error(error),
                        action: (strings.retry, () => onIntent(const TodoListRetry())),
                      ),
                      TodoListState(hasLoaded: true, todos: []) => _Placeholder(
                        title: strings.emptyPeriod(state.period),
                        subtitle: strings.emptyHint,
                      ),
                      _ => _TodoList(todos: state.todos, onTap: (id) => onIntent(TodoListTodoClicked(id))),
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatefulWidget {
  const _PeriodTabs({required this.period, required this.onSelected});

  final Period period;
  final ValueChanged<Period> onSelected;

  @override
  State<_PeriodTabs> createState() => _PeriodTabsState();
}

class _PeriodTabsState extends State<_PeriodTabs> with SingleTickerProviderStateMixin {
  late final _controller = TabController(length: Period.values.length, initialIndex: widget.period.index, vsync: this);

  @override
  void didUpdateWidget(_PeriodTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.index != widget.period.index) _controller.animateTo(widget.period.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return TabBar(
      controller: _controller,
      onTap: (index) => widget.onSelected(Period.values[index]),
      tabs: [for (final period in Period.values) Tab(text: strings.period(period))],
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({required this.todos, required this.onTap});

  final List<Todo> todos;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    // Keeps the last row clear of the FAB.
    padding: const EdgeInsets.only(bottom: 88),
    itemCount: todos.length,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (context, index) {
      final todo = todos[index];
      return _TodoRow(key: ValueKey(todo.id), todo: todo, onTap: () => onTap(todo.id));
    },
  );
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({super.key, required this.todo, required this.onTap});

  final Todo todo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final dueAt = todo.dueAt.toLocal();
    return ListTile(
      onTap: onTap,
      leading: Text(
        strings.formatTime(dueAt.hour, dueAt.minute),
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
      ),
      title: Text(todo.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(strings.formatDate(dueAt)),
      trailing: StatusBadge(status: todo.status),
    );
  }
}

/// Scrollable so that pull-to-refresh also works on empty and error states.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    final action = this.action;
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  Icon(Icons.checklist, size: 48, color: theme.colorScheme.outline),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  if (action != null) FilledButton(onPressed: action.$2, child: Text(action.$1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
