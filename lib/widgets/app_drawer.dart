import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/avatar_helper.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onPostTap;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onPostTap,
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

    return Drawer(
      backgroundColor: AppColors.panel,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TheVent',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Speak freely. Anonymously.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  _buildTile(
                    context,
                    index: 0,
                    icon: Icons.local_fire_department_rounded,
                    title: 'Home Feed',
                  ),
                  _buildTile(
                    context,
                    index: 1,
                    icon: Icons.person_rounded,
                    title: 'My Profile',
                  ),
                  _buildTile(
                    context,
                    index: 2,
                    icon: Icons.info_rounded,
                    title: 'About TheVent',
                  ),
                  _buildTile(
                    context,
                    index: 3,
                    icon: Icons.bug_report_rounded,
                    title: 'Report Bug',
                  ),
                  const SizedBox(height: 20),

                  // Create Vent Button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onPostTap();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.onAccent,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create Vent',
                                style: TextStyle(
                                  color: AppColors.onAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, height: 1),

            // User Info & Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl: user?.photoURL,
                    radius: 20,
                    backgroundColor: AppColors.surfaceHigh,
                    fallbackIcon: Icons.person_rounded,
                    iconSize: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppColors.textMuted,
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
                      color: AppColors.danger,
                      size: 22,
                    ),
                    tooltip: 'Logout',
                    onPressed: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isSelected
            ? AppColors.accent.withOpacity(0.14)
            : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.accentLight : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          onTabSelected(index);
        },
      ),
    );
  }
}
