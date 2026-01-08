import 'package:flutter/material.dart';

import '../../../../shared/theme/colors.dart';

/// Theme showcase page for visual verification of M3 theme
/// Only accessible in debug/development builds
class ThemeShowcasePage extends StatelessWidget {
  const ThemeShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Showcase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Color Palette Section
          _SectionTitle('Color Palette'),
          _ColorPaletteSection(colors: colors),
          const SizedBox(height: 24),

          // Typography Section
          _SectionTitle('Typography'),
          _TypographySection(textTheme: textTheme),
          const SizedBox(height: 24),

          // Buttons Section
          _SectionTitle('Buttons'),
          _ButtonsSection(),
          const SizedBox(height: 24),

          // Cards Section
          _SectionTitle('Cards'),
          _CardsSection(),
          const SizedBox(height: 24),

          // Form Inputs Section
          _SectionTitle('Form Inputs'),
          _FormInputsSection(),
          const SizedBox(height: 24),

          // Chips Section
          _SectionTitle('Chips'),
          _ChipsSection(),
          const SizedBox(height: 24),

          // Selection Controls Section
          _SectionTitle('Selection Controls'),
          _SelectionControlsSection(),
          const SizedBox(height: 24),

          // Issue State Colors Section
          _SectionTitle('Issue State Colors'),
          _IssueStateColorsSection(),
          const SizedBox(height: 24),

          // Heat Colors Section
          _SectionTitle('Heat Priority Colors'),
          _HeatColorsSection(),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ColorPaletteSection extends StatelessWidget {
  final ColorScheme colors;
  const _ColorPaletteSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Primary', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            _ColorSwatch('primary', colors.primary, colors.onPrimary),
            _ColorSwatch('primaryContainer', colors.primaryContainer, colors.onPrimaryContainer),
          ],
        ),
        const SizedBox(height: 16),
        Text('Secondary', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            _ColorSwatch('secondary', colors.secondary, colors.onSecondary),
            _ColorSwatch('secondaryContainer', colors.secondaryContainer, colors.onSecondaryContainer),
          ],
        ),
        const SizedBox(height: 16),
        Text('Tertiary', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            _ColorSwatch('tertiary', colors.tertiary, colors.onTertiary),
            _ColorSwatch('tertiaryContainer', colors.tertiaryContainer, colors.onTertiaryContainer),
          ],
        ),
        const SizedBox(height: 16),
        Text('Surface', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            _ColorSwatch('surface', colors.surface, colors.onSurface),
            _ColorSwatch('surfaceContainerLow', colors.surfaceContainerLow, colors.onSurface),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _ColorSwatch('surfaceContainer', colors.surfaceContainer, colors.onSurface),
            _ColorSwatch('surfaceContainerHigh', colors.surfaceContainerHigh, colors.onSurface),
          ],
        ),
        const SizedBox(height: 16),
        Text('Error', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            _ColorSwatch('error', colors.error, colors.onError),
            _ColorSwatch('errorContainer', colors.errorContainer, colors.onErrorContainer),
          ],
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;
  final Color onColor;

  const _ColorSwatch(this.label, this.color, this.onColor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          label,
          style: TextStyle(color: onColor, fontSize: 10),
        ),
      ),
    );
  }
}

class _TypographySection extends StatelessWidget {
  final TextTheme textTheme;
  const _TypographySection({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large', style: textTheme.displayLarge),
        Text('Display Medium', style: textTheme.displayMedium),
        Text('Display Small', style: textTheme.displaySmall),
        const Divider(height: 24),
        Text('Headline Large', style: textTheme.headlineLarge),
        Text('Headline Medium', style: textTheme.headlineMedium),
        Text('Headline Small', style: textTheme.headlineSmall),
        const Divider(height: 24),
        Text('Title Large', style: textTheme.titleLarge),
        Text('Title Medium', style: textTheme.titleMedium),
        Text('Title Small', style: textTheme.titleSmall),
        const Divider(height: 24),
        Text('Body Large', style: textTheme.bodyLarge),
        Text('Body Medium', style: textTheme.bodyMedium),
        Text('Body Small', style: textTheme.bodySmall),
        const Divider(height: 24),
        Text('Label Large', style: textTheme.labelLarge),
        Text('Label Medium', style: textTheme.labelMedium),
        Text('Label Small', style: textTheme.labelSmall),
      ],
    );
  }
}

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Filled Button (40dp height)', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {},
          child: const Text('Filled Button'),
        ),
        const SizedBox(height: 16),
        Text('Elevated Button', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Elevated Button'),
        ),
        const SizedBox(height: 16),
        Text('Outlined Button', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Outlined Button'),
        ),
        const SizedBox(height: 16),
        Text('Text Button', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {},
          child: const Text('Text Button'),
        ),
        const SizedBox(height: 16),
        Text('Disabled States', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: null,
                child: const Text('Disabled'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: null,
                child: const Text('Disabled'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Icon Buttons', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite_outline),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.share_outlined),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardsSection extends StatelessWidget {
  const _CardsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Card (12dp radius, 1dp elevation)', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Card Title', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'This is a card with M3 styling: 12dp corner radius, surfaceContainerLow background.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Card with Actions', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interactive Card', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Card with action buttons following M3 spacing.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () {}, child: const Text('Confirm')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FormInputsSection extends StatelessWidget {
  const _FormInputsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Text Field (4dp radius, filled)', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Label',
            hintText: 'Enter text...',
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'With Helper',
            hintText: 'Enter text...',
            helperText: 'Helper text goes here',
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Error State',
            errorText: 'This field has an error',
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Disabled',
            hintText: 'Cannot edit',
          ),
        ),
      ],
    );
  }
}

class _ChipsSection extends StatelessWidget {
  const _ChipsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chips (8dp radius)', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const Chip(label: Text('Chip')),
            Chip(
              label: const Text('With Avatar'),
              avatar: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Text('A', style: TextStyle(fontSize: 12)),
              ),
            ),
            Chip(
              label: const Text('Deletable'),
              onDeleted: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Filter Chips', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Selected'),
              selected: true,
              onSelected: (_) {},
            ),
            FilterChip(
              label: const Text('Not Selected'),
              selected: false,
              onSelected: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectionControlsSection extends StatefulWidget {
  const _SelectionControlsSection();

  @override
  State<_SelectionControlsSection> createState() => _SelectionControlsSectionState();
}

class _SelectionControlsSectionState extends State<_SelectionControlsSection> {
  bool _checkboxValue = true;
  bool _switchValue = true;
  int _radioValue = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Checkbox', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _checkboxValue,
              onChanged: (v) => setState(() => _checkboxValue = v!),
            ),
            const Text('Checked'),
            const SizedBox(width: 16),
            Checkbox(
              value: false,
              onChanged: (v) {},
            ),
            const Text('Unchecked'),
          ],
        ),
        const SizedBox(height: 16),
        Text('Switch', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Switch(
              value: _switchValue,
              onChanged: (v) => setState(() => _switchValue = v),
            ),
            Text(_switchValue ? 'On' : 'Off'),
          ],
        ),
        const SizedBox(height: 16),
        Text('Radio', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        RadioGroup<int>(
          groupValue: _radioValue,
          onChanged: (v) => setState(() => _radioValue = v!),
          child: Row(
            children: [
              Radio<int>(value: 0),
              const Text('Option 1'),
              const SizedBox(width: 16),
              Radio<int>(value: 1),
              const Text('Option 2'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Slider', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Slider(
          value: 0.5,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

class _IssueStateColorsSection extends StatelessWidget {
  const _IssueStateColorsSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StateChip('Reported', IssueStateColors.reported),
        _StateChip('Confirmed', IssueStateColors.confirmed),
        _StateChip('In Progress', IssueStateColors.inProgress),
        _StateChip('Fixed', IssueStateColors.fixed),
        _StateChip('Rejected', IssueStateColors.rejected),
        _StateChip('Reopened', IssueStateColors.reopened),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StateChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}

class _HeatColorsSection extends StatelessWidget {
  const _HeatColorsSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _HeatChip('Low (< 40)', HeatColors.low),
        _HeatChip('Medium (40-59)', HeatColors.medium),
        _HeatChip('High (60-79)', HeatColors.high),
        _HeatChip('Critical (80+)', HeatColors.critical),
      ],
    );
  }
}

class _HeatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _HeatChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}
