import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/issue_type.dart';
import '../../../../shared/models/verification.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../../issues/domain/domain.dart';
import '../../../issues/providers/issue_providers.dart';
import '../../providers/verification_providers.dart';

/// Page for Ground Admins to verify an issue's existence or fix.
class VerifyIssuePage extends ConsumerStatefulWidget {
  final String issueId;
  final String verificationType; // 'existence' or 'fix'

  const VerifyIssuePage({
    super.key,
    required this.issueId,
    required this.verificationType,
  });

  @override
  ConsumerState<VerifyIssuePage> createState() => _VerifyIssuePageState();
}

class _VerifyIssuePageState extends ConsumerState<VerifyIssuePage> {
  File? _photo;
  VerificationReason? _selectedReason;
  final _noteController = TextEditingController();

  bool get isExistence => widget.verificationType == 'existence';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final issueAsync = ref.watch(issueDetailProvider(widget.issueId));
    final submitState = ref.watch(verificationSubmitProvider);
    final isLoading = submitState is VerificationSubmitStateLoading;

    // Handle submit state changes
    ref.listen(verificationSubmitProvider, (previous, next) {
      if (next is VerificationSubmitStateSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.verificationSubmitted)));
        context.pop();
      } else if (next is VerificationSubmitStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isExistence ? l10n.verifyIssueExists : l10n.verifyIssueFix),
      ),
      body: issueAsync.when(
        data: (issue) => _buildContent(context, issue, isLoading),
        loading: () => const LoadingSpinner(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    IssueDetail issue,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issue info card
          _buildIssueInfoCard(context, issue),
          const SizedBox(height: Spacing.lg),

          // Photo section
          _buildPhotoSection(context),
          const SizedBox(height: Spacing.lg),

          // Note section
          _buildNoteSection(context),
          const SizedBox(height: Spacing.xl),

          // Action buttons
          _buildActionButtons(context, isLoading),
        ],
      ),
    );
  }

  Widget _buildIssueInfoCard(BuildContext context, IssueDetail issue) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = S.of(context);

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem, color: colors.primary),
                const SizedBox(width: Spacing.sm),
                Text(
                  IssueType.fromString(issue.type).displayName,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            if (issue.description != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                issue.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: IconSizes.sm,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    issue.address ??
                        'Lat: ${issue.location.latitude.toStringAsFixed(5)}, Lng: ${issue.location.longitude.toStringAsFixed(5)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: () => context.push('/issues/${widget.issueId}/map'),
              icon: const Icon(Icons.map),
              label: Text(l10n.viewOnMap),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = S.of(context);

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addPhoto, style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.photoOptional,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.md),
            if (_photo != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: Image.file(
                      _photo!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: Spacing.xs,
                    right: Spacing.xs,
                    child: IconButton.filled(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _photo = null),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: Text(l10n.camera),
                      onPressed: () => _pickPhoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: Text(l10n.gallery),
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = S.of(context);

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.additionalNote, style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.noteHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isLoading) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: isLoading ? null : () => _submit('confirmed'),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isExistence ? l10n.confirmExists : l10n.confirmFixed),
        ),
        const SizedBox(height: Spacing.sm),
        OutlinedButton(
          onPressed: isLoading ? null : _showCannotVerifyDialog,
          child: Text(isExistence ? l10n.cannotVerify : l10n.notFixed),
        ),
      ],
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _photo = File(image.path));
    }
  }

  Future<void> _submit(String result) async {
    // Get verificationId from pending verifications
    final pending = ref.read(pendingVerificationsProvider).value;
    final verification = pending?.firstWhere(
      (v) => v.issueId == widget.issueId,
      orElse: () => pending.first,
    );

    if (verification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).verificationNotFound)),
      );
      return;
    }

    await ref
        .read(verificationSubmitProvider.notifier)
        .submit(
          issueId: widget.issueId,
          verificationId: verification.verificationId,
          result: result,
          reason: _selectedReason,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          photo: _photo,
        );
  }

  void _showCannotVerifyDialog() {
    final l10n = S.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.cannotVerify),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.selectReason),
                const SizedBox(height: Spacing.sm),
                RadioGroup<VerificationReason>(
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setDialogState(() => _selectedReason = value);
                    setState(() {});
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: VerificationReason.values
                        .map(
                          (reason) => RadioListTile<VerificationReason>(
                            value: reason,
                            title: Text(reason.displayName),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: _selectedReason != null
                    ? () {
                        Navigator.pop(context);
                        _submit('cannot_verify');
                      }
                    : null,
                child: Text(l10n.submit),
              ),
            ],
          );
        },
      ),
    );
  }
}
