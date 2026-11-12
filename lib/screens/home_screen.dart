import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../utils/avatar_helper.dart';
import '../utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onPostTap;

  const HomeScreen({super.key, this.onPostTap});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void loadPosts() => _loadPosts();

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final posts = await _postService.getPosts();
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  // Toggle like instantly on home screen
  Future<void> _toggleLike(PostModel post) async {
    final previousIsLiked = post.isLiked;
    final previousLikesCount = post.likesCount;

    setState(() {
      post.isLiked = !post.isLiked;
      post.likesCount += post.isLiked ? 1 : -1;
    });

    final isNowLiked = await _postService.toggleLike(post);
    if (!mounted) return;

    setState(() {
      post.isLiked = isNowLiked;
      if (isNowLiked == previousIsLiked) {
        post.likesCount = previousLikesCount;
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

  void _triggerCreatePost() {
    if (widget.onPostTap != null) {
      widget.onPostTap!();
    } else {
      Navigator.pushNamed(context, '/post').then((_) => _loadPosts());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: isWide
          ? AppBar(
              backgroundColor: const Color(0xFF0D0D0D),
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Home Feed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF9E9E9E),
                  ),
                  tooltip: 'Refresh feed',
                  onPressed: _loadPosts,
                ),
                const SizedBox(width: 16),
              ],
            )
          : AppBar(
              backgroundColor: const Color(0xFF0D0D0D),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Open menu',
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TheVent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF9E9E9E),
                  ),
                  tooltip: 'Refresh',
                  onPressed: _loadPosts,
                ),
              ],
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Responsive.feedMaxWidth,
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7C4DFF),
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            color: Color(0xFF9E9E9E),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No vents yet',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Be the first one to vent!',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _triggerCreatePost,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create a Vent'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C4DFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      color: const Color(0xFF7C4DFF),
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          isWide ? 32 : 100, // bottom padding for mobile bar
                        ),
                        itemCount: _posts.length + (isWide ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Top "What's on your mind" card on desktop/wide screen
                          if (isWide && index == 0) {
                            return _buildQuickCreateVentCard(user);
                          }

                          final postIndex = isWide ? index - 1 : index;
                          final post = _posts[postIndex];
                          return _buildPostCard(post);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  /// Quick composer card on Web/Desktop (Twitter / Reddit style)
  Widget _buildQuickCreateVentCard(User? user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF282828),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user?.photoURL,
            radius: 19,
            backgroundColor: const Color(0xFF262626),
            fallbackIcon: Icons.person_outline_rounded,
            iconSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: _triggerCreatePost,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF303030),
                  ),
                ),
                child: const Text(
                  "What's on your mind? Vent anonymously...",
                  style: TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _triggerCreatePost,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Vent',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return _HoverablePostCard(
      post: post,
      timeAgo: _timeAgo(post.createdAt),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/post-details',
          arguments: post,
        ).then((_) {
          _loadPosts();
        });
      },
      onLikeTap: () => _toggleLike(post),
    );
  }
}

class _HoverablePostCard extends StatefulWidget {
  final PostModel post;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;

  const _HoverablePostCard({
    required this.post,
    required this.timeAgo,
    required this.onTap,
    required this.onLikeTap,
  });

  @override
  State<_HoverablePostCard> createState() => _HoverablePostCardState();
}

class _HoverablePostCardState extends State<_HoverablePostCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF1E1E1E) : const Color(0xFF171717),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF7C4DFF).withOpacity(0.45)
                  : const Color(0xFF282828),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Row
              Row(
                children: [
                  UserAvatar(
                    imageUrl: post.profilePictureUrl,
                    radius: 20,
                    backgroundColor: const Color(0xFF282828),
                    fallbackIcon: Icons.person_outline,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6E6E6E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.timeAgo,
                              style: const TextStyle(
                                color: Color(0xFF8E8E8E),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Anonymous Member',
                          style: TextStyle(
                            color: Color(0xFF6E6E6E),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Post Content with Human-Readable Typography
              Text(
                post.content,
                style: const TextStyle(
                  color: Color(0xFFE4E4E4),
                  fontSize: 15,
                  height: 1.55,
                  letterSpacing: 0.2,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              const Divider(color: Color(0xFF242424), height: 1),
              const SizedBox(height: 12),

              // Action Buttons Row (Like, Reply, Share)
              Row(
                children: [
                  // Like Button
                  InkWell(
                    onTap: widget.onLikeTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: post.isLiked
                                ? const Color(0xFFFF4D6D)
                                : const Color(0xFF9E9E9E),
                            size: 19,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likesCount}',
                            style: TextStyle(
                              color: post.isLiked
                                  ? const Color(0xFFFF4D6D)
                                  : const Color(0xFF9E9E9E),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Reply / Comment Button
                  InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF9E9E9E),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Replies',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Share Button
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF7E7E7E),
                      size: 18,
                    ),
                    tooltip: 'Copy vent',
                    splashRadius: 18,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: post.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Vent text copied to clipboard!'),
                          backgroundColor: const Color(0xFF2C2C2C),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
