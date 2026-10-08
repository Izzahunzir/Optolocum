import 'package:flutter/material.dart';

import 'CO_notifications.dart';
import 'CO_navigation.dart';
import 'CO_mainpage.dart';
import 'CO_profile.dart';

class COChatMessage {
  const COChatMessage({
    required this.id,
    required this.text,
    this.isFromClinic = false,
  });
  final String id, text;
  final bool isFromClinic;
}

class COMessages extends StatefulWidget {
  const COMessages({super.key, required this.conversation, this.onSendMessage});
  final COConversation conversation;
  final Future<void> Function(String conversationId, String message)?
  onSendMessage;

  @override
  State<COMessages> createState() => _COMessagesState();
}

class _COMessagesState extends State<COMessages> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || widget.onSendMessage == null) return;
    setState(() => _sending = true);
    try {
      await widget.onSendMessage!(widget.conversation.id, text);
      if (mounted && _input.text.trim() == text) _input.clear();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message could not be sent. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2FAFE),
    appBar: AppBar(
      title: const Text(
        'Messages',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF3B4E92),
      foregroundColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
          child: Text(
            widget.conversation.applicantName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: widget.conversation.messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    itemCount: widget.conversation.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.conversation.messages[index];
                      return Align(
                        alignment: message.isFromClinic
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: message.isFromClinic
                                ? const Color(0xFFDDF0FF)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(8),
                              topRight: const Radius.circular(8),
                              bottomLeft: Radius.circular(
                                message.isFromClinic ? 8 : 0,
                              ),
                              bottomRight: Radius.circular(
                                message.isFromClinic ? 0 : 8,
                              ),
                            ),
                          ),
                          child: Text(
                            message.text,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                helperText: widget.onSendMessage == null
                    ? 'Messaging will be available once connected.'
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: CONavigation(
      notificationsSelected: true,
      onNotifications: () => Navigator.pop(context),
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
  );
}
