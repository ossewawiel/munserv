# Screen Widget Generator

name: "screen"
description: "Generate screen with GoRouter integration"
parameters:
  - name: "name"
    description: "Screen name in PascalCase (e.g., 'IssueList', 'IssueDetail', 'CreateIssue')"
    required: true
  - name: "feature"
    description: "Feature folder (e.g., 'issues', 'members', 'auth')"
    required: true
  - name: "type"
    description: "Screen type: list, detail, form, empty"
    required: false
    default: "empty"

---

You are an expert Flutter developer generating screens for the MunServ mobile app.

## Task

Generate a `{{type}}` screen named `{{name}}Page` in the `{{feature}}` feature.

## File Location

```
lib/features/{{feature}}/presentation/{{snake_case(name)}}_page.dart
```

## Screen Types

### List Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munserv/shared/widgets/loading_spinner.dart';
import 'package:munserv/shared/widgets/error_display.dart';
import '../providers/{{feature}}_providers.dart';
import '../domain/{{entity}}.dart';
import 'widgets/{{entity}}_card.dart';

/// Screen displaying list of {{entity}}s
class {{name}}Page extends ConsumerWidget {
  const {{name}}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final {{entity}}sAsync = ref.watch({{entity}}sProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('{{displayName}}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate({{entity}}sProvider),
          ),
        ],
      ),
      body: {{entity}}sAsync.when(
        data: ({{entity}}s) => _buildList(context, ref, {{entity}}s),
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate({{entity}}sProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<{{Entity}}> items) {
    if (items.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate({{entity}}sProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return {{Entity}}Card(
            {{entity}}: item,
            onTap: () => _navigateToDetail(context, item.id),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String id) {
    context.push('/{{feature}}/$id');
  }

  void _navigateToCreate(BuildContext context) {
    context.push('/{{feature}}/create');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first item to get started',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Detail Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munserv/shared/widgets/loading_spinner.dart';
import 'package:munserv/shared/widgets/error_display.dart';
import '../providers/{{feature}}_providers.dart';
import '../domain/{{entity}}.dart';

/// Screen displaying {{entity}} details
class {{name}}Page extends ConsumerWidget {
  final String id;

  const {{name}}Page({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final {{entity}}Async = ref.watch({{entity}}DetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('{{displayName}}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: {{entity}}Async.when(
        data: ({{entity}}) => {{entity}} != null
            ? _buildContent(context, ref, {{entity}})
            : const ErrorDisplay(error: 'Item not found'),
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate({{entity}}DetailProvider(id)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, {{Entity}} item) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description ?? 'No description',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Additional sections
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    context.push('/{{feature}}/$id/edit');
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'delete') {
      final confirmed = await _showDeleteConfirmation(context);
      if (confirmed == true) {
        // Delete logic
        if (context.mounted) {
          context.pop();
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
```

### Form Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/{{feature}}_providers.dart';

/// Screen for creating/editing {{entity}}
class {{name}}Page extends ConsumerStatefulWidget {
  final String? id; // null for create, non-null for edit

  const {{name}}Page({
    super.key,
    this.id,
  });

  @override
  ConsumerState<{{name}}Page> createState() => _{{name}}PageState();
}

class _{{name}}PageState extends ConsumerState<{{name}}Page> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  bool get isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    if (isEditing) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    final item = await ref.read({{entity}}DetailProvider(widget.id!).future);
    if (item != null && mounted) {
      _titleController.text = item.title;
      _descriptionController.text = item.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit' : 'Create'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter title',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description (optional)',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            // Additional form fields
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read({{entity}}NotifierProvider.notifier);

      if (isEditing) {
        await notifier.update(
          widget.id!,
          title: _titleController.text,
          description: _descriptionController.text,
        );
      } else {
        await notifier.create(
          title: _titleController.text,
          description: _descriptionController.text,
        );
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Updated successfully' : 'Created successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

## GoRouter Configuration

Add routes to `lib/routing/app_router.dart`:

```dart
// Route constants
static const {{feature}}List = '/{{feature}}';
static const {{feature}}Detail = '/{{feature}}/:id';
static const {{feature}}Create = '/{{feature}}/create';
static const {{feature}}Edit = '/{{feature}}/:id/edit';

// Route configuration
GoRoute(
  path: '/{{feature}}',
  builder: (context, state) => const {{Name}}ListPage(),
  routes: [
    GoRoute(
      path: 'create',
      builder: (context, state) => const {{Name}}FormPage(),
    ),
    GoRoute(
      path: ':id',
      builder: (context, state) => {{Name}}DetailPage(
        id: state.pathParameters['id']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => {{Name}}FormPage(
            id: state.pathParameters['id'],
          ),
        ),
      ],
    ),
  ],
),
```

## Best Practices

### Do
- [ ] Use `ConsumerWidget` for read-only screens
- [ ] Use `ConsumerStatefulWidget` for forms with controllers
- [ ] Handle loading, error, and empty states
- [ ] Use `RefreshIndicator` for pull-to-refresh
- [ ] Invalidate provider on retry
- [ ] Show confirmation dialogs for destructive actions

### Don't
- [ ] Don't use setState for async data (use Riverpod)
- [ ] Don't hardcode strings (use l10n)
- [ ] Don't forget to dispose controllers
- [ ] Don't navigate without checking `mounted`

## Output

1. Create screen file at correct location
2. Include proper imports
3. Add route configuration to app_router.dart
4. Handle all async states (loading, error, data, empty)
5. Verify with `flutter analyze`
