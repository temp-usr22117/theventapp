import 'mood.dart';

class PostModel {
  final String id;
  final String userId;
  String content;
  int likesCount;
  bool isLiked;
  final DateTime createdAt;
  final String username;
  final String? profilePictureUrl;
  Mood? mood;

  /// Set when the author edited the vent after posting; null otherwise.
  DateTime? editedAt;

  bool get isEdited => editedAt != null;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.likesCount,
    this.isLiked = false,
    required this.createdAt,
    required this.username,
    this.profilePictureUrl,
    this.mood,
    this.editedAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'],
      userId: map['user_id'],
      content: map['content'],
      likesCount: map['likes_count'] ?? 0,
      isLiked: map['is_liked'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      username: map['users']['username'],
      profilePictureUrl: map['users']['profile_picture_url'],
      mood: Mood.fromKey(map['mood']),
      editedAt: map['edited_at'] is String
          ? DateTime.tryParse(map['edited_at'])
          : null,
    );
  }
}

/// Returns the posts tagged with [mood], or all posts when [mood] is null.
List<PostModel> filterPostsByMood(List<PostModel> posts, Mood? mood) {
  if (mood == null) return posts;
  return posts.where((post) => post.mood == mood).toList();
}
