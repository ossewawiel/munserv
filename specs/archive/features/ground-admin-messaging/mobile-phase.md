# Ground Admin & Messaging - Mobile Phase

## Status: 🟢 Complete

## Overview

All Flutter mobile app changes for the Ground Admin & Messaging feature. This includes:
- Messages tab in bottom navigation
- Message detail and action pages
- Apply for Ground Admin flow
- Invitation response flow
- Issue verification pages
- Notification settings

## Prerequisites

- Backend Phase 1 complete (database)
- Backend messaging API available
- Backend Ground Admin API available

---

## Task Groups

### Group A: Dart Models (1 day)

Create Freezed models in `lib/shared/models/`:

**File:** `lib/shared/models/message.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

enum MessageType {
  @JsonValue('ground_admin_invitation')
  groundAdminInvitation,
  @JsonValue('ground_admin_application')
  groundAdminApplication,
  @JsonValue('ground_admin_approved')
  groundAdminApproved,
  @JsonValue('ground_admin_declined')
  groundAdminDeclined,
  @JsonValue('ground_admin_invitation_declined')
  groundAdminInvitationDeclined,
  @JsonValue('ground_admin_revocation')
  groundAdminRevocation,
  @JsonValue('ground_admin_stepdown_request')
  groundAdminStepdownRequest,
  @JsonValue('verify_new_issue')
  verifyNewIssue,
  @JsonValue('verify_fix')
  verifyFix,
  @JsonValue('member_registration')
  memberRegistration,
  @JsonValue('monthly_report')
  monthlyReport,
}

enum MessageStatus {
  unread,
  read,
  actioned,
  dismissed,
}

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required MessageType type,
    required String title,
    required String body,
    required String recipientId,
    required String recipientType,
    String? senderId,
    String? senderType,
    required MessageStatus status,
    String? actionType,
    String? relatedEntityId,
    String? relatedEntityType,
    String? actionResult,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    DateTime? readAt,
    DateTime? actionedAt,
    DateTime? expiresAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}

@freezed
class MessageListResponse with _$MessageListResponse {
  const factory MessageListResponse({
    required List<Message> items,
    required int total,
    required int page,
    required int unreadCount,
  }) = _MessageListResponse;

  factory MessageListResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageListResponseFromJson(json);
}

@freezed
class MessageActionRequest with _$MessageActionRequest {
  const factory MessageActionRequest({
    required String action,
    String? note,
  }) = _MessageActionRequest;

  factory MessageActionRequest.fromJson(Map<String, dynamic> json) =>
      _$MessageActionRequestFromJson(json);
}
```

**File:** `lib/shared/models/ground_admin.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ground_admin.freezed.dart';
part 'ground_admin.g.dart';

enum GroundAdminStatus {
  active,
  @JsonValue('on_hold')
  onHold,
  inactive,
}

@freezed
class GroundAdminInfo with _$GroundAdminInfo {
  const factory GroundAdminInfo({
    required GroundAdminStatus status,
    required DateTime since,
    required double responseRate,
    required int pendingVerifications,
    required int totalVerifications,
  }) = _GroundAdminInfo;

  factory GroundAdminInfo.fromJson(Map<String, dynamic> json) =>
      _$GroundAdminInfoFromJson(json);
}

@freezed
class GroundAdminApplication with _$GroundAdminApplication {
  const factory GroundAdminApplication({
    required String id,
    required String status,
  }) = _GroundAdminApplication;

  factory GroundAdminApplication.fromJson(Map<String, dynamic> json) =>
      _$GroundAdminApplicationFromJson(json);
}
```

**File:** `lib/shared/models/verification.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'geo_point.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

enum VerificationReason {
  busy,
  away,
  @JsonValue('cannot_find')
  cannotFind,
  @JsonValue('wrong_location')
  wrongLocation,
  @JsonValue('not_an_issue')
  notAnIssue,
}

@freezed
class PendingVerification with _$PendingVerification {
  const factory PendingVerification({
    required String verificationId,
    required String issueId,
    required String issueType,
    required String verificationType,
    required GeoPoint location,
    required DateTime requestedAt,
    double? distance,
  }) = _PendingVerification;

  factory PendingVerification.fromJson(Map<String, dynamic> json) =>
      _$PendingVerificationFromJson(json);
}

@freezed
class VerificationResponse with _$VerificationResponse {
  const factory VerificationResponse({
    required String verificationId,
    required String result,
    VerificationReason? reason,
    String? note,
    String? photoPath,
  }) = _VerificationResponse;

  factory VerificationResponse.fromJson(Map<String, dynamic> json) =>
      _$VerificationResponseFromJson(json);
}
```

**File:** `lib/shared/models/notification_settings.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings.freezed.dart';
part 'notification_settings.g.dart';

@freezed
class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    required bool pushEnabled,
    required bool verificationAlerts,
    required bool monthlyReports,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}
```

Run code generation:
```bash
cd mobile && flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Group B: API Clients (1 day)

**File:** `lib/features/messages/data/messages_api.dart`

```dart
import 'package:dio/dio.dart';
import '../../../shared/models/message.dart';
import '../../../shared/services/api_client.dart';

class MessagesApi {
  final Dio _dio;

  MessagesApi(this._dio);

  Future<MessageListResponse> getMessages({
    String? status,
    String? type,
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get('/messages', queryParameters: {
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      'page': page,
      'size': size,
    });
    return MessageListResponse.fromJson(response.data);
  }

  Future<Message> getMessage(String id) async {
    final response = await _dio.get('/messages/$id');
    return Message.fromJson(response.data);
  }

  Future<Message> markAsRead(String id) async {
    final response = await _dio.patch('/messages/$id/read');
    return Message.fromJson(response.data);
  }

  Future<Message> performAction(String id, MessageActionRequest action) async {
    final response = await _dio.post('/messages/$id/action', data: action.toJson());
    return Message.fromJson(response.data);
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/messages', queryParameters: {
      'status': 'unread',
      'size': 1,
    });
    return MessageListResponse.fromJson(response.data).unreadCount;
  }
}
```

**File:** `lib/features/ground_admin/data/ground_admin_api.dart`

```dart
import 'package:dio/dio.dart';
import '../../../shared/models/ground_admin.dart';

class GroundAdminApi {
  final Dio _dio;

  GroundAdminApi(this._dio);

  Future<GroundAdminInfo?> getMyGroundAdminInfo() async {
    final response = await _dio.get('/members/me/ground-admin');
    if (response.data == null) return null;
    return GroundAdminInfo.fromJson(response.data);
  }

  Future<GroundAdminApplication> apply() async {
    final response = await _dio.post('/members/me/ground-admin/apply');
    return GroundAdminApplication.fromJson(response.data);
  }

  Future<void> acceptInvitation(String applicationId) async {
    await _dio.post('/members/me/ground-admin/accept', data: {
      'applicationId': applicationId,
    });
  }

  Future<void> declineInvitation(String applicationId, {String? reason}) async {
    await _dio.post('/members/me/ground-admin/decline', data: {
      'applicationId': applicationId,
      if (reason != null) 'reason': reason,
    });
  }

  Future<void> stepDown({String? reason}) async {
    await _dio.post('/members/me/ground-admin/stepdown', data: {
      if (reason != null) 'reason': reason,
    });
  }
}
```

**File:** `lib/features/verification/data/verification_api.dart`

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../shared/models/verification.dart';

class VerificationApi {
  final Dio _dio;

  VerificationApi(this._dio);

  Future<List<PendingVerification>> getPendingVerifications() async {
    final response = await _dio.get('/members/me/pending-verifications');
    final items = response.data['items'] as List;
    return items.map((e) => PendingVerification.fromJson(e)).toList();
  }

  Future<void> submitVerification({
    required String issueId,
    required String verificationId,
    required String result,
    VerificationReason? reason,
    String? note,
    File? photo,
  }) async {
    String? photoId;
    
    // Upload photo first if provided
    if (photo != null) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(photo.path),
      });
      final photoResponse = await _dio.post('/issues/$issueId/photos', data: formData);
      photoId = photoResponse.data['id'];
    }

    await _dio.post('/issues/$issueId/verify', data: {
      'verificationId': verificationId,
      'result': result,
      if (reason != null) 'reason': reason.name,
      if (note != null) 'note': note,
      if (photoId != null) 'photoId': photoId,
    });
  }
}
```

---

### Group C: Riverpod Providers (1 day)

**File:** `lib/features/messages/providers/messages_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/message.dart';
import '../data/messages_api.dart';

final messagesApiProvider = Provider((ref) => MessagesApi(ref.read(dioProvider)));

final messagesProvider = FutureProvider.family<MessageListResponse, MessagesParams>(
  (ref, params) async {
    final api = ref.read(messagesApiProvider);
    return api.getMessages(
      status: params.status,
      type: params.type,
      page: params.page,
    );
  },
);

final unreadCountProvider = FutureProvider<int>((ref) async {
  final api = ref.read(messagesApiProvider);
  return api.getUnreadCount();
});

final messageDetailProvider = FutureProvider.family<Message, String>(
  (ref, id) async {
    final api = ref.read(messagesApiProvider);
    return api.getMessage(id);
  },
);

class MessagesParams {
  final String? status;
  final String? type;
  final int page;

  const MessagesParams({this.status, this.type, this.page = 1});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagesParams &&
          status == other.status &&
          type == other.type &&
          page == other.page;

  @override
  int get hashCode => Object.hash(status, type, page);
}
```

**File:** `lib/features/ground_admin/providers/ground_admin_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/ground_admin.dart';
import '../data/ground_admin_api.dart';

final groundAdminApiProvider = Provider((ref) => GroundAdminApi(ref.read(dioProvider)));

final myGroundAdminInfoProvider = FutureProvider<GroundAdminInfo?>((ref) async {
  final api = ref.read(groundAdminApiProvider);
  return api.getMyGroundAdminInfo();
});

final groundAdminApplicationProvider = StateNotifierProvider<GroundAdminApplicationNotifier, AsyncValue<GroundAdminApplication?>>(
  (ref) => GroundAdminApplicationNotifier(ref.read(groundAdminApiProvider)),
);

class GroundAdminApplicationNotifier extends StateNotifier<AsyncValue<GroundAdminApplication?>> {
  final GroundAdminApi _api;

  GroundAdminApplicationNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> apply() async {
    state = const AsyncValue.loading();
    try {
      final application = await _api.apply();
      state = AsyncValue.data(application);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> accept(String applicationId) async {
    state = const AsyncValue.loading();
    try {
      await _api.acceptInvitation(applicationId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> decline(String applicationId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _api.declineInvitation(applicationId, reason: reason);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

**File:** `lib/features/verification/providers/verification_provider.dart`

```dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/verification.dart';
import '../data/verification_api.dart';

final verificationApiProvider = Provider((ref) => VerificationApi(ref.read(dioProvider)));

final pendingVerificationsProvider = FutureProvider<List<PendingVerification>>((ref) async {
  final api = ref.read(verificationApiProvider);
  return api.getPendingVerifications();
});

final verificationSubmissionProvider = StateNotifierProvider<VerificationSubmissionNotifier, AsyncValue<void>>(
  (ref) => VerificationSubmissionNotifier(ref.read(verificationApiProvider)),
);

class VerificationSubmissionNotifier extends StateNotifier<AsyncValue<void>> {
  final VerificationApi _api;

  VerificationSubmissionNotifier(this._api) : super(const AsyncValue.data(null));

  Future<bool> submit({
    required String issueId,
    required String verificationId,
    required String result,
    VerificationReason? reason,
    String? note,
    File? photo,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _api.submitVerification(
        issueId: issueId,
        verificationId: verificationId,
        result: result,
        reason: reason,
        note: note,
        photo: photo,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
```

---

### Group D: Messages UI (3-4 days)

#### D1: Messages Page

**File:** `lib/features/messages/presentation/pages/messages_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/message_list_tile.dart';
import '../../providers/messages_provider.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(MessagesParams(status: _statusFilter)));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).messages),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(S.of(context).all)),
              PopupMenuItem(value: 'unread', child: Text(S.of(context).unread)),
              PopupMenuItem(value: 'actioned', child: Text(S.of(context).actioned)),
            ],
          ),
        ],
      ),
      body: messagesAsync.when(
        data: (response) {
          if (response.items.isEmpty) {
            return Center(child: Text(S.of(context).noMessages));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(messagesProvider(MessagesParams(status: _statusFilter)).future),
            child: ListView.separated(
              itemCount: response.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final message = response.items[index];
                return MessageListTile(
                  message: message,
                  onTap: () => _openMessage(message),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _openMessage(Message message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailPage(messageId: message.id),
      ),
    );
  }
}
```

#### D2: Message List Tile

**File:** `lib/features/messages/presentation/widgets/message_list_tile.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../shared/models/message.dart';
import '../../../../shared/utils/date_formatter.dart';

class MessageListTile extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;

  const MessageListTile({
    super.key,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = message.status == MessageStatus.unread;
    final theme = Theme.of(context);

    return ListTile(
      leading: _buildIcon(),
      title: Text(
        message.title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        message.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatRelativeTime(message.createdAt),
            style: theme.textTheme.bodySmall,
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (message.type) {
      case MessageType.groundAdminInvitation:
      case MessageType.groundAdminApplication:
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case MessageType.verifyNewIssue:
      case MessageType.verifyFix:
        icon = Icons.fact_check;
        color = Colors.orange;
        break;
      case MessageType.groundAdminApproved:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case MessageType.groundAdminDeclined:
      case MessageType.groundAdminRevocation:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.mail;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }
}
```

#### D3: Message Detail Page

**File:** `lib/features/messages/presentation/pages/message_detail_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/message.dart';
import '../../providers/messages_provider.dart';
import '../widgets/message_action_buttons.dart';

class MessageDetailPage extends ConsumerStatefulWidget {
  final String messageId;

  const MessageDetailPage({super.key, required this.messageId});

  @override
  ConsumerState<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends ConsumerState<MessageDetailPage> {
  @override
  void initState() {
    super.initState();
    // Mark as read when opened
    Future.microtask(() => _markAsRead());
  }

  Future<void> _markAsRead() async {
    final api = ref.read(messagesApiProvider);
    await api.markAsRead(widget.messageId);
    ref.invalidate(unreadCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final messageAsync = ref.watch(messageDetailProvider(widget.messageId));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).messageDetail),
      ),
      body: messageAsync.when(
        data: (message) => _buildContent(message),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(Message message) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            formatDateTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 32),
          Text(
            message.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          if (message.status != MessageStatus.actioned && message.actionType != null)
            MessageActionButtons(
              message: message,
              onAction: (action, note) => _handleAction(message, action, note),
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(Message message, String action, String? note) async {
    // Handle special message types that need navigation
    if (message.type == MessageType.verifyNewIssue || message.type == MessageType.verifyFix) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyIssuePage(
            issueId: message.relatedEntityId!,
            verificationType: message.type == MessageType.verifyNewIssue ? 'existence' : 'fix',
          ),
        ),
      );
      return;
    }

    final api = ref.read(messagesApiProvider);
    await api.performAction(message.id, MessageActionRequest(action: action, note: note));
    ref.invalidate(messageDetailProvider(widget.messageId));
    ref.invalidate(messagesProvider(const MessagesParams()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).actionCompleted)),
      );
      Navigator.pop(context);
    }
  }
}
```

#### D4: Message Action Buttons

**File:** `lib/features/messages/presentation/widgets/message_action_buttons.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../shared/models/message.dart';

class MessageActionButtons extends StatelessWidget {
  final Message message;
  final void Function(String action, String? note) onAction;

  const MessageActionButtons({
    super.key,
    required this.message,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getActionsForType(message.actionType);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => onAction(action.value, null),
              style: ElevatedButton.styleFrom(
                backgroundColor: action.isPrimary 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
              ),
              child: Text(action.label),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_ActionInfo> _getActionsForType(String? actionType) {
    switch (actionType) {
      case 'accept_decline':
        return [
          _ActionInfo('accept', S.current.accept, true),
          _ActionInfo('decline', S.current.decline, false),
        ];
      case 'approve_reject':
        return [
          _ActionInfo('approve', S.current.approve, true),
          _ActionInfo('reject', S.current.reject, false),
        ];
      case 'confirm_verify':
        return [
          _ActionInfo('confirm', S.current.confirm, true),
          _ActionInfo('cannot_verify', S.current.cannotVerify, false),
        ];
      case 'acknowledge':
        return [
          _ActionInfo('dismiss', S.current.dismiss, true),
        ];
      default:
        return [];
    }
  }
}

class _ActionInfo {
  final String value;
  final String label;
  final bool isPrimary;

  _ActionInfo(this.value, this.label, this.isPrimary);
}
```

---

### Group E: Ground Admin Flow (2-3 days)

#### E1: Apply for Ground Admin Page

**File:** `lib/features/ground_admin/presentation/pages/apply_ground_admin_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ground_admin_provider.dart';

class ApplyGroundAdminPage extends ConsumerWidget {
  const ApplyGroundAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationState = ref.watch(groundAdminApplicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).becomeGroundAdmin),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(context),
            const SizedBox(height: 24),
            _buildResponsibilitiesSection(context),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: applicationState.isLoading
                    ? null
                    : () => _apply(context, ref),
                child: applicationState.isLoading
                    ? const CircularProgressIndicator()
                    : Text(S.of(context).applyNow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  S.of(context).whatIsGroundAdmin,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(S.of(context).groundAdminDescription),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibilitiesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).responsibilities,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildResponsibilityItem(context, Icons.fact_check, S.of(context).verifyNewIssues),
            _buildResponsibilityItem(context, Icons.check_circle, S.of(context).confirmFixes),
            _buildResponsibilityItem(context, Icons.camera_alt, S.of(context).providePhotoEvidence),
            _buildResponsibilityItem(context, Icons.schedule, S.of(context).respondPromptly),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibilityItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    await ref.read(groundAdminApplicationProvider.notifier).apply();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).applicationSubmitted)),
      );
      Navigator.pop(context);
    }
  }
}
```

#### E2: Invitation Response Page

**File:** `lib/features/ground_admin/presentation/pages/invitation_response_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ground_admin_provider.dart';

class InvitationResponsePage extends ConsumerWidget {
  final String applicationId;
  final String inviterName;

  const InvitationResponsePage({
    super.key,
    required this.applicationId,
    required this.inviterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groundAdminApplicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).groundAdminInvitation),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).invitedByAdmin(inviterName),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(S.of(context).groundAdminInvitationDescription),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isLoading ? null : () => _decline(context, ref),
                    child: Text(S.of(context).decline),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : () => _accept(context, ref),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(S.of(context).accept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    await ref.read(groundAdminApplicationProvider.notifier).accept(applicationId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).youAreNowGroundAdmin)),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    await ref.read(groundAdminApplicationProvider.notifier).decline(applicationId);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
```

#### E3: Update Settings Page

Add Ground Admin section to existing settings page:

```dart
// In settings_page.dart, add this section:

Widget _buildGroundAdminSection(BuildContext context, WidgetRef ref) {
  final gaInfoAsync = ref.watch(myGroundAdminInfoProvider);

  return gaInfoAsync.when(
    data: (info) {
      if (info != null) {
        // Already a Ground Admin
        return _buildGroundAdminStatus(context, info);
      }
      // Not a Ground Admin - show apply button
      return ListTile(
        leading: const Icon(Icons.volunteer_activism),
        title: Text(S.of(context).becomeGroundAdmin),
        subtitle: Text(S.of(context).helpVerifyIssues),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApplyGroundAdminPage()),
        ),
      );
    },
    loading: () => const ListTile(
      leading: CircularProgressIndicator(),
      title: Text('Loading...'),
    ),
    error: (_, __) => const SizedBox.shrink(),
  );
}

Widget _buildGroundAdminStatus(BuildContext context, GroundAdminInfo info) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                S.of(context).groundAdminStatus,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatRow(S.of(context).status, info.status.name.toUpperCase()),
          _buildStatRow(S.of(context).responseRate, '${info.responseRate.toStringAsFixed(1)}%'),
          _buildStatRow(S.of(context).pendingVerifications, info.pendingVerifications.toString()),
        ],
      ),
    ),
  );
}
```

---

### Group F: Verification UI (3-4 days)

#### F1: Verify Issue Page

**File:** `lib/features/verification/presentation/pages/verify_issue_page.dart`

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/models/verification.dart';
import '../../providers/verification_provider.dart';

class VerifyIssuePage extends ConsumerStatefulWidget {
  final String issueId;
  final String verificationType;

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
  VerificationReason? _reason;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(verificationSubmissionProvider);
    final isExistence = widget.verificationType == 'existence';

    return Scaffold(
      appBar: AppBar(
        title: Text(isExistence 
            ? S.of(context).verifyIssueExists 
            : S.of(context).verifyIssueFix),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Issue info card would go here (fetch issue details)
            _buildPhotoSection(),
            const SizedBox(height: 24),
            _buildActionButtons(isExistence, submissionState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).addPhoto,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(S.of(context).photoOptional),
            const SizedBox(height: 12),
            if (_photo != null)
              Stack(
                children: [
                  Image.file(_photo!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
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
                      label: Text(S.of(context).camera),
                      onPressed: () => _pickPhoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: Text(S.of(context).gallery),
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

  Widget _buildActionButtons(bool isExistence, bool isLoading) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _submit('confirmed'),
            child: Text(isExistence 
                ? S.of(context).confirmExists 
                : S.of(context).confirmFixed),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : () => _showCannotVerifyDialog(),
            child: Text(isExistence 
                ? S.of(context).cannotVerify 
                : S.of(context).notFixed),
          ),
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
    final success = await ref.read(verificationSubmissionProvider.notifier).submit(
      issueId: widget.issueId,
      verificationId: 'TODO', // Get from pending verification
      result: result,
      reason: _reason,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      photo: _photo,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).verificationSubmitted)),
      );
      Navigator.pop(context);
    }
  }

  void _showCannotVerifyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).cannotVerify),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...VerificationReason.values.map((reason) => RadioListTile<VerificationReason>(
              value: reason,
              groupValue: _reason,
              title: Text(_getReasonLabel(reason)),
              onChanged: (value) => setState(() => _reason = value),
            )),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: S.of(context).additionalNote,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: _reason != null ? () {
              Navigator.pop(context);
              _submit('cannot_verify');
            } : null,
            child: Text(S.of(context).submit),
          ),
        ],
      ),
    );
  }

  String _getReasonLabel(VerificationReason reason) {
    switch (reason) {
      case VerificationReason.busy:
        return S.of(context).reasonBusy;
      case VerificationReason.away:
        return S.of(context).reasonAway;
      case VerificationReason.cannotFind:
        return S.of(context).reasonCannotFind;
      case VerificationReason.wrongLocation:
        return S.of(context).reasonWrongLocation;
      case VerificationReason.notAnIssue:
        return S.of(context).reasonNotAnIssue;
    }
  }
}
```

---

### Group G: Navigation Updates (1 day)

#### G1: Update Bottom Navigation

**File:** Update `lib/navigation/app_navigation.dart`

Add Messages tab:
```dart
BottomNavigationBarItem(
  icon: Badge(
    label: Text(unreadCount.toString()),
    isLabelVisible: unreadCount > 0,
    child: const Icon(Icons.mail_outline),
  ),
  activeIcon: Badge(
    label: Text(unreadCount.toString()),
    isLabelVisible: unreadCount > 0,
    child: const Icon(Icons.mail),
  ),
  label: S.of(context).messages,
),
```

#### G2: Notification Settings

Add to settings page notification preferences section.

---

## i18n Keys

**File:** `lib/l10n/app_en.arb`

```json
{
  "messages": "Messages",
  "noMessages": "No messages",
  "unread": "Unread",
  "actioned": "Actioned",
  "messageDetail": "Message",
  "actionCompleted": "Action completed",
  
  "becomeGroundAdmin": "Become a Ground Admin",
  "whatIsGroundAdmin": "What is a Ground Admin?",
  "groundAdminDescription": "Ground Admins are trusted community members who help verify issues on the ground. They confirm that reported problems exist and that fixes are complete.",
  "responsibilities": "Responsibilities",
  "verifyNewIssues": "Verify that reported issues exist",
  "confirmFixes": "Confirm when issues are properly fixed",
  "providePhotoEvidence": "Provide photo evidence when needed",
  "respondPromptly": "Respond to verification requests promptly",
  "applyNow": "Apply Now",
  "applicationSubmitted": "Your application has been submitted",
  
  "groundAdminInvitation": "Ground Admin Invitation",
  "invitedByAdmin": "{name} has invited you to become a Ground Admin",
  "groundAdminInvitationDescription": "As a Ground Admin, you'll help verify issues in your community.",
  "youAreNowGroundAdmin": "You are now a Ground Admin!",
  "helpVerifyIssues": "Help verify issues in your community",
  
  "groundAdminStatus": "Ground Admin",
  "status": "Status",
  "responseRate": "Response Rate",
  "pendingVerifications": "Pending Verifications",
  
  "verifyIssueExists": "Verify Issue Exists",
  "verifyIssueFix": "Verify Fix",
  "addPhoto": "Add Photo",
  "photoOptional": "Optional: Take a photo as evidence",
  "camera": "Camera",
  "gallery": "Gallery",
  "confirmExists": "Confirm Issue Exists",
  "confirmFixed": "Confirm Fix is Complete",
  "cannotVerify": "Cannot Verify",
  "notFixed": "Not Fixed",
  "verificationSubmitted": "Verification submitted",
  
  "additionalNote": "Additional note (optional)",
  "reasonBusy": "I'm busy right now",
  "reasonAway": "I'm away from the area",
  "reasonCannotFind": "Cannot find the issue",
  "reasonWrongLocation": "Location seems incorrect",
  "reasonNotAnIssue": "This is not actually an issue",
  
  "accept": "Accept",
  "decline": "Decline",
  "approve": "Approve",
  "reject": "Reject",
  "confirm": "Confirm",
  "dismiss": "Dismiss",
  "cancel": "Cancel",
  "submit": "Submit"
}
```

---

## Testing Checklist

### Unit Tests
- [ ] Message models serialize/deserialize
- [ ] Ground Admin models serialize/deserialize
- [ ] Verification models serialize/deserialize
- [ ] API clients handle responses correctly

### Widget Tests
- [ ] MessageListTile displays correctly
- [ ] MessageDetailPage shows action buttons
- [ ] ApplyGroundAdminPage form works
- [ ] VerifyIssuePage photo capture works

### Integration Tests
- [ ] Messages flow end-to-end
- [ ] Ground Admin application flow
- [ ] Verification submission flow

---

## Commands

```bash
# Generate models
cd mobile && flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
cd mobile && flutter test

# Run specific test
cd mobile && flutter test test/features/messages/

# Run app
cd mobile && flutter run
```

---

## Definition of Done

- [ ] All Dart models generated with Freezed
- [ ] All API clients implemented
- [ ] All Riverpod providers working
- [ ] Messages tab in bottom navigation
- [ ] Messages page displays correctly
- [ ] Message detail with actions
- [ ] Apply for Ground Admin flow
- [ ] Invitation response flow
- [ ] Issue verification pages
- [ ] Notification settings
- [ ] All i18n keys added
- [ ] No lint errors
- [ ] Tests passing

---

## Handoff Notes

**For agent execution:**
```bash
cd mobile
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md
cat ../specs/features/ground-admin-messaging/spec.md

# Follow existing patterns in mobile/lib/features/
# Use Riverpod for state management
# Use Freezed for all models
# Start with models → API → providers → pages
```
