import 'package:flutter/painting.dart';
import '../models/mood.dart';
import '../models/post_model.dart';

/// How the home feed is ordered.
enum FeedSort {
  /// Newest vents first.
  latest,

  /// Most liked vents first (newest first among equal likes).
  top,
}

/// Splits a search query into lowercase keywords.
List<String> searchTerms(String query) => query
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((term) => term.isNotEmpty)
    .toList();

/// True when the vent's text contains every keyword (case-insensitive).
bool matchesSearch(PostModel post, List<String> terms) {
  final text = post.content.toLowerCase();
  return terms.every(text.contains);
}

/// Applies the mood filter, keyword search and sort order to [posts].
/// Always returns a new list; [posts] is never reordered.
List<PostModel> applyFeedQuery(
  List<PostModel> posts, {
  Mood? mood,
  String query = '',
  FeedSort sort = FeedSort.latest,
}) {
  final terms = searchTerms(query);
  final result = filterPostsByMood(posts, mood)
      .where((post) => terms.isEmpty || matchesSearch(post, terms))
      .toList();

  int newestFirst(PostModel a, PostModel b) =>
      b.createdAt.compareTo(a.createdAt);

  switch (sort) {
    case FeedSort.latest:
      result.sort(newestFirst);
    case FeedSort.top:
      result.sort((a, b) {
        final byLikes = b.likesCount.compareTo(a.likesCount);
        return byLikes != 0 ? byLikes : newestFirst(a, b);
      });
  }
  return result;
}

/// Splits [text] into spans, styling every occurrence of any of [terms]
/// (case-insensitive) with [highlightStyle].
List<TextSpan> highlightMatches(
  String text,
  List<String> terms,
  TextStyle highlightStyle,
) {
  final lower = text.toLowerCase();
  // Some characters change length when lowercased; skip highlighting rather
  // than risk misaligned ranges.
  if (terms.isEmpty || lower.length != text.length) {
    return [TextSpan(text: text)];
  }

  // Collect match ranges, then merge overlapping/adjacent ones.
  final ranges = <List<int>>[];
  for (final term in terms) {
    var start = lower.indexOf(term);
    while (start != -1) {
      ranges.add([start, start + term.length]);
      start = lower.indexOf(term, start + term.length);
    }
  }
  if (ranges.isEmpty) return [TextSpan(text: text)];

  ranges.sort((a, b) => a[0].compareTo(b[0]));
  final merged = <List<int>>[ranges.first];
  for (final range in ranges.skip(1)) {
    final last = merged.last;
    if (range[0] <= last[1]) {
      if (range[1] > last[1]) last[1] = range[1];
    } else {
      merged.add(range);
    }
  }

  final spans = <TextSpan>[];
  var cursor = 0;
  for (final range in merged) {
    if (range[0] > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, range[0])));
    }
    spans.add(
      TextSpan(text: text.substring(range[0], range[1]), style: highlightStyle),
    );
    cursor = range[1];
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}
