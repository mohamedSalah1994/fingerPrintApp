import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

Future<Uint8List?> pickImageBytes() async {
  const typeGroup = XTypeGroup(
    label: 'images',
    extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'gif'],
  );
  final file = await openFile(
    acceptedTypeGroups: <XTypeGroup>[typeGroup],
  );
  if (file == null) return null;
  return file.readAsBytes();
}
