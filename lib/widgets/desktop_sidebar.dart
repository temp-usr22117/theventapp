import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onPostTap;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onPostTap,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    final username = user?.displayName ?? 'Anonymous';
    final email = user?.email ?? '';

    final sidebarWidth = isCollapsed ? 76.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(
          right: BorderSide(
            color: Color(0xFF242424),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Brand & Hamburger toggle
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12 : 16,
                vertical: 18,
              ),
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!isCollapsed)
                    Expanded(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TheVent',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Speak freely',
                                  style: TextStyle(
                                    color: Color(0xFF8E8E8E),
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.menu : Icons.menu_open_rounded,
                      color: const Color(0xFFB0B0B0),
                      size: 22,
                    ),
                    tooltip: isCollapsed ? 'Expand menu' : 'Collapse menu',
                    splashRadius: 20,
                    onPressed: onToggleCollapse,
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF242424), height: 1),
            const SizedBox(height: 12),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 8 : 12,
                ),
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.local_fire_department_rounded,
                    outlineIcon: Icons.local_fire_department_outlined,
                    label: 'Home Feed',
                  ),
                  const SizedBox(height: 6),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.person_rounded,
                    outlineIcon: Icons.person_outline_rounded,
                    label: 'My Profile',
                  ),
                  const SizedBox(height: 6),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.info_rounded,
                    outlineIcon: Icons.info_outline_rounded,
                    label: 'About',
                  ),
                  const SizedBox(height: 6),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.bug_report_rounded,
                    outlineIcon: Icons.bug_report_outlined,
                    label: 'Report Bug',
                  ),
                  const SizedBox(height: 24),

                  // + Vent / Create Post Call to Action
                  _buildPostButton(),
                ],
              ),
            ),

            const Divider(color: Color(0xFF242424), height: 1),

            // User Info Tile & Logout
            Padding(
              padding: EdgeInsets.all(isCollapsed ? 10 : 14),
              child: isCollapsed
                  ? Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFFF5277),
                          size: 22,
                        ),
                        tooltip: 'Logout',
                        onPressed: onLogout,
                      ),
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF262626),
                          backgroundImage: user?.photoURL != null &&
                                  user!.photoURL!.isNotEmpty
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user?.photoURL == null ||
                                  user!.photoURL!.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF9E9E9E),
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E8E),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFFF5277),
                            size: 20,
                          ),
                          tooltip: 'Logout',
                          splashRadius: 18,
                          onPressed: onLogout,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData outlineIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      hoverColor: const Color(0xFF1E1E1E),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 0 : 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C4DFF).withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C4DFF).withOpacity(0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              isSelected ? icon : outlineIcon,
              color: isSelected
                  ? const Color(0xFFB388FF)
                  : const Color(0xFFA0A0A0),
              size: 22,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFFB0B0B0),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB388FF),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPostButton() {
    return isCollapsed
        ? Center(
            child: Tooltip(
              message: 'Create Vent',
              child: InkWell(
                onTap: onPostTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF9E7BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF9E7BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPostTap,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Create Vent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
