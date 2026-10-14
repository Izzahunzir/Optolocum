import 'package:flutter/material.dart';

class LocumNotification {
  const LocumNotification({
    required this.id,
    required this.text,
    this.isUnread = false,
  });
  final String id, text;
  final bool isUnread;
}

class LocumMessage {
  const LocumMessage({required this.text, this.isFromLocum = false});
  final String text;
  final bool isFromLocum;
}

class LocumConversation {
  const LocumConversation({
    required this.id,
    required this.name,
    required this.preview,
    this.isUnread = false,
    this.messages = const [],
  });
  final String id, name, preview;
  final bool isUnread;
  final List<LocumMessage> messages;
}

/// Supply inbox data for the signed-in locum from the messaging service.
class LNotifications extends StatefulWidget {
  const LNotifications({
    super.key,
    this.notifications = const [],
    this.conversations = const [],
    this.onNotificationTap,
    this.onConversationRead,
    this.onSendMessage,
  });
  final List<LocumNotification> notifications;
  final List<LocumConversation> conversations;
  final ValueChanged<LocumNotification>? onNotificationTap;
  final ValueChanged<LocumConversation>? onConversationRead;
  final Future<void> Function(String conversationId, String text)?
  onSendMessage;

  @override
  State<LNotifications> createState() => _LNotificationsState();
}

class _LNotificationsState extends State<LNotifications> {
  static const _teal = Color(0xFF237F7D);
  final _input = TextEditingController();
  final _readNotifications = <String>{};
  final _readConversations = <String>{};
  LocumConversation? _conversation;
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final thread = _conversation;
    if (text.isEmpty ||
        _sending ||
        thread == null ||
        widget.onSendMessage == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSendMessage!(thread.id, text);
      if (mounted && _input.text.trim() == text) _input.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message could not be sent. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _row(String text, bool unread, VoidCallback onTap) => Material(
    color: const Color(0xFFEBF5F3),
    child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFD3DEDC))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 18),
              Semantics(
                label: 'Unread',
                child: const Icon(Icons.circle, size: 11, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _empty(String text) => Center(
    child: Text(text, style: const TextStyle(color: Colors.black54)),
  );

  @override
  Widget build(BuildContext context) {
    final selected = _conversation;
    if (selected != null) {
      final thread =
          widget.conversations
              .where((item) => item.id == selected.id)
              .firstOrNull ??
          selected;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) setState(() => _conversation = null);
        },
        child: Column(
          children: [
            Container(
              color: _teal,
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Center(
                          child: Text(
                            'Messages',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Back to inbox',
                            onPressed: () =>
                                setState(() => _conversation = null),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    thread.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: thread.messages.isEmpty
                  ? _empty('No messages yet')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 30,
                      ),
                      itemCount: thread.messages.length,
                      itemBuilder: (context, index) {
                        final message = thread.messages[index];
                        return Align(
                          alignment: message.isFromLocum
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .76,
                            ),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: message.isFromLocum
                                  ? const Color(0xFFDDF0EC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              message.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                readOnly: _sending || widget.onSendMessage == null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  suffixIcon: widget.onSendMessage == null
                      ? null
                      : IconButton(
                          tooltip: 'Send message',
                          onPressed: _sending ? null : _send,
                          icon: Icon(
                            _sending
                                ? Icons.hourglass_empty
                                : Icons.send_outlined,
                            color: _teal,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: _teal,
            child: Column(
              children: [
                const SizedBox(
                  height: 72,
                  child: Center(
                    child: Text(
                      'Inbox',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(fontSize: 13),
                  indicatorColor: const Color(0xFFFFB343),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'Notifications (${widget.notifications.length})'),
                    Tab(text: 'Messages (${widget.conversations.length})'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                widget.notifications.isEmpty
                    ? _empty('No notifications yet')
                    : ListView(
                        children: widget.notifications
                            .map(
                              (item) => _row(
                                item.text,
                                item.isUnread &&
                                    !_readNotifications.contains(item.id),
                                () {
                                  setState(
                                    () => _readNotifications.add(item.id),
                                  );
                                  widget.onNotificationTap?.call(item);
                                },
                              ),
                            )
                            .toList(),
                      ),
                widget.conversations.isEmpty
                    ? _empty('No messages yet')
                    : ListView(
                        children: widget.conversations
                            .map(
                              (thread) => _row(
                                thread.preview,
                                thread.isUnread &&
                                    !_readConversations.contains(thread.id),
                                () {
                                  setState(() {
                                    _readConversations.add(thread.id);
                                    _conversation = thread;
                                    _input.clear();
                                  });
                                  widget.onConversationRead?.call(thread);
                                },
                              ),
                            )
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
