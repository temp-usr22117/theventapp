import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import '../utils/avatar_helper.dart';
import '../utils/responsive.dart';
import '../widgets/mood_widgets.dart';
import '../widgets/vent_widgets.dart';
import 'about_screen.dart';
import 'post_screen.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final PostService _postService = PostService();
  Map<String, dynamic>? _profile;
  List<PostModel> _userPosts = [];
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _profileService.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
    if (profile != null && profile['id'] != null) {
      _loadUserPosts(profile['id']);
    }
  }

  Future<void> _loadUserPosts(String userId) async {
    setState(() => _isLoadingPosts = true);
    final posts = await _postService.getUserPosts(userId);
    if (!mounted) return;
    setState(() {
      _userPosts = posts;
      _isLoadingPosts = false;
      if (_profile != null) {
        _profile!['post_count'] = posts.length;
      }
    });
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  Future<void> _editPost(PostModel post) async {
    final saved = await PostScreen.openEditor(context, post);
    if (saved && mounted) setState(() {});
  }

  Future<void> _confirmDeletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Vent',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this vent? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _postService.deletePost(post.id);
      if (!mounted) return;
      if (result['success'] == true) {
        _showMessage('Vent deleted successfully');
        setState(() {
          _userPosts.removeWhere((p) => p.id == post.id);
          if (_profile != null && _profile!['post_count'] != null) {
            final count = (_profile!['post_count'] as int) - 1;
            _profile!['post_count'] = count < 0 ? 0 : count;
          }
        });
      } else {
        _showMessage(
          result['message'] ?? 'Failed to delete vent',
          isError: true,
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.onAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _profile?['profile_picture_url'] != null
                        ? 'Replace Picture'
                        : 'Upload Picture',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImage();
                  },
                ),
                if (_profile?['profile_picture_url'] != null)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.danger,
                      child: Icon(
                        Icons.delete_outline,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Remove Picture',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage();
                    },
                  ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceHigh,
                    child: Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadImage() async {
    final image = await _profileService.pickImage();
    if (image == null) return;

    setState(() => _isUploadingImage = true);

    final result = await _profileService.uploadProfilePicture(image);

    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (result['success'] == true) {
      _showMessage('Profile picture updated!');
      await _loadProfile();
    } else {
      _showMessage(
        result['message'] ?? 'Failed to upload image',
        isError: true,
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() => _isUploadingImage = true);

    final result = await _profileService.removeProfilePicture();

    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (result['success'] == true) {
      _showMessage('Profile picture removed!');
      await _loadProfile();
    } else {
      _showMessage(
        result['message'] ?? 'Failed to remove image',
        isError: true,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _profileService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppColors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: Responsive.isWide(context) ? 20.0 : 100.0,
          left: 16.0,
          right: 16.0,
        ),
        duration: Duration(seconds: isError ? 4 : 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMyVentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'My Vents',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_userPosts.length}',
                style: const TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoadingPosts)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            ),
          )
        else if (_userPosts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No vents yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your anonymous vents and thoughts will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userPosts.length,
            itemBuilder: (context, index) {
              final post = _userPosts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/post-details',
                        arguments: post,
                      ).then((_) {
                        if (_profile != null && _profile!['id'] != null) {
                          _loadUserPosts(_profile!['id']);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Tag, time ago, and Edit/Delete menu
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Your Vent',
                                  style: TextStyle(
                                    color: AppColors.accentLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (post.mood != null) ...[
                                const SizedBox(width: 6),
                                MoodBadge(mood: post.mood!),
                              ],
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _timeAgo(post.createdAt),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              VentOwnerMenu(
                                onEdit: () => _editPost(post),
                                onDelete: () => _confirmDeletePost(post),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.content,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(
                                post.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: post.isLiked
                                    ? AppColors.like
                                    : AppColors.textMuted,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${post.likesCount}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (post.editedAt != null) ...[
                                const SizedBox(width: 12),
                                EditedBadge(editedAt: post.editedAt!),
                              ],
                              const Spacer(),
                              const Row(
                                children: [
                                  Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.accent,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    Responsive.isWide(context) ? 40 : 100,
                  ),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile Picture
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _isUploadingImage
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                    ),
                                  )
                                : Builder(
                                    builder: (context) {
                                      final imageProvider =
                                          getUserAvatarImageProvider(
                                        _profile?['profile_picture_url'],
                                      );
                                      if (imageProvider != null) {
                                        return Image(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.person_outline,
                                            color: AppColors.textSecondary,
                                            size: 50,
                                          ),
                                        );
                                      }
                                      return const CircleAvatar(
                                        backgroundColor: AppColors.surfaceHigh,
                                        child: Icon(
                                          Icons.person_outline,
                                          color: AppColors.textSecondary,
                                          size: 50,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.onAccent,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Username
                  Text(
                    _profile?['username'] ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile?['email'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_profile?['post_count'] ?? 0}', // ← Fixed
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Vents',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // My Vents Section
                  _buildMyVentsSection(),
                  const SizedBox(height: 24),

                  // About Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceRaised,
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.info_outline),
                      label: const Text(
                        'About TheVent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceRaised,
                        foregroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppColors.danger,
                            width: 1,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
    );
  }
}