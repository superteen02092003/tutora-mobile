import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';
import 'package:tutora/features/tutor/presentation/widgets/swipeable_convo_item.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

void main() {
  test('chat channel keeps the avatar URL returned by the API', () {
    final channel = ChatChannelDto.fromJson({
      'channelId': 12,
      'bookingId': 34,
      'otherUserId': 'tutor-1',
      'otherUserName': 'Nguyễn An',
      'otherUserAvatarUrl': 'https://cdn.example.com/tutor-1.png',
    });

    expect(
      channel.otherUserAvatarUrl,
      'https://cdn.example.com/tutor-1.png',
    );
  });

  testWidgets('user avatar uses initials when the avatar URL is blank', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UserAvatar(
          name: 'Nguyễn Quân',
          imageUrl: '   ',
          size: 54,
        ),
      ),
    );

    expect(find.text('NQ'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('user avatar uses the real image when a URL is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UserAvatar(
          name: 'Nguyễn Quân',
          imageUrl: 'https://cdn.example.com/avatar.png',
          size: 54,
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('NQ'), findsNothing);
  });

  testWidgets('swiping a conversation left reveals and runs delete', (
    tester,
  ) async {
    var deleted = false;
    const channel = ChatChannelDto(
      channelId: 12,
      bookingId: 34,
      otherUserId: 'tutor-1',
      otherUserName: 'Nguyễn An',
      otherUserAvatarUrl: '',
      status: 'active',
      lastMessageAt: '',
      lastMessagePreview: 'Xin chào',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeableConvoItem(
            channel: channel,
            onTap: () {},
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.fling(
      find.byType(SwipeableConvoItem),
      const Offset(-250, 0),
      1000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));

    expect(deleted, isTrue);
  });
}
