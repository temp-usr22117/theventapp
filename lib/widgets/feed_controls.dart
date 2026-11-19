import 'package:flutter/material.dart';
import '../utils/feed_query.dart';

/// Compact "Latest | Top" segmented toggle for the feed sort order.
class FeedSortToggle extends StatelessWidget {
  final FeedSort value;
  final ValueChanged<FeedSort> onChanged;

  const FeedSortToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Latest',
            tooltip: 'Newest vents first',
            icon: Icons.schedule_rounded,
            selected: value == FeedSort.latest,
            onTap: () => onChanged(FeedSort.latest),
          ),
          _Segment(
            label: 'Top',
            tooltip: 'Most liked vents first',
            icon: Icons.trending_up_rounded,
            selected: value == FeedSort.top,
            onTap: () => onChanged(FeedSort.top),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFF9E9E9E);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF7C4DFF).withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
