import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood.dart';
import '../models/post_model.dart';
import '../models/reply_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getCurrentUserId() async => _auth.currentUser?.uid;

  Future<Map<String, dynamic>?> _getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  String? _isoOrNull(dynamic value) =>
      value is Timestamp ? value.toDate().toIso8601String() : null;

  Future<List<PostModel>> getPosts() async {
    try {
      final currentUserId = await _getCurrentUserId();

      final snapshot = await _db
          .collection('posts')
          .orderBy('created_at', descending: true)
          .get();

      final posts = <PostModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        bool isLiked = false;
        if (currentUserId != null) {
          final likeDoc = await _db
              .collection('posts')
              .doc(doc.id)
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists;
        }

        final createdAt = data['created_at'] is Timestamp
            ? (data['created_at'] as Timestamp).toDate().toIso8601String()
            : DateTime.now().toIso8601String();

        posts.add(
          PostModel.fromMap({
            'id': doc.id,
            'content': data['content'] ?? '',
            'user_id': data['user_id'] ?? '',
            'likes_count': data['likes_count'] ?? 0,
            'created_at': createdAt,
            'mood': data['mood'],
            'edited_at': _isoOrNull(data['edited_at']),
            'users': {
              'username': data['username'] ?? 'Unknown',
              'profile_picture_url': data['profile_picture_url'],
            },
            'is_liked': isLiked,
          }),
        );
      }

      return posts;
    } catch (_) {
      return [];
    }
  }

  // Get all vents posted by a specific user
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final currentUserId = await _getCurrentUserId();

      final snapshot = await _db
          .collection('posts')
          .where('user_id', isEqualTo: userId)
          .get();

      final posts = <PostModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        bool isLiked = false;
        if (currentUserId != null) {
          final likeDoc = await _db
              .collection('posts')
              .doc(doc.id)
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists;
        }

        final createdAt = data['created_at'] is Timestamp
            ? (data['created_at'] as Timestamp).toDate().toIso8601String()
            : DateTime.now().toIso8601String();

        posts.add(
          PostModel.fromMap({
            'id': doc.id,
            'content': data['content'] ?? '',
            'user_id': data['user_id'] ?? '',
            'likes_count': data['likes_count'] ?? 0,
            'created_at': createdAt,
            'mood': data['mood'],
            'edited_at': _isoOrNull(data['edited_at']),
            'users': {
              'username': data['username'] ?? 'Unknown',
              'profile_picture_url': data['profile_picture_url'],
            },
            'is_liked': isLiked,
          }),
        );
      }

      // Sort by newest first
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (_) {
      return [];
    }
  }

  // Delete a post and its subcollections (author only)
  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final uid = await _getCurrentUserId();
      if (uid == null) {
        return {'success': false, 'message': 'You must be logged in to delete.'};
      }

      final postRef = _db.collection('posts').doc(postId);
      final doc = await postRef.get();
      if (!doc.exists) {
        return {'success': false, 'message': 'Vent not found.'};
      }

      final data = doc.data();
      if (data?['user_id'] != uid) {
        return {
          'success': false,
          'message': 'You can only delete your own vents.'
        };
      }

      // Delete subcollections (replies & likes)
      try {
        final repliesSnap = await postRef.collection('replies').get();
        for (final r in repliesSnap.docs) {
          await r.reference.delete();
        }
      } catch (_) {}

      try {
        final likesSnap = await postRef.collection('likes').get();
        for (final l in likesSnap.docs) {
          await l.reference.delete();
        }
      } catch (_) {}

      await postRef.delete();

      return {'success': true, 'message': 'Vent deleted successfully.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete vent: $e'};
    }
  }

  // Edit a post's content / mood and stamp it as edited (author only)
  Future<Map<String, dynamic>> updatePost({
    required String postId,
    required String content,
    Mood? mood,
  }) async {
    try {
      final uid = await _getCurrentUserId();
      if (uid == null) {
        return {'success': false, 'message': 'You must be logged in to edit.'};
      }

      final postRef = _db.collection('posts').doc(postId);
      final doc = await postRef.get();
      if (!doc.exists) {
        return {'success': false, 'message': 'Vent not found.'};
      }

      if (doc.data()?['user_id'] != uid) {
        return {'success': false, 'message': 'You can only edit your own vents.'};
      }

      await postRef.update({
        'content': content,
        'mood': mood?.key ?? FieldValue.delete(),
        'edited_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Vent updated.'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Could not update vent. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String content,
    Mood? mood,
  }) async {
    try {
      final uid = await _getCurrentUserId();
      if (uid == null) {
        return {'success': false, 'message': 'You must be logged in to post.'};
      }

      final profile = await _getCurrentUserProfile();
      if (profile == null) {
        return {'success': false, 'message': 'User profile not found.'};
      }

      await _db.collection('posts').add({
        'user_id': uid,
        'username': profile['username'] ?? 'Unknown',
        'profile_picture_url': profile['profile_picture_url'],
        'content': content,
        'likes_count': 0,
        'created_at': FieldValue.serverTimestamp(),
        if (mood != null) 'mood': mood.key,
      });

      return {'success': true, 'message': 'Vent posted successfully!'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.'
      };
    }
  }

  Future<bool> toggleLike(PostModel post) async {
    try {
      final uid = await _getCurrentUserId();
      if (uid == null) return post.isLiked;

      final postRef = _db.collection('posts').doc(post.id);
      final likeRef = postRef.collection('likes').doc(uid);

      await _db.runTransaction((tx) async {
        final likeSnap = await tx.get(likeRef);
        final postSnap = await tx.get(postRef);

        final currentLikes = (postSnap.data()?['likes_count'] ?? 0) as int;

        if (likeSnap.exists) {
          tx.delete(likeRef);
          tx.update(postRef, {'likes_count': (currentLikes - 1).clamp(0, 1 << 30)});
        } else {
          tx.set(likeRef, {
            'user_id': uid,
            'created_at': FieldValue.serverTimestamp(),
          });
          tx.update(postRef, {'likes_count': currentLikes + 1});
        }
      });

      return !post.isLiked;
    } catch (_) {
      return post.isLiked;
    }
  }

  Future<List<ReplyModel>> getReplies(String postId) async {
    try {
      final snapshot = await _db
          .collection('posts')
          .doc(postId)
          .collection('replies')
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        final createdAt = data['created_at'] is Timestamp
            ? (data['created_at'] as Timestamp).toDate().toIso8601String()
            : DateTime.now().toIso8601String();

        return ReplyModel.fromMap({
          'id': doc.id,
          'post_id': postId,
          'user_id': data['user_id'] ?? '',
          'content': data['content'] ?? '',
          'created_at': createdAt,
          'users': {
            'username': data['username'] ?? 'Unknown',
            'profile_picture_url': data['profile_picture_url'],
          },
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addReply({
    required String postId,
    required String content,
  }) async {
    try {
      final uid = await _getCurrentUserId();
      if (uid == null) {
        return {'success': false, 'message': 'You must be logged in to reply.'};
      }

      final profile = await _getCurrentUserProfile();
      if (profile == null) {
        return {'success': false, 'message': 'User profile not found.'};
      }

      await _db.collection('posts').doc(postId).collection('replies').add({
        'user_id': uid,
        'username': profile['username'] ?? 'Unknown',
        'profile_picture_url': profile['profile_picture_url'],
        'content': content,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Reply added!'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.'
      };
    }
  }

  // Delete a reply (author only)
  Future<Map<String, dynamic>> deleteReply({
    required String postId,
    required String replyId,
  }) async {
    try {
      final uid = await _getCurrentUserId();
      if (uid == null) {
        return {'success': false, 'message': 'You must be logged in to delete.'};
      }

      final replyRef = _db
          .collection('posts')
          .doc(postId)
          .collection('replies')
          .doc(replyId);

      final doc = await replyRef.get();
      if (!doc.exists) {
        return {'success': false, 'message': 'Reply not found.'};
      }

      if (doc.data()?['user_id'] != uid) {
        return {
          'success': false,
          'message': 'You can only delete your own replies.'
        };
      }

      await replyRef.delete();
      return {'success': true, 'message': 'Reply deleted successfully.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete reply: $e'};
    }
  }
}