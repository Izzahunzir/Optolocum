import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';
import 'package:optolocum/features/clinic_owner/CO_notifications.dart';
import 'package:optolocum/features/clinic_owner/CO_messages.dart';

void main() {
  testWidgets('Notifications navigation opens an empty inbox', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: COMainPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications (0)'), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
    await tester.tap(find.text('Messages (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No messages yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Inbox filters accounts, opens messages and sends through its callback',
    (tester) async {
      String? selectedJob, readThread, sent;
      await tester.pumpWidget(
        MaterialApp(
          home: CONotifications(
            clinicOwnerId: 'owner-1',
            notifications: const [
              CONotification(
                id: 'event-1',
                clinicOwnerId: 'owner-1',
                jobId: 'job-1',
                text: 'New application for your posting',
                isUnread: true,
              ),
              CONotification(
                id: 'event-2',
                clinicOwnerId: 'owner-2',
                jobId: 'job-2',
                text: 'Other account event',
              ),
            ],
            conversations: const [
              COConversation(
                id: 'thread-1',
                clinicOwnerId: 'owner-1',
                applicantName: 'Applicant',
                preview: 'I have applied for your job',
                isUnread: true,
                messages: [
                  COChatMessage(
                    id: 'message-1',
                    text: 'I am available for this shift.',
                  ),
                ],
              ),
            ],
            onNotificationTap: (event) => selectedJob = event.jobId,
            onConversationRead: (thread) => readThread = thread.id,
            onSendMessage: (id, text) async {
              sent = '$id:$text';
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notifications (1)'), findsOneWidget);
      expect(find.text('Other account event'), findsNothing);
      await tester.tap(find.text('New application for your posting'));
      expect(selectedJob, 'job-1');
      await tester.tap(find.text('Messages (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I have applied for your job'));
      await tester.pumpAndSettle();
      expect(readThread, 'thread-1');
      expect(find.text('Applicant'), findsOneWidget);
      expect(find.text('I am available for this shift.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Thanks for applying');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(sent, 'thread-1:Thanks for applying');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
