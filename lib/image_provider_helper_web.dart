import 'package:flutter/material.dart';

ImageProvider<Object> imageProviderFromPath(String path) {
  return NetworkImage(path);
}
