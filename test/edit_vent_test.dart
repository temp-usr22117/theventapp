import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theventapp/models/post_model.dart';
import 'package:theventapp/utils/time_ago.dart';
import 'package:theventapp/widgets/vent_widgets.dart';

Map<String, dynamic> _map({Object? editedAt}) => {
      'id': 'p1',
      'user_id': 'u1',
      'content': 'hello world',
      'likes_count': 0,
      'created_at': '2026-01-01T00:00:00.000',
      'edited_at': editedAt,
      'users': {'username': 'anon', 'profile_picture_url': null},
    };

void main() {
  group('timeAgo', () {
    final now = DateTime(2026, 11, 19, 12);

    test('formats each bucket', () {
      expect(timeAgo(now.subtract(const Duration(seconds: 30)), now: now),
          'just now');
      expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
          '5m ago');
      expect(
          timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
      expect(
          timeAgo(now.subtract(const Duration(days: 2)), now: now), '2d ago');
      expect(
          timeAgo(now.subtract(const Duration(days: 15)), now: now), '2w ago');
    });
  });

  group('PostModel edited_at', () {
    test('unedited vents have no editedAt', () {
      final post = PostModel.fromMap(_map());
      expect(post.editedAt, isNull);
      expect(post.isEdited, isFalse);
    });

    test('parses editedAt for edited vents', () {
      final post = PostModel.fromMap(_map(editedAt: '2026-01-02T10:00:00.000'));
      expect(post.editedAt, DateTime(2026, 1, 2, 10));
      expect(post.isEdited, isTrue);
    });
  });

  group('Vent widgets', () {
    Future<void> pump(WidgetTester tester, Widget child) {
      return tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: child))),
      );
    }

    testWidgets('EditedBadge shows edited label with time', (tester) async {
      await pump(
        tester,
        EditedBadge(
          editedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      expect(find.text('Edited · 5m ago'), findsOneWidget);
    });

    testWidgets('VentOwnerMenu offers Edit and Delete', (tester) async {
      var edited = 0;
      var deleted = 0;
      await pump(
        tester,
        VentOwnerMenu(onEdit: () => edited++, onDelete: () => deleted++),
      );

      await tester.tap(find.byTooltip('Vent options'));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(edited, 1);

      await tester.tap(find.byTooltip('Vent options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, 1);
    });
  });
}
