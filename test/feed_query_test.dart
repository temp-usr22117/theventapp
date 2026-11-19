import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theventapp/models/mood.dart';
import 'package:theventapp/models/post_model.dart';
import 'package:theventapp/utils/feed_query.dart';
import 'package:theventapp/widgets/feed_controls.dart';

PostModel _post(
  String id, {
  required String content,
  int likes = 0,
  int daysAgo = 0,
  Mood? mood,
}) =>
    PostModel(
      id: id,
      userId: 'u1',
      content: content,
      likesCount: likes,
      createdAt: DateTime(2026, 11, 19).subtract(Duration(days: daysAgo)),
      username: 'anon',
      mood: mood,
    );

List<String> _ids(List<PostModel> posts) => posts.map((p) => p.id).toList();

void main() {
  final posts = [
    _post('old-popular',
        content: 'Exams are stressing me out', likes: 9, daysAgo: 5),
    _post('new-quiet', content: 'Work was rough today', likes: 1, daysAgo: 0),
    _post('mid',
        content: 'Rough week of EXAMS and work',
        likes: 4,
        daysAgo: 2,
        mood: Mood.anxious),
    _post('tie-older',
        content: 'Feeling lonely', likes: 4, daysAgo: 3, mood: Mood.lonely),
  ];

  group('searchTerms', () {
    test('lowercases and splits on whitespace', () {
      expect(searchTerms('  Exams   WORK '), ['exams', 'work']);
      expect(searchTerms('   '), isEmpty);
    });
  });

  group('applyFeedQuery', () {
    test('latest sorts newest first', () {
      expect(_ids(applyFeedQuery(posts)),
          ['new-quiet', 'mid', 'tie-older', 'old-popular']);
    });

    test('top sorts by likes, newest first on ties', () {
      expect(_ids(applyFeedQuery(posts, sort: FeedSort.top)),
          ['old-popular', 'mid', 'tie-older', 'new-quiet']);
    });

    test('search is case-insensitive and requires every keyword', () {
      expect(
          _ids(applyFeedQuery(posts, query: 'exams')), ['mid', 'old-popular']);
      expect(_ids(applyFeedQuery(posts, query: 'EXAMS work')), ['mid']);
      expect(applyFeedQuery(posts, query: 'vacation'), isEmpty);
    });

    test('combines search, mood filter and sort', () {
      expect(
        _ids(applyFeedQuery(posts,
            query: 'rough', mood: Mood.anxious, sort: FeedSort.top)),
        ['mid'],
      );
    });

    test('never reorders the source list', () {
      final before = _ids(posts);
      applyFeedQuery(posts, sort: FeedSort.top);
      expect(_ids(posts), before);
    });
  });

  group('highlightMatches', () {
    const hl = TextStyle(fontWeight: FontWeight.bold);

    String joined(List<TextSpan> spans) => spans.map((s) => s.text).join();
    List<String> highlighted(List<TextSpan> spans) =>
        spans.where((s) => s.style == hl).map((s) => s.text!).toList();

    test('highlights every case-insensitive occurrence', () {
      final spans = highlightMatches('Work, work, WORK.', ['work'], hl);
      expect(joined(spans), 'Work, work, WORK.');
      expect(highlighted(spans), ['Work', 'work', 'WORK']);
    });

    test('merges overlapping matches', () {
      final spans = highlightMatches('stressed', ['stress', 'ressed'], hl);
      expect(highlighted(spans), ['stressed']);
    });

    test('returns plain text when nothing to highlight', () {
      expect(highlighted(highlightMatches('hello', const [], hl)), isEmpty);
      expect(highlighted(highlightMatches('hello', ['bye'], hl)), isEmpty);
    });
  });

  testWidgets('FeedSortToggle switches between Latest and Top', (tester) async {
    var sort = FeedSort.latest;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FeedSortToggle(
              value: sort,
              onChanged: (s) => setState(() => sort = s),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Top'));
    await tester.pump();
    expect(sort, FeedSort.top);

    await tester.tap(find.text('Latest'));
    await tester.pump();
    expect(sort, FeedSort.latest);
  });
}
