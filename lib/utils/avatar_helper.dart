import 'dart:convert';
import 'package:flutter/material.dart';

/// Helper to resolve any avatar string into an [ImageProvider].
///
/// Supports:
/// - Base64 Data URIs: `data:image/jpeg;base64,...` or `data:image/png;base64,...`
/// - Standard web/storage URLs: `https://...` or `http://...`
/// - Raw Base64 encoded strings
/// Returns `null` if the input is null, empty, or unparseable.
ImageProvider? getUserAvatarImageProvider(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) return null;
  final clean = imageUrl.trim();

  // Handle data URI
  if (clean.startsWith('data:image')) {
    try {
      final commaIndex = clean.indexOf(',');
      final base64Payload =
          commaIndex != -1 ? clean.substring(commaIndex + 1) : clean;
      final bytes = base64Decode(
        base64Payload.replaceAll('\n', '').replaceAll('\r', '').trim(),
      );
      if (bytes.isNotEmpty) {
        return MemoryImage(bytes);
      }
    } catch (_) {
      return null;
    }
  }

  // Handle standard HTTP / HTTPS URLs
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }

  // Handle potential raw base64 string
  if (clean.length > 60 && !clean.contains('/') && !clean.contains(' ')) {
    try {
      final bytes = base64Decode(
        clean.replaceAll('\n', '').replaceAll('\r', '').trim(),
      );
      if (bytes.isNotEmpty) {
        return MemoryImage(bytes);
      }
    } catch (_) {
      return null;
    }
  }

  return null;
}

/// A standard, flexible User Avatar widget used consistently across mobile and web.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;
  final double? iconSize;
  final Color backgroundColor;
  final Color iconColor;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.fallbackIcon = Icons.person_outline,
    this.iconSize,
    this.backgroundColor = const Color(0xFF2C2C2C),
    this.iconColor = const Color(0xFF9E9E9E),
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = getUserAvatarImageProvider(imageUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(
              fallbackIcon,
              color: iconColor,
              size: iconSize ?? (radius * 1.05),
            )
          : null,
    );
  }
}
