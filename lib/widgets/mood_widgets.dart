import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../theme/app_colors.dart';

/// Small pill showing a vent's mood. Tappable when [onTap] is provided.
class MoodBadge extends StatelessWidget {
  final Mood mood;
  final VoidCallback? onTap;

  const MoodBadge({super.key, required this.mood, this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: mood.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mood.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mood.icon, size: 13, color: mood.color),
          const SizedBox(width: 4),
          Text(
            mood.label,
            style: TextStyle(
              color: mood.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: 'Mood: ${mood.label}', child: badge);
    }

    return Tooltip(
      message: 'Show ${mood.label.toLowerCase()} vents',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: badge,
      ),
    );
  }
}

/// Mood picker for the vent composer. Tapping the selected mood clears it,
/// since tagging a mood is optional.
class MoodSelector extends StatelessWidget {
  final Mood? selected;
  final ValueChanged<Mood?> onChanged;

  const MoodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mood in Mood.values)
          _MoodChip(
            label: mood.label,
            icon: mood.icon,
            color: mood.color,
            selected: mood == selected,
            onTap: () => onChanged(mood == selected ? null : mood),
          ),
      ],
    );
  }
}

/// Horizontal "All + each mood" filter row for the feed.
class MoodFilterBar extends StatelessWidget {
  static const double height = 52;

  final Mood? selected;
  final ValueChanged<Mood?> onChanged;
  final EdgeInsetsGeometry padding;

  const MoodFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 10),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          _MoodChip(
            label: 'All',
            icon: Icons.all_inclusive_rounded,
            color: AppColors.accent,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final mood in Mood.values) ...[
            const SizedBox(width: 8),
            _MoodChip(
              label: mood.label,
              icon: mood.icon,
              color: mood.color,
              selected: mood == selected,
              // Tapping the active filter again goes back to "All".
              onTap: () => onChanged(mood == selected ? null : mood),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.2)
                  : AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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
