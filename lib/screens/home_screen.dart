import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../utils/avatar_helper.dart';
import '../utils/feed_query.dart';
import '../utils/responsive.dart';
import '../widgets/feed_controls.dart';
import '../widgets/mood_widgets.dart';
import '../widgets/vent_widgets.dart';
import 'post_screen.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onPostTap;

  const HomeScreen({super.key, this.onPostTap});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  Mood? _selectedMood;
  FeedSort _sort = FeedSort.latest;
  bool _isSearching = false;
  String _query = '';

  /// Filtered + sorted view of [_posts]. Recomputed only when the feed or the
  /// query changes (not on likes), so cards don't jump around in "Top".
  List<PostModel> _visiblePosts = [];

  void _refreshVisible() {
    _visiblePosts = applyFeedQuery(
      _posts,
      mood: _selectedMood,
      query: _query,
      sort: _sort,
    );
  }

  bool get _hasActiveFilters => _query.trim().isNotEmpty || _selectedMood != null;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _setMoodFilter(Mood? mood) {
    if (mood == _selectedMood) return;
    setState(() {
      _selectedMood = mood;
      _refreshVisible();
    });
    _scrollToTop();
  }

  void _setSort(FeedSort sort) {
    if (sort == _sort) return;
    setState(() {
      _sort = sort;
      _refreshVisible();
    });
    _scrollToTop();
  }

  void _setQuery(String query) {
    setState(() {
      _query = query;
      _refreshVisible();
    });
    _scrollToTop();
  }

  void _openSearch() => setState(() => _isSearching = true);

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _query = '';
      _refreshVisible();
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedMood = null;
      _refreshVisible();
    });
    _scrollToTop();
  }

  PreferredSizeWidget _buildFeedControls() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(MoodFilterBar.height),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.feedMaxWidth),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 0, 10),
                child: FeedSortToggle(value: _sort, onChanged: _setSort),
              ),
              Expanded(
                child: MoodFilterBar(
                  selected: _selectedMood,
                  onChanged: _setMoodFilter,
                  padding: const EdgeInsets.fromLTRB(10, 6, 16, 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        tooltip: 'Close search',
        onPressed: _closeSearch,
      ),
      titleSpacing: 0,
      title: TextField(
        controller: _searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.accent,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'Search vents by keyword...',
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
          border: InputBorder.none,
        ),
        onChanged: _setQuery,
      ),
      actions: [
        if (_query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            tooltip: 'Clear search',
            onPressed: () {
              _searchController.clear();
              _setQuery('');
            },
          ),
        const SizedBox(width: 8),
      ],
      bottom: _buildFeedControls(),
    );
  }

  Widget _searchButton() {
    return IconButton(
      icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
      tooltip: 'Search vents',
      onPressed: _openSearch,
    );
  }

  void loadPosts() => _loadPosts();

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final posts = await _postService.getPosts();
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _isLoading = false;
      _refreshVisible();
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
    final visiblePosts = _visiblePosts;

    return PopScope(
      // Android back closes the search before leaving the feed.
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearching) _closeSearch();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isSearching
          ? _buildSearchAppBar()
          : isWide
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Home Feed',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                _searchButton(),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Refresh feed',
                  onPressed: _loadPosts,
                ),
                const SizedBox(width: 16),
              ],
              bottom: _buildFeedControls(),
            )
          : AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
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
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              actions: [
                _searchButton(),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Refresh',
                  onPressed: _loadPosts,
                ),
              ],
              bottom: _buildFeedControls(),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Responsive.feedMaxWidth,
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            color: AppColors.textSecondary,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No vents yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Be the first one to vent!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _triggerCreatePost,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create a Vent'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.onAccent,
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
                      color: AppColors.accent,
                      child: ListView.builder(
                        controller: _scrollController,
                        // Keep pull-to-refresh working when a filter leaves
                        // only a few (or no) items on screen.
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          isWide ? 32 : 100, // bottom padding for mobile bar
                        ),
                        itemCount: (visiblePosts.isEmpty ? 1 : visiblePosts.length) +
                            (isWide ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Top "What's on your mind" card on desktop/wide screen
                          if (isWide && index == 0) {
                            return _buildQuickCreateVentCard(user);
                          }

                          if (visiblePosts.isEmpty) {
                            return _buildNoMatches();
                          }

                          final postIndex = isWide ? index - 1 : index;
                          final post = visiblePosts[postIndex];
                          return _buildPostCard(post);
                        },
                      ),
                    ),
        ),
      ),
      ),
    );
  }

  /// Shown when the active search / mood filter matches none of the vents.
  Widget _buildNoMatches() {
    final mood = _selectedMood;
    final query = _query.trim();
    final moodSuffix = mood == null ? '' : ' in ${mood.label}';

    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Icon(
            query.isNotEmpty
                ? Icons.search_off_rounded
                : mood?.icon ?? Icons.filter_alt_off_rounded,
            color: query.isEmpty && mood != null
                ? mood.color
                : AppColors.textSecondary,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            query.isNotEmpty
                ? 'No vents match "$query"$moodSuffix'
                : 'No ${mood?.label.toLowerCase() ?? ''} vents yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            query.isNotEmpty
                ? 'Try different keywords.'
                : 'Try another mood, or share how you feel.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Show all vents',
                style: TextStyle(
                  color: AppColors.accentLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Quick composer card on Web/Desktop (Twitter / Reddit style)
  Widget _buildQuickCreateVentCard(User? user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user?.photoURL,
            radius: 19,
            backgroundColor: AppColors.surfaceHigh,
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
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: const Text(
                  "What's on your mind? Vent anonymously...",
                  style: TextStyle(
                    color: AppColors.textMuted,
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
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
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
      highlightTerms: searchTerms(_query),
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
      onDeleteTap: () => _confirmDeletePost(post),
      onEditTap: () => _editPost(post),
      onMoodTap: post.mood == null ? null : () => _setMoodFilter(post.mood),
    );
  }

  Future<void> _editPost(PostModel post) async {
    final saved = await PostScreen.openEditor(context, post);
    // The post is updated in place; just rebuild (and re-apply the filter).
    if (saved && mounted) setState(_refreshVisible);
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
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
          _refreshVisible();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vent deleted successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete vent'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class _HoverablePostCard extends StatefulWidget {
  final PostModel post;
  final String timeAgo;
  final List<String> highlightTerms;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onMoodTap;

  const _HoverablePostCard({
    required this.post,
    required this.timeAgo,
    this.highlightTerms = const [],
    required this.onTap,
    required this.onLikeTap,
    this.onDeleteTap,
    this.onEditTap,
    this.onMoodTap,
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
            color: _isHovered ? AppColors.surfaceHover : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppColors.accent.withOpacity(0.45)
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.08),
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
                    backgroundColor: AppColors.surfaceHigh,
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
                            Flexible(
                              child: Text(
                                post.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.timeAgo,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Anonymous Member',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            if (post.editedAt != null)
                              EditedBadge(editedAt: post.editedAt!),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (post.mood != null) ...[
                    const SizedBox(width: 8),
                    MoodBadge(mood: post.mood!, onTap: widget.onMoodTap),
                  ],
                  if (FirebaseAuth.instance.currentUser?.uid == post.userId) ...[
                    const SizedBox(width: 4),
                    VentOwnerMenu(
                      onEdit: () => widget.onEditTap?.call(),
                      onDelete: () => widget.onDeleteTap?.call(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Post Content with Human-Readable Typography
              // (search keywords are highlighted while searching)
              Text.rich(
                TextSpan(
                  children: highlightMatches(
                    post.content,
                    widget.highlightTerms,
                    TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 15,
                  height: 1.55,
                  letterSpacing: 0.2,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              const Divider(color: AppColors.divider, height: 1),
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
                                ? AppColors.like
                                : AppColors.textSecondary,
                            size: 19,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likesCount}',
                            style: TextStyle(
                              color: post.isLiked
                                  ? AppColors.like
                                  : AppColors.textSecondary,
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
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Replies',
                            style: TextStyle(
                              color: AppColors.textSecondary,
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
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    tooltip: 'Copy vent',
                    splashRadius: 18,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: post.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Vent text copied to clipboard!'),
                          backgroundColor: AppColors.surfaceHigh,
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
