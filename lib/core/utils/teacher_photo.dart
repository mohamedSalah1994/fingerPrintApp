import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';

/// Builds an [ImageProvider] from local bytes, data-URI, or http URL.
ImageProvider? teacherPhotoProvider({
  Uint8List? localBytes,
  String? photoUrl,
}) {
  if (localBytes != null && localBytes.isNotEmpty) {
    return MemoryImage(localBytes);
  }
  if (photoUrl == null || photoUrl.isEmpty) return null;
  if (photoUrl.startsWith('data:image')) {
    try {
      final comma = photoUrl.indexOf(',');
      if (comma < 0) return null;
      return MemoryImage(base64Decode(photoUrl.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(photoUrl);
}

/// Compact data-URI for Firestore fallback when Storage is unavailable.
String teacherPhotoDataUri(Uint8List bytes, {String mime = 'image/jpeg'}) {
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

String personInitial(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return t.substring(0, 1).toUpperCase();
}

/// Circular avatar: photo if available, otherwise first letter of [name].
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.localBytes,
    this.radius = 20,
  });

  final String name;
  final String? photoUrl;
  final Uint8List? localBytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final provider = teacherPhotoProvider(
      localBytes: localBytes,
      photoUrl: photoUrl,
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      foregroundColor: AppColors.primary,
      backgroundImage: provider,
      child: provider == null
          ? Text(
              personInitial(name),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.9,
              ),
            )
          : null,
    );
  }
}
