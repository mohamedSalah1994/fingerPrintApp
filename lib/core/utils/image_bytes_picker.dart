import 'dart:typed_data';

import 'image_bytes_picker_stub.dart'
    if (dart.library.html) 'image_bytes_picker_web.dart'
    if (dart.library.io) 'image_bytes_picker_io.dart' as impl;

/// Cross-platform image pick (web: file_selector; mobile/desktop: image_picker).
Future<Uint8List?> pickImageBytes() => impl.pickImageBytes();
