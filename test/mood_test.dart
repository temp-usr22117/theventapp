import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theventapp/models/mood.dart';
import 'package:theventapp/models/post_model.dart';
import 'package:theventapp/widgets/mood_widgets.dart';

PostModel _post(String id, {Mood? mood}) => PostModel(
      id: id,
      userId: 'u1',
      content: 'content $id',
      likesCount: 0,
      createdAt: DateTime(2026, 1, 1),
      username: 'anon',
      mood: mood,
    );

Map<String, dynamic> _map({Object? mood}) => {
      'id': 'p1',
      'user_id': 'u1',
      'content': 'hello world',
      'likes_count': 2,
      'created_at': '2026-01-01T00:00:00.000',
      'mood': mood,
      'users': {'username': 'anon', 'profile_picture_url': null},
    };

void main() {
  group('Mood.fromKey', () {
    test('parses every stored key', () {
      for (final mood in Mood.values) {
        expect(Mood.fromKey(mood.key), mood);
      }
    });

    test('returns null for missing, unknown, or non-string values', () {
      expect(Mood.fromKey(null), isNull);
      expect(Mood.fromKey('ecstatic'), isNull);
      expect(Mood.fromKey(42), isNull);
    });

    test('keys are unique', () {
      final keys = Mood.values.map((m) => m.key).toSet();
      expect(keys.length, Mood.values.length);
    });
  });

  group('PostModel.fromMap mood', () {
    test('reads a tagged mood', () {
      expect(PostModel.fromMap(_map(mood: 'anxious')).mood, Mood.anxious);
    });

    test('legacy vents without a mood parse as null', () {
      expect(PostModel.fromMap(_map()).mood, isNull);
    });
  });

  group('filterPostsByMood', () {
    final posts = [
      _post('a', mood: Mood.sad),
      _post('b', mood: Mood.frustrated),
      _post('c'),
      _post('d', mood: Mood.sad),
    ];

    test('null filter returns everything', () {
      expect(filterPostsByMood(posts, null), posts);
    });

    test('keeps only matching moods, preserving order', () {
      expect(
        filterPostsByMood(posts, Mood.sad).map((p) => p.id),
        ['a', 'd'],
      );
    });

    test('returns empty when nothing matches', () {
      expect(filterPostsByMood(posts, Mood.hopeful), isEmpty);
    });
  });

  group('Mood widgets', () {
    Future<void> pump(WidgetTester tester, Widget child) {
      return tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: child))),
      );
    }

    testWidgets('MoodSelector selects and then clears a mood', (tester) async {
      Mood? selected;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => MoodSelector(
            selected: selected,
            onChanged: (m) => setState(() => selected = m),
          ),
        ),
      );

      await tester.tap(find.text('Anxious'));
      await tester.pump();
      expect(selected, Mood.anxious);

      await tester.tap(find.text('Anxious'));
      await tester.pump();
      expect(selected, isNull);
    });

    testWidgets('MoodFilterBar reports selection and "All" resets',
        (tester) async {
      Mood? selected = Mood.sad;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => MoodFilterBar(
            selected: selected,
            onChanged: (m) => setState(() => selected = m),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      await tester.tap(find.text('Frustrated'));
      await tester.pump();
      expect(selected, Mood.frustrated);

      await tester.tap(find.text('All'));
      await tester.pump();
      expect(selected, isNull);
    });

    testWidgets('MoodBadge shows label and fires onTap', (tester) async {
      var tapped = false;
      await pump(
        tester,
        MoodBadge(mood: Mood.lonely, onTap: () => tapped = true),
      );

      expect(find.text('Lonely'), findsOneWidget);
      await tester.tap(find.text('Lonely'));
      expect(tapped, isTrue);
    });
  });
}
