/// Short relative time label, e.g. "just now", "5m ago", "3d ago", "2w ago".
String timeAgo(DateTime dateTime, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(dateTime);
  if (difference.inSeconds < 60) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${(difference.inDays / 7).floor()}w ago';
}
