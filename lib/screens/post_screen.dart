import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/mood_widgets.dart';
import '../theme/app_colors.dart';

class PostScreen extends StatefulWidget {
  /// When set, the screen edits this vent instead of creating a new one.
  final PostModel? editingPost;

  const PostScreen({super.key, this.editingPost});

  /// Opens the editor for [post]. Resolves to true if the vent was saved;
  /// [post] is updated in place so callers only need to rebuild.
  static Future<bool> openEditor(BuildContext context, PostModel post) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PostScreen(editingPost: post)),
    );
    return saved == true;
  }

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _contentController = TextEditingController();
  final PostService _postService = PostService();
  bool _isLoading = false;
  int _charCount = 0;
  final int _maxChars = 500;
  Mood? _selectedMood;

  bool get _isEditing => widget.editingPost != null;

  @override
  void initState() {
    super.initState();
    final post = widget.editingPost;
    if (post != null) {
      _contentController.text = post.content;
      _charCount = post.content.length;
      _selectedMood = post.mood;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      _showMessage('Please write something before posting');
      return;
    }

    if (content.length < 10) {
      _showMessage('Vent must be at least 10 characters');
      return;
    }

    if (_isEditing) {
      await _saveEdit(content);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _postService.createPost(
      content: content,
      mood: _selectedMood,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showMessage('Vent posted successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      _showMessage(result['message']);
    }
  }

  Future<void> _saveEdit(String content) async {
    final post = widget.editingPost!;

    if (content == post.content && _selectedMood == post.mood) {
      _showMessage('No changes to save');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _postService.updatePost(
      postId: post.id,
      content: content,
      mood: _selectedMood,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      post
        ..content = content
        ..mood = _selectedMood
        ..editedAt = DateTime.now();
      _showMessage('Vent updated');
      Navigator.pop(context, true);
    } else {
      _showMessage(result['message']);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          _isEditing ? 'Edit Vent' : 'New Vent',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Post Button
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.onAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Save' : 'Post',
                      style: const TextStyle(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Your vent is anonymous. Speak freely.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Mood picker (optional)
                const Text(
                  'How are you feeling? (optional)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                MoodSelector(
                  selected: _selectedMood,
                  onChanged: (mood) => setState(() => _selectedMood = mood),
                ),
                const SizedBox(height: 20),

                // Text Field
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    maxLength: _maxChars,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind? Let it out...",
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                      ),
                      counterStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      alignLabelWithHint: true,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _charCount = value.length;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}