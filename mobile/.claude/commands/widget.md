# Flutter Widget Generator

name: "widget"
description: "Generate Flutter widget following project patterns"
parameters:
  - name: "name"
    description: "Widget name in PascalCase (e.g., 'IssueCard', 'HeatBadge')"
    required: true
  - name: "feature"
    description: "Feature folder (e.g., 'issues', 'members', 'auth')"
    required: true
  - name: "type"
    description: "Widget type: stateless, consumer, or hook"
    required: false
    default: "stateless"

---

You are an expert Flutter developer generating widgets for the MunServ mobile app.

## Task

Generate a `{{type}}` widget named `{{name}}` in the `{{feature}}` feature.

## Widget Types

### StatelessWidget (default)
Use when widget:
- Only displays data passed via constructor
- Has no state
- Doesn't need providers

```dart
import 'package:flutter/material.dart';

class {{name}} extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onTap;

  const {{name}}({
    super.key,
    required this.issue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      // Widget implementation
    );
  }
}
```

### ConsumerWidget
Use when widget:
- Needs to read Riverpod providers
- Needs reactive updates from state changes

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class {{name}} extends ConsumerWidget {
  final String issueId;

  const {{name}}({
    super.key,
    required this.issueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final issueAsync = ref.watch(issueProvider(issueId));

    return issueAsync.when(
      data: (issue) => _buildContent(context, issue),
      loading: () => const LoadingSpinner(),
      error: (error, _) => ErrorDisplay(
        error: error,
        onRetry: () => ref.invalidate(issueProvider(issueId)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Issue issue) {
    // Widget implementation
  }
}
```

### HookConsumerWidget
Use when widget:
- Needs Riverpod providers AND Flutter Hooks
- Has animations, controllers, focus nodes

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class {{name}} extends HookConsumerWidget {
  const {{name}}({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(duration: const Duration(milliseconds: 300));
    final focusNode = useFocusNode();

    return Container(
      // Widget implementation
    );
  }
}
```

## File Location

```
lib/features/{{feature}}/presentation/widgets/{{snake_case(name)}}.dart
```

## Best Practices Checklist

### Constructor
- [ ] `const` constructor if all fields are final
- [ ] `super.key` as first parameter
- [ ] Required fields use `required` keyword
- [ ] Optional callbacks use `VoidCallback?` type

### Theme Usage
- [ ] Use `Theme.of(context).colorScheme` for colors
- [ ] Use `Theme.of(context).textTheme` for text styles
- [ ] NEVER hardcode colors with `Color(0xFF...)`
- [ ] NEVER use `.withOpacity()` on theme colors

### Widget Composition
- [ ] Extract sub-widgets if >50 lines
- [ ] Use `_` prefix for private sub-widgets
- [ ] Private sub-widgets in same file if single-use
- [ ] Separate file if reusable

### Performance
- [ ] Use `const` wherever possible
- [ ] Avoid creating objects in build()
- [ ] Use `ListView.builder` for long lists
- [ ] Extract rebuild-heavy widgets

## M3 Component Patterns

### Card
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content
      ],
    ),
  ),
)
```

### ListTile
```dart
ListTile(
  leading: Icon(Icons.place, color: colors.primary),
  title: Text(issue.type.displayName),
  subtitle: Text(issue.state.displayName),
  trailing: HeatBadge(heat: issue.heat),
  onTap: onTap,
)
```

### Button
```dart
FilledButton(
  onPressed: onSubmit,
  child: const Text('Submit'),
)

FilledButton.tonal(
  onPressed: onCancel,
  child: const Text('Cancel'),
)
```

### Chip
```dart
Chip(
  label: Text(state.displayName),
  backgroundColor: IssueStateColors.forState(state),
)
```

## Import Order

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Third-party
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Project imports
import 'package:munserv/shared/widgets/loading_spinner.dart';
import '../domain/issue.dart';
import '../providers/issue_providers.dart';
```

## Output

1. Determine appropriate widget type based on requirements
2. Create widget file at correct location
3. Include proper imports
4. Follow M3 theming patterns
5. Add KDoc comment explaining widget purpose
