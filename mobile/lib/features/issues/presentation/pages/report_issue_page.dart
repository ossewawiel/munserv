import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../shared/models/issue_type.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../domain/domain.dart';
import '../../providers/issue_providers.dart';
import '../widgets/widgets.dart';

/// Multi-step page for reporting a new issue
class ReportIssuePage extends ConsumerStatefulWidget {
  const ReportIssuePage({super.key});

  @override
  ConsumerState<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends ConsumerState<ReportIssuePage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Form data
  List<String> _photoPaths = [];
  IssueType? _selectedType;
  GeoPoint? _location;
  String? _description;

  // State
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  bool get _canProceed => switch (_currentStep) {
        0 => _photoPaths.isNotEmpty,
        1 => _selectedType != null,
        2 => _location != null,
        3 => true,
        _ => false,
      };

  Future<void> _submit() async {
    if (_selectedType == null || _location == null) return;

    // Get sectorId from auth state
    final authState = ref.read(authProvider);
    final sectorId = authState.sectorIdOrNull;

    if (sectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).noSectorAssigned),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Capture context-dependent values before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final router = GoRouter.of(context);

    setState(() => _isSubmitting = true);

    final request = ReportIssueRequest(
      type: _selectedType!,
      location: _location!,
      sectorId: sectorId,
      description: _description,
    );

    try {
      debugPrint('📤 Starting issue submission...');
      final result = await ref.read(reportIssueProvider.notifier).reportIssue(
            request: request,
            photoPaths: _photoPaths,
          );
      debugPrint('📤 Issue submission completed. isSuccess: ${result.isSuccess}');

      // Update UI state if still mounted
      if (mounted) {
        setState(() => _isSubmitting = false);
      }

      // Show feedback regardless of mounted state (using captured messenger)
      if (result.isSuccess) {
        debugPrint('📤 Showing success snackbar and navigating home');
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        // Navigate using captured router
        router.go('/');
      } else {
        final errorMsg = result.errorOrNull?.displayMessage ?? 'Failed to report issue';
        debugPrint('📤 Showing error snackbar: $errorMsg');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      // Handle unexpected errors
      debugPrint('📤 Exception caught: $e');
      debugPrint('📤 Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return BrandedScaffold(
      appBar: AppBar(
        title: Text(l10n.reportIssueTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _StepIndicator(currentStep: _currentStep),
          // Steps content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PhotoStep(
                  photoPaths: _photoPaths,
                  onPhotosChanged: (paths) => setState(() {
                    _photoPaths = List.from(paths);
                  }),
                ),
                _TypeStep(
                  selectedType: _selectedType,
                  onTypeSelected: (type) => setState(() => _selectedType = type),
                ),
                LocationStep(
                  location: _location,
                  onLocationChanged: (loc) => setState(() => _location = loc),
                ),
                _ReviewStep(
                  photoPaths: _photoPaths,
                  type: _selectedType,
                  location: _location,
                  description: _description,
                  onDescriptionChanged: (desc) => setState(() => _description = desc),
                ),
              ],
            ),
          ),
          // Navigation buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _canProceed
                          ? (_currentStep == 3 ? _submit : _nextStep)
                          : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_currentStep == 3 ? 'Submit' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Photo', 'Type', 'Location', 'Review'];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: currentStep > stepIndex
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            );
          }

          // Step circle
          final stepIndex = index ~/ 2;
          final isActive = currentStep >= stepIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: currentStep > stepIndex
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isActive
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _PhotoStep extends StatefulWidget {
  final List<String> photoPaths;
  final void Function(List<String>) onPhotosChanged;

  const _PhotoStep({
    required this.photoPaths,
    required this.onPhotosChanged,
  });

  @override
  State<_PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<_PhotoStep> {
  static const int _maxFileSizeMB = 5;
  static const List<String> _allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  Future<void> _pickAndValidatePhoto(BuildContext context, ImageSource source) async {
    // Capture context-dependent values before async gap
    final l10n = S.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    // Validate file size
    final file = File(image.path);
    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);

    if (sizeInMB > _maxFileSizeMB) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.photoTooLarge),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Validate file extension
    final extension = image.path.toLowerCase().substring(
          image.path.lastIndexOf('.'),
        );

    if (!_allowedExtensions.contains(extension)) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.unsupportedPhotoFormat),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Validation passed - add photo
    widget.onPhotosChanged([...widget.photoPaths, image.path]);
  }

  void _removePhoto(int index) {
    final updated = List<String>.from(widget.photoPaths)..removeAt(index);
    widget.onPhotosChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Take a Photo',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Capture a clear photo of the issue. You can add up to 5 photos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Photo grid
          if (widget.photoPaths.isNotEmpty) ...[
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                ...widget.photoPaths.asMap().entries.map(
                      (entry) => _PhotoTile(
                        path: entry.value,
                        onRemove: () => _removePhoto(entry.key),
                      ),
                    ),
                if (widget.photoPaths.length < 5)
                  _AddPhotoTile(
                    onCamera: () => _pickAndValidatePhoto(context, ImageSource.camera),
                    onGallery: () => _pickAndValidatePhoto(context, ImageSource.gallery),
                  ),
              ],
            ),
          ] else ...[
            // Initial state - large buttons
            _PhotoPickerButtons(
              onCamera: () => _pickAndValidatePhoto(context, ImageSource.camera),
              onGallery: () => _pickAndValidatePhoto(context, ImageSource.gallery),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.path,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.md),
          child: Image.file(
            File(path),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _AddPhotoTile({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.add,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                onCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                onGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPickerButtons extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PhotoPickerButtons({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Camera button - prominent
        SizedBox(
          height: 200,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onCamera,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'Take Photo',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        // Gallery button
        OutlinedButton.icon(
          onPressed: onGallery,
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

class _TypeStep extends StatelessWidget {
  final IssueType? selectedType;
  final void Function(IssueType) onTypeSelected;

  const _TypeStep({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What type of issue?',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Select the category that best describes the problem.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // Issue type grid
          ...IssueType.values.map(
            (type) => _TypeOption(
              type: type,
              isSelected: selectedType == type,
              onTap: () => onTypeSelected(type),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IssueType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        leading: IssueTypeBadge(type: type, showLabel: false, iconSize: 24),
        title: Text(type.displayName),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final List<String> photoPaths;
  final IssueType? type;
  final GeoPoint? location;
  final String? description;
  final void Function(String?) onDescriptionChanged;

  const _ReviewStep({
    required this.photoPaths,
    required this.type,
    required this.location,
    required this.description,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Review & Submit',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Check your report details before submitting.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Photo preview
          if (photoPaths.isNotEmpty) ...[
            Text('Photos', style: theme.textTheme.labelLarge),
            const SizedBox(height: Spacing.sm),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: Image.file(
                    File(photoPaths[index]),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
          ],

          // Type
          if (type != null) ...[
            Text('Issue Type', style: theme.textTheme.labelLarge),
            const SizedBox(height: Spacing.sm),
            IssueTypeBadge(type: type!),
            const SizedBox(height: Spacing.lg),
          ],

          // Location
          if (location != null) ...[
            Text('Location', style: theme.textTheme.labelLarge),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const SizedBox(width: Spacing.sm),
                Text(
                  '${location!.latitude.toStringAsFixed(6)}, ${location!.longitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
          ],

          // Description (optional)
          Text('Description (optional)', style: theme.textTheme.labelLarge),
          const SizedBox(height: Spacing.sm),
          TextField(
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Add any additional details about the issue...',
              border: OutlineInputBorder(),
            ),
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }
}
