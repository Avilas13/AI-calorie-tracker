import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider<Object> imageProviderFromPath(String path) {
  final uri = Uri.tryParse(path);
  if (uri != null && uri.hasScheme) {
    switch (uri.scheme) {
      case 'http':
      case 'https':
      case 'blob':
      case 'data':
        return NetworkImage(path);
      case 'file':
        return FileImage(File.fromUri(uri));
      default:
        break;
    }
  }
  return FileImage(File(path));
}
