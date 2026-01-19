# Shared Widget Generator

name: "shared-widget"
description: "Generate reusable widget in shared/widgets/ following design system standards"
parameters:
  - name: "name"
    description: "Widget name in PascalCase (e.g., 'QuickActionCard', 'StepIndicator')"
    required: true
  - name: "type"
    description: "Widget type: stateless, consumer, or stateful"
    required: false
    default: "stateless"
  - name: "variants"
    description: "Comma-separated variant names if widget supports multiple modes (e.g., 'list,compact,preview')"
    required: false

---

You are an expert Flutter developer creating shared, reusable widgets for the MunServ mobile app design system.

## Task

Generate a shared widget named `{{name}}` in `lib/shared/widgets/`.

## File Location

```
lib/shared/widgets/{{snake_case(name)}}.dart
```

## Shared Widget Checklist

Before creating, verify:
- [ ] This widget will be used by 2+ features OR is a core UI pattern
- [ ] No existing widget in `shared/widgets/` does the same thing
- [ ] Cannot be achieved by adding a variant to existing widget

## Widget Template

### StatelessWidget (with optional variants)

```dart
import 'package:flutter/material.dart';
import 'package:munserv/shared/theme/typography.dart';

{{#if variants}}
/// Variants for [{{name}}] display modes.
enum {{name}}Variant {
  {{#each variants}}
  /// {{description}}
  {{name}},
  {{/each}}
}
{{/if}}

/// {{description}}
///
/// A reusable widget from the MunServ design system.
///
/// ## Usage
/// ```dart
/// {{name}}(
///   {{primaryParam}}: value,
{{#if variants}}
///   variant: {{name}}Variant.{{defaultVariant}},
{{/if}}
///   onTap: () => handleTap(),
/// )
/// ```
class {{name}} extends StatelessWidget {
  {{#each params}}
  /// {{description}}
  final {{type}} {{name}};
  {{/each}}

{{#if variants}}
  /// Display variant. Defaults to [{{name}}Variant.{{defaultVariant}}].
  final {{name}}Variant variant;
{{/if}}

  /// Optional tap callback.
  final VoidCallback? onTap;

{{#if hasCloseAction}}
  /// Optional close callback (for dismissible variants).
  final VoidCallback? onClose;
{{/if}}

  const {{name}}({
    super.key,
    {{#each params}}
    {{#if required}}required {{/if}}this.{{name}},
    {{/each}}
{{#if variants}}
    this.variant = {{name}}Variant.{{defaultVariant}},
{{/if}}
    this.onTap,
{{#if hasCloseAction}}
    this.onClose,
{{/if}}
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

{{#if variants}}
    return switch (variant) {
      {{#each variants}}
      {{name}}Variant.{{name}} => _build{{PascalCase(name)}}(context, colors, textTheme),
      {{/each}}
    };
{{else}}
    return _buildContent(context, colors, textTheme);
{{/if}}
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              // Leading element
              Container(
                width: IconSizes.xxl,
                height: IconSizes.xxl,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(
                  Icons.placeholder,
                  size: IconSizes.lg,
                  color: colors.onPrimaryContainer,
                ),
              ),
              SizedBox(width: Spacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style: textTheme.titleMedium,
                    ),
                    SizedBox(height: Spacing.xs),
                    Text(
                      'Subtitle',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing element
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Widget with Factory Constructors (like EmptyState)

```dart
import 'package:flutter/material.dart';
import 'package:munserv/shared/theme/typography.dart';

/// {{description}}
///
/// Use factory constructors for common use cases:
/// - [{{name}}.variant1] - Description
/// - [{{name}}.variant2] - Description
class {{name}} extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const {{name}}({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  /// Factory for variant 1 use case.
  factory {{name}}.variant1({
    VoidCallback? onAction,
  }) {
    return {{name}}(
      icon: Icons.inbox_outlined,
      title: 'Variant 1 Title',
      subtitle: 'Variant 1 description',
      action: onAction != null
          ? FilledButton(
              onPressed: onAction,
              child: const Text('Action'),
            )
          : null,
    );
  }

  /// Factory for variant 2 use case.
  factory {{name}}.variant2({
    VoidCallback? onRetry,
  }) {
    return {{name}}(
      icon: Icons.error_outline,
      title: 'Variant 2 Title',
      subtitle: 'Variant 2 description',
      action: onRetry != null
          ? OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: IconSizes.display,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: Spacing.lg),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: Spacing.sm),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: Spacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

## Sizing Constants (MUST USE)

```dart
import 'package:munserv/shared/theme/typography.dart';

// Icons
IconSizes.sm    // 16dp - Small inline icons
IconSizes.md    // 24dp - Default icon size
IconSizes.lg    // 32dp - Prominent icons
IconSizes.xl    // 48dp - Feature icons
IconSizes.xxl   // 64dp - Card leading icons
IconSizes.display // 80dp - Empty state icons

// Thumbnails
ThumbnailSizes.sm  // 48dp - Small avatars
ThumbnailSizes.md  // 64dp - Card thumbnails
ThumbnailSizes.lg  // 100dp - Photo tiles
ThumbnailSizes.xl  // 120dp - Large previews

// Spacing
Spacing.xs  // 4dp
Spacing.sm  // 8dp
Spacing.md  // 16dp
Spacing.lg  // 24dp
Spacing.xl  // 32dp
Spacing.xxl // 48dp

// Radii
Radii.xs  // 4dp - Inputs
Radii.sm  // 8dp - Chips, small cards
Radii.md  // 12dp - Cards
Radii.lg  // 16dp - FAB
Radii.xl  // 28dp - Dialogs
```

## Full-Width Card Pattern

All card-based shared widgets MUST expand to full width:

```dart
// ✅ DO: Cards expand to fill available width
Card(
  margin: EdgeInsets.symmetric(
    horizontal: Spacing.md,  // Horizontal margin only
    vertical: Spacing.xs,
  ),
  child: InkWell(
    // Content fills card
  ),
)

// ❌ DON'T: Constrain width
SizedBox(width: 300, child: Card(...))
Center(child: Card(...))
```

## Export Widget

After creating, add export to `lib/shared/widgets/widgets.dart`:

```dart
export 'loading_spinner.dart';
export 'error_display.dart';
export 'empty_state.dart';
export '{{snake_case(name)}}.dart';  // Add this line
```

## M3 Theming Rules

- [ ] Use `Theme.of(context).colorScheme` for all colors
- [ ] Use `Theme.of(context).textTheme` for all text styles
- [ ] NEVER hardcode `Color(0xFF...)` values
- [ ] NEVER use `.withOpacity()` - use semantic color variants
- [ ] Use `Spacing`, `IconSizes`, `ThumbnailSizes` constants

## Widget Tests

Create test file at `test/shared/widgets/{{snake_case(name)}}_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv/shared/widgets/{{snake_case(name)}}.dart';

void main() {
  group('{{name}}', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: {{name}}(
              // Required params
            ),
          ),
        ),
      );

      expect(find.byType({{name}}), findsOneWidget);
    });

{{#if variants}}
    testWidgets('renders each variant', (tester) async {
      for (final variant in {{name}}Variant.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: {{name}}(
                variant: variant,
                // Required params
              ),
            ),
          ),
        );

        expect(find.byType({{name}}), findsOneWidget);
      }
    });
{{/if}}

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: {{name}}(
              onTap: () => tapped = true,
              // Required params
            ),
          ),
        ),
      );

      await tester.tap(find.byType({{name}}));
      expect(tapped, isTrue);
    });
  });
}
```

## Output

1. Create widget file at `lib/shared/widgets/{{snake_case(name)}}.dart`
2. Include proper imports (especially `typography.dart`)
3. Use sizing constants (NO magic numbers)
4. Support variants via enum or factory constructors
5. Ensure full-width card pattern if card-based
6. Add export to `shared/widgets/widgets.dart`
7. Create widget test file
8. Add KDoc with usage example
