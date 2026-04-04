import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'http_client_helper.dart';
import 'package:flutter/material.dart';

/// A custom image provider that handles self-signed SSL certificates
class SecureNetworkImage extends ImageProvider<SecureNetworkImage> {
  final String url;
  final double scale;
  final Map<String, String>? headers;

  const SecureNetworkImage(
    this.url, {
    this.scale = 1.0,
    this.headers,
  });

  @override
  Future<SecureNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SecureNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    SecureNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
    );
  }

  Future<Codec> _loadAsync(
    SecureNetworkImage key,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);

    // Use HttpClientHelper to load the image with SSL certificate handling
    final response = await HttpClientHelper.get(
      Uri.parse(key.url),
      headers: key.headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP request failed, statusCode: ${response.statusCode}, uri: ${key.url}',
      );
    }

    final Uint8List bytes = response.bodyBytes;
    if (bytes.lengthInBytes == 0) {
      throw Exception('NetworkImage is an empty file: ${key.url}');
    }

    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is SecureNetworkImage &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'SecureNetworkImage')}("$url", scale: $scale)';
}


