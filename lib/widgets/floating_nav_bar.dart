import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A modern, Telegram and Google Photos-inspired floating bottom navigation bar.
///
/// Features:
/// - Rounded pill/capsule shape with glassmorphism (BackdropFilter blur)
/// - 3 functions: Home, Post (Create new post in the center), and Profile
/// - Interactive sliding gesture: users can slide/drag their finger across the bar
///   to smoothly navigate between tabs with haptic feedback
/// - Animated sliding indicator pill that glides behind the active tab
/// - Center prominent gradient button for creating a new post
class ModernFloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onPostTap;

  const ModernFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onPostTap,
  });

  @override
  State<ModernFloatingNavBar> createState() => _ModernFloatingNavBarState();
}

class _ModernFloatingNavBarState extends State<ModernFloatingNavBar>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  bool _isDragging = false;
  bool _isPostPressed = false;

  void _handleDrag(DragUpdateDetails details, double totalWidth) {
    if (totalWidth <= 0) return;
    final dx = details.localPosition.dx.clamp(0.0, totalWidth);
    final ratio = dx / totalWidth;

    int newHovered;
    if (ratio < 0.33) {
      newHovered = 0; // Home
    } else if (ratio < 0.67) {
      newHovered = 1; // Post
    } else {
      newHovered = 2; // Profile
    }

    if (newHovered != _hoveredIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _hoveredIndex = newHovered;
      });

      // If user drags onto Home or Profile, switch active tab smoothly
      if (newHovered == 0 && widget.currentIndex != 0) {
        widget.onTabSelected(0);
      } else if (newHovered == 2 && widget.currentIndex != 1) {
        widget.onTabSelected(1);
      }
    }
  }

  void _handleDragEnd() {
    if (_hoveredIndex == 1) {
      HapticFeedback.mediumImpact();
      widget.onPostTap();
    }
    setState(() {
      _isDragging = false;
      _hoveredIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Effective active tab for the sliding indicator (0 = Home, 1 = Profile)
    final activeTab = widget.currentIndex;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final itemWidth = totalWidth / 3;

            return GestureDetector(
              onHorizontalDragStart: (details) {
                setState(() => _isDragging = true);
                _handleDrag(
                  DragUpdateDetails(
                    globalPosition: details.globalPosition,
                    localPosition: details.localPosition,
                  ),
                  totalWidth,
                );
              },
              onHorizontalDragUpdate: (details) =>
                  _handleDrag(details, totalWidth),
              onHorizontalDragEnd: (_) => _handleDragEnd(),
              onHorizontalDragCancel: () {
                setState(() {
                  _isDragging = false;
                  _hoveredIndex = null;
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xEB181818),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated sliding indicator pill behind the active tab
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          left: activeTab == 0
                              ? 6.0
                              : totalWidth - itemWidth + 6.0,
                          top: 8.0,
                          bottom: 8.0,
                          width: itemWidth - 12.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C4DFF).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),

                        // Navigation Items Row
                        Row(
                          children: [
                            // 1. Home Tab
                            Expanded(
                              child: _buildNavItem(
                                index: 0,
                                label: 'Home',
                                icon: Icons.home_outlined,
                                activeIcon: Icons.home_rounded,
                                isSelected: activeTab == 0,
                                isHovered: _isDragging && _hoveredIndex == 0,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onTabSelected(0);
                                },
                              ),
                            ),

                            // 2. Center Post Action Button
                            Expanded(
                              child: _buildCenterPostButton(),
                            ),

                            // 3. Profile Tab
                            Expanded(
                              child: _buildNavItem(
                                index: 2,
                                label: 'Profile',
                                icon: Icons.person_outline_rounded,
                                activeIcon: Icons.person_rounded,
                                isSelected: activeTab == 1,
                                isHovered: _isDragging && _hoveredIndex == 2,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onTabSelected(1);
                                },
                              ),
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
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required bool isHovered,
    required VoidCallback onTap,
  }) {
    final effectiveActive = isSelected || isHovered;
    final color = effectiveActive ? const Color(0xFF9E7BFF) : const Color(0xFF9E9E9E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      splashColor: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: effectiveActive ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                effectiveActive ? activeIcon : icon,
                color: effectiveActive ? Colors.white : color,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: effectiveActive ? Colors.white : color,
                fontSize: 11,
                fontWeight: effectiveActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPostButton() {
    final isHovered = _isDragging && _hoveredIndex == 1;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPostPressed = true),
      onTapUp: (_) {
        setState(() => _isPostPressed = false);
        HapticFeedback.mediumImpact();
        widget.onPostTap();
      },
      onTapCancel: () => setState(() => _isPostPressed = false),
      child: Center(
        child: AnimatedScale(
          scale: _isPostPressed || isHovered ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9569FF),
                  Color(0xFF7C4DFF),
                  Color(0xFF673AB7),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  'Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
