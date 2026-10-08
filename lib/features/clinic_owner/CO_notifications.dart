import 'package:flutter/material.dart';

import 'CO_navigation.dart';
import 'CO_mainpage.dart';
import 'CO_profile.dart';
import 'CO_messages.dart';

class CONotification {
  const CONotification({
    required this.id,
    required this.clinicOwnerId,
    required this.jobId,
    required this.text,
    this.isUnread = false,
  });
  final String id, clinicOwnerId, jobId, text;
  final bool isUnread;
}

class COConversation {
  const COConversation({
    required this.id,
    required this.clinicOwnerId,
    required this.applicantName,
    required this.preview,
    this.jobId,
    this.isUnread = false,
    this.messages = const [],
  });
  final String id, clinicOwnerId, applicantName, preview;
  final String? jobId;
  final bool isUnread;
  final List<COChatMessage> messages;
}

/// Inject account-scoped events and conversations from the future inbox service.
class CONotifications extends StatelessWidget {
  const CONotifications({
    super.key,
    this.clinicOwnerId,
    this.notifications = const [],
    this.conversations = const [],
    this.onNotificationTap,
    this.onConversationRead,
    this.onSendMessage,
  });
  final String? clinicOwnerId;
  final List<CONotification> notifications;
  final List<COConversation> conversations;
  final ValueChanged<CONotification>? onNotificationTap;
  final ValueChanged<COConversation>? onConversationRead;
  final Future<void> Function(String conversationId, String message)?
  onSendMessage;

  @override
  Widget build(BuildContext context) {
    final events = notifications
        .where(
          (item) =>
              clinicOwnerId != null && item.clinicOwnerId == clinicOwnerId,
        )
        .toList();
    final threads = conversations
        .where(
          (item) =>
              clinicOwnerId != null && item.clinicOwnerId == clinicOwnerId,
        )
        .toList();
    Widget empty(String text) => Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
    Widget row(String text, bool unread, VoidCallback? onTap) => Material(
      color: const Color(0xFFDDF0FF),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFCDD6DD))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(width: 16),
              if (unread)
                Semantics(
                  label: 'Unread',
                  child: const Icon(Icons.circle, color: Colors.red, size: 12),
                ),
            ],
          ),
        ),
      ),
    );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2FAFE),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: const Color(0xFF3B4E92),
          foregroundColor: Colors.white,
          title: const Text(
            'Inbox',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            indicatorColor: const Color(0xFFFFAD45),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Notifications (${events.length})'),
              Tab(text: 'Messages (${threads.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            events.isEmpty
                ? empty('No notifications yet')
                : ListView(
                    children: events
                        .map(
                          (item) => row(
                            item.text,
                            item.isUnread,
                            onNotificationTap == null
                                ? null
                                : () => onNotificationTap!(item),
                          ),
                        )
                        .toList(),
                  ),
            threads.isEmpty
                ? empty('No messages yet')
                : ListView(
                    children: threads
                        .map(
                          (thread) => row(thread.preview, thread.isUnread, () {
                            onConversationRead?.call(thread);
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => COMessages(
                                  conversation: thread,
                                  onSendMessage: onSendMessage,
                                ),
                              ),
                            );
                          }),
                        )
                        .toList(),
                  ),
          ],
        ),
        bottomNavigationBar: CONavigation(
          notificationsSelected: true,
          onNotifications: () {},
          onHome: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (_) => const COMainPage()),
            (route) => route.isFirst,
          ),
          onProfile: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const COProfile()),
          ),
        ),
      ),
    );
  }
}
