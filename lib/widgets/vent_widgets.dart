import 'package:flutter/material.dart';
import '../utils/time_ago.dart';
import '../theme/app_colors.dart';

/// Highlighted "Edited · 5m ago" pill shown on vents the author has edited.
class EditedBadge extends StatelessWidget {
  final DateTime editedAt;

  const EditedBadge({super.key, required this.editedAt});

  static const Color _accent = AppColors.accentLight;

  @override
  Widget build(BuildContext context) {
    final label = 'Edited · ${timeAgo(editedAt)}';
    return Semantics(
      label: 'This vent was edited ${timeAgo(editedAt)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, size: 11, color: _accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: _accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OwnerAction { edit, delete }

/// "⋮" menu with Edit / Delete, shown only on the author's own vents.
class VentOwnerMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color iconColor;

  const VentOwnerMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.iconColor = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<_OwnerAction>(
        tooltip: 'Vent options',
        icon: Icon(Icons.more_vert_rounded, color: iconColor, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 140),
        color: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        onSelected: (action) {
          switch (action) {
            case _OwnerAction.edit:
              onEdit();
            case _OwnerAction.delete:
              onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _OwnerAction.edit,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                SizedBox(width: 10),
                Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
          PopupMenuItem(
            value: _OwnerAction.delete,
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                SizedBox(width: 10),
                Text('Delete', style: TextStyle(color: AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
